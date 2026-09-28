import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/categories/domain/category.dart';
import 'package:rota/features/focus/domain/focus_session.dart';
import 'package:rota/features/goals/domain/goal.dart';
import 'package:rota/features/goals/domain/goal_period.dart';
import 'package:rota/features/goals/domain/progress_entry.dart';
import 'package:rota/features/planning/data/planner_data.dart';
import 'package:rota/features/planning/data/planner_json.dart';
import 'package:rota/features/planning/domain/period_closing.dart';
import 'package:rota/features/settings/domain/planner_settings.dart';

import '../../../../helpers/builders.dart';

PlannerData _sample({GoalPeriod? period}) => PlannerData(
  categories: [
    GoalCategory(
      id: 'cat-project',
      name: 'Sağlık / ilaç',
      iconKey: 'healthMedication',
      preset: PresetCategory.healthMedication,
      isSensitive: true,
    ),
  ],
  goals: [projectGoal()],
  periods: [period ?? weekPeriod()],
  allocations: [allocation(monday, 120)],
  entries: [
    entry(monday, 90, id: 'e1'),
    entry(monday, -30, id: 'e2', source: ProgressSource.adjustment),
  ],
);

void main() {
  group('schema v2', () {
    test('keeps snapshots, reviews, settings and a running timer', () {
      final closed = closePeriod(
        goal: projectGoal(),
        period: weekPeriod(),
        allocations: const [],
        entries: [entry(monday, 90)],
        closedAtUtc: DateTime.utc(2026, 10, 5),
      );
      final data = PlannerData(
        goals: [projectGoal()],
        periods: [closed.closedPeriod],
        snapshots: [closed.snapshot],
        reviewedPeriodIds: {'period-1'},
        settings: PlannerSettings(
          dailyCapacityMinutes: 180,
          weekdayCapacityMinutes: {DateTime.saturday: 360},
          weekStartDay: DateTime.sunday,
        ),
        activeFocus: FocusSession(
          id: 'f1',
          goalPeriodId: 'period-1',
          startedAt: DateTime.utc(2026, 9, 28, 9),
          pausedAt: DateTime.utc(2026, 9, 28, 9, 30),
          pausedSeconds: 60,
        ),
      );

      final decoded = decodePlannerData(encodePlannerData(data));

      final snapshot = decoded.snapshots.single;
      expect(snapshot.achieved, 90);
      expect(snapshot.categoryId, 'cat-project');
      expect(snapshot.goalType, GoalType.flexibleQuota);
      expect(decoded.reviewedPeriodIds, {'period-1'});
      expect(decoded.settings.capacityForWeekday(DateTime.saturday), 360);
      expect(decoded.settings.weekStartDay, DateTime.sunday);
      expect(decoded.activeFocus!.isPaused, isTrue);
      expect(decoded.activeFocus!.pausedSeconds, 60);
    });

    test('a v1 file is migrated: weekly goals get their default target', () {
      final v1 =
          jsonDecode(encodePlannerData(_sample())) as Map<String, Object?>
            ..['schema_version'] = 1
            ..remove('period_snapshots')
            ..remove('reviewed_period_ids')
            ..remove('settings')
            ..remove('active_focus');
      for (final g in v1['goals']! as List) {
        (g as Map).remove('default_target_value');
      }

      final decoded = decodePlannerData(jsonEncode(v1));

      expect(decoded.goals.single.defaultTargetValue, 600);
      expect(decoded.snapshots, isEmpty);
      expect(decoded.settings.dailyCapacityMinutes, 240);
      expect(decoded.activeFocus, isNull);
    });
  });

  test('round trip keeps every field', () {
    final decoded = decodePlannerData(encodePlannerData(_sample()));

    final category = decoded.categories.single;
    expect(category.preset, PresetCategory.healthMedication);
    expect(category.isSensitive, isTrue);

    expect(decoded.goals.single.title, 'Proje geliştirme');

    final period = decoded.periods.single;
    expect(period.range, weekPeriod().range);
    expect(period.targetValue, 600);
    expect(period.isClosed, isFalse);

    expect(decoded.allocations.single.date, monday);
    expect(decoded.allocations.single.allocatedValue, 120);

    final entries = decoded.entries;
    expect(entries.map((e) => e.valueDelta), [90, -30]);
    expect(entries.first.localDate, monday);
    expect(entries.first.occurredAt.isUtc, isTrue);
    expect(entries.last.source, ProgressSource.adjustment);
  });

  test('a closed period stays closed with its timestamp', () {
    final closedAt = DateTime.utc(2026, 10, 4, 21);
    final data = _sample(period: weekPeriod().close(closedAt));

    final period = decodePlannerData(encodePlannerData(data)).periods.single;

    expect(period.isClosed, isTrue);
    expect(period.closedAt, closedAt);
  });

  test('uses the future SQL column names', () {
    final json =
        jsonDecode(encodePlannerData(_sample())) as Map<String, Object?>;
    final entry = (json['progress_entries']! as List).first as Map;
    expect(
      entry.keys,
      containsAll(['goal_period_id', 'local_date', 'idempotency_key']),
    );
  });

  group('refuses unreadable data', () {
    test('not JSON', () {
      expect(() => decodePlannerData('{oops'), throwsFormatException);
    });

    test('unknown schema version', () {
      final json =
          jsonDecode(encodePlannerData(_sample())) as Map<String, Object?>;
      json['schema_version'] = 99;
      expect(() => decodePlannerData(jsonEncode(json)), throwsFormatException);
    });

    test('a field of the wrong type', () {
      final json =
          jsonDecode(encodePlannerData(_sample())) as Map<String, Object?>;
      ((json['goal_periods']! as List).first as Map)['target_value'] = '600';
      expect(() => decodePlannerData(jsonEncode(json)), throwsFormatException);
    });

    test('a record that breaks a domain rule', () {
      final json =
          jsonDecode(encodePlannerData(_sample())) as Map<String, Object?>;
      ((json['goal_periods']! as List).first as Map)['target_value'] = 0;
      expect(() => decodePlannerData(jsonEncode(json)), throwsFormatException);
    });

    test('an unknown enum value', () {
      final json =
          jsonDecode(encodePlannerData(_sample())) as Map<String, Object?>;
      ((json['goals']! as List).first as Map)['goal_type'] = 'magic';
      expect(() => decodePlannerData(jsonEncode(json)), throwsFormatException);
    });
  });
}
