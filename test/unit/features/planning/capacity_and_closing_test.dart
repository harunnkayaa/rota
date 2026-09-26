import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/period_range.dart';
import 'package:rota/features/goals/domain/goal.dart';
import 'package:rota/features/goals/domain/goal_period.dart';
import 'package:rota/features/planning/domain/capacity.dart';
import 'package:rota/features/planning/domain/period_closing.dart';

import '../../../helpers/builders.dart';

void main() {
  group('capacity', () {
    final model = CapacityModel(
      defaultDailyMinutes: 240,
      overrides: {tuesday: 60},
    );

    test('warns when planned exceeds capacity', () {
      final check = checkCapacity(tuesday, model, [
        allocation(tuesday, 90),
        allocation(tuesday, 30, periodId: 'other'),
      ]);
      expect(check.capacity, 60);
      expect(check.planned, 120);
      expect(check.overBy, 60);
      expect(check.free, 0);
    });

    test('shows free minutes when under capacity', () {
      final check = checkCapacity(monday, model, [allocation(monday, 120)]);
      expect(check.free, 120);
      expect(check.isOver, isFalse);
    });

    test('rejects impossible capacities', () {
      expect(
        () => CapacityModel(defaultDailyMinutes: 1441),
        throwsArgumentError,
      );
    });
  });

  group('closePeriod', () {
    final closedAt = DateTime.utc(2026, 10, 4, 21);

    PeriodCloseResult close(int achieved) => closePeriod(
      goal: projectGoal(),
      period: weekPeriod(),
      allocations: [allocation(monday, 300), allocation(tuesday, 300)],
      entries: [if (achieved > 0) entry(monday, achieved)],
      closedAtUtc: closedAt,
    );

    test('produces a frozen snapshot with the outcome', () {
      final result = close(450);
      expect(result.closedPeriod.isClosed, isTrue);
      expect(result.snapshot.achieved, 450);
      expect(result.snapshot.allocated, 600);
      expect(result.snapshot.shortfall, 150);
      expect(result.snapshot.outcome, PeriodOutcome.partial);
      expect(result.snapshot.toJson()['goal_title'], 'Proje geliştirme');
    });

    test('completed and missed outcomes', () {
      expect(close(600).snapshot.outcome, PeriodOutcome.completed);
      expect(close(0).snapshot.outcome, PeriodOutcome.missed);
    });

    test('closing twice is refused', () {
      final closed = close(100).closedPeriod;
      expect(() => closed.close(closedAt), throwsStateError);
    });

    test('the snapshot keeps the title even if the goal is renamed', () {
      final snapshot = close(100).snapshot;
      final renamed = Goal(
        id: 'goal-project',
        categoryId: 'cat-project',
        title: 'Yeni ad',
        goalType: GoalType.flexibleQuota,
        measurementType: MeasurementType.durationMinutes,
      );
      expect(renamed.title, isNot(snapshot.goalTitle));
      expect(snapshot.goalTitle, 'Proje geliştirme');
    });
  });

  group('createCarryOver', () {
    final result = closePeriod(
      goal: projectGoal(),
      period: weekPeriod(),
      allocations: const [],
      entries: [entry(monday, 450)],
      closedAtUtc: DateTime.utc(2026, 10, 4, 21),
    );
    final nextWeek = PeriodRange.rolling7Days(sunday.addDays(1));

    GoalPeriod carry(int amount, {List<GoalPeriod> existing = const []}) =>
        createCarryOver(
          closedPeriod: result.closedPeriod,
          snapshot: result.snapshot,
          amount: amount,
          newPeriodId: 'period-2',
          periodType: PeriodType.calendarWeek,
          nextRange: nextWeek,
          existingPeriods: existing,
        );

    test('creates a linked period for the chosen amount', () {
      final next = carry(150);
      expect(next.carryoverFromPeriodId, 'period-1');
      expect(next.targetValue, 150);
      expect(next.range.start, sunday.addDays(1));
    });

    test('cannot carry more than the shortfall', () {
      expect(() => carry(151), throwsArgumentError);
    });

    test('the same period cannot be carried over twice', () {
      final first = carry(150);
      expect(() => carry(100, existing: [first]), throwsStateError);
    });

    test('an open period cannot be carried over', () {
      expect(
        () => createCarryOver(
          closedPeriod: weekPeriod(),
          snapshot: result.snapshot,
          amount: 10,
          newPeriodId: 'x',
          periodType: PeriodType.calendarWeek,
          nextRange: nextWeek,
          existingPeriods: const [],
        ),
        throwsStateError,
      );
    });
  });
}
