import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/period_range.dart';
import 'package:rota/core/utils/uuid.dart';
import 'package:rota/features/goals/domain/goal.dart';
import 'package:rota/features/goals/domain/goal_period.dart';
import 'package:rota/features/goals/domain/progress_entry.dart';

import '../../../helpers/builders.dart';

void main() {
  group('Goal', () {
    test('a dose goal must be a fixed-time critical routine', () {
      expect(
        () => Goal(
          id: 'g',
          categoryId: 'c',
          title: 'İlaç',
          goalType: GoalType.flexibleQuota,
          measurementType: MeasurementType.dose,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a blank title', () {
      expect(() => projectGoalWithTitle('   '), throwsArgumentError);
    });
  });

  group('GoalPeriod', () {
    test('rejects a non-positive target', () {
      expect(() => weekPeriod(target: 0), throwsArgumentError);
    });

    test('a calendar week must be 7 days', () {
      expect(
        () => GoalPeriod(
          id: 'p',
          goalId: 'g',
          periodType: PeriodType.calendarWeek,
          range: PeriodRange(monday, friday),
          targetValue: 60,
        ),
        throwsArgumentError,
      );
    });

    test('a custom period can have any length', () {
      final p = GoalPeriod(
        id: 'p',
        goalId: 'g',
        periodType: PeriodType.custom,
        range: PeriodRange(monday, monday.addDays(21)),
        targetValue: 60,
      );
      expect(p.range.lengthInDays, 21);
    });
  });

  group('ProgressEntry', () {
    test('only adjustments may be negative', () {
      expect(() => entry(monday, -10), throwsArgumentError);
    });

    test('occurredAt must be UTC', () {
      expect(
        () => ProgressEntry(
          id: 'e',
          goalPeriodId: 'p',
          valueDelta: 10,
          source: ProgressSource.manual,
          occurredAt: DateTime(2026, 9, 28, 9),
          localDate: monday,
        ),
        throwsArgumentError,
      );
    });
  });

  group('generateUuidV4', () {
    test('has the v4 format and does not repeat', () {
      final ids = {for (var i = 0; i < 1000; i++) generateUuidV4()};
      expect(ids, hasLength(1000));
      expect(
        ids.first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });
}

Goal projectGoalWithTitle(String title) => Goal(
  id: 'g',
  categoryId: 'c',
  title: title,
  goalType: GoalType.flexibleQuota,
  measurementType: MeasurementType.durationMinutes,
);
