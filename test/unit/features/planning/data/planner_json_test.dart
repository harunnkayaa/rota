import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/categories/domain/category.dart';
import 'package:rota/features/goals/domain/goal_period.dart';
import 'package:rota/features/goals/domain/progress_entry.dart';
import 'package:rota/features/planning/data/planner_data.dart';
import 'package:rota/features/planning/data/planner_json.dart';

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
