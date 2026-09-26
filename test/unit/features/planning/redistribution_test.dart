import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/goals/domain/goal.dart';
import 'package:rota/features/planning/domain/redistribution.dart';

import '../../../helpers/builders.dart';

void main() {
  group('detectMissedAllocations', () {
    test('finds a past day below its allocation', () {
      final missed = detectMissedAllocations(
        period: weekPeriod(),
        allocations: [allocation(monday, 120), allocation(tuesday, 120)],
        entries: [entry(monday, 60), entry(tuesday, 120)],
        today: wednesday,
      );

      expect(missed, hasLength(1));
      expect(missed.single.date, monday);
      expect(missed.single.shortfall, 60);
    });

    test('today and future days are never "missed"', () {
      final missed = detectMissedAllocations(
        period: weekPeriod(),
        allocations: [allocation(wednesday, 120)],
        entries: const [],
        today: wednesday,
      );
      expect(missed, isEmpty);
    });
  });

  group('unplannedRemaining (goal debt)', () {
    test('Monday shortfall with the rest still planned creates debt', () {
      // Target 600 over Mon–Fri 120. Monday only 60 → 60 no longer planned.
      final debt = unplannedRemaining(
        period: weekPeriod(),
        allocations: [
          for (final d in [monday, tuesday, wednesday, thursday, friday])
            allocation(d, 120),
        ],
        entries: [entry(monday, 60)],
        today: tuesday,
      );
      expect(debt, 60);
    });

    test('extra work on another day cancels the debt', () {
      final debt = unplannedRemaining(
        period: weekPeriod(target: 240),
        allocations: [allocation(monday, 120), allocation(tuesday, 120)],
        entries: [entry(monday, 60), entry(tuesday, 180)],
        today: wednesday,
      );
      expect(debt, 0);
    });
  });

  group('remainingDays', () {
    test('starts tomorrow by default, today on request', () {
      final period = weekPeriod();
      expect(remainingDays(period, friday), [saturday, sunday]);
      expect(remainingDays(period, friday, includeToday: true), [
        friday,
        saturday,
        sunday,
      ]);
    });
  });

  group('proposeRedistribution', () {
    RedistributionProposal propose(
      int deficit,
      List<DayCapacity> days, {
      RedistributionStrategy strategy = RedistributionStrategy.even,
      int? maxDailyAddition,
    }) =>
        proposeRedistribution(
              goal: projectGoal(),
              period: weekPeriod(),
              deficit: deficit,
              candidateDays: days,
              strategy: strategy,
              maxDailyAddition: maxDailyAddition,
            )
            as RedistributionProposal;

    test('even split over remaining days', () {
      final p = propose(300, [
        DayCapacity(thursday, 200),
        DayCapacity(friday, 200),
        DayCapacity(saturday, 200),
      ]);
      expect(p.additions, {thursday: 100, friday: 100, saturday: 100});
      expect(p.isFeasible, isTrue);
    });

    test('capacity-weighted split', () {
      final p = propose(300, [
        DayCapacity(thursday, 60),
        DayCapacity(friday, 120),
        DayCapacity(saturday, 180),
      ], strategy: RedistributionStrategy.capacityWeighted);
      expect(p.additions, {thursday: 50, friday: 100, saturday: 150});
    });

    test('not enough capacity: honest shortfall (CLAUDE.md §10.1)', () {
      final p = propose(360, [
        DayCapacity(friday, 100),
        DayCapacity(saturday, 100),
        DayCapacity(sunday, 100),
      ]);
      expect(p.isFeasible, isFalse);
      expect(p.shortfall, 60);
      expect(p.totalFreeCapacity, 300);
      expect(p.eligibleDayCount, 3);
    });

    test('respects the maximum daily addition', () {
      final p = propose(300, [
        DayCapacity(saturday, 500),
        DayCapacity(sunday, 500),
      ], maxDailyAddition: 90);
      expect(p.additions, {saturday: 90, sunday: 90});
      expect(p.shortfall, 120);
    });

    test('full days are skipped', () {
      final p = propose(60, [
        DayCapacity(saturday, 0),
        DayCapacity(sunday, 120),
      ]);
      expect(p.additions, {sunday: 60});
      expect(p.eligibleDayCount, 1);
    });

    test('a fixed-time goal (medication) is never redistributed', () {
      final result = proposeRedistribution(
        goal: projectGoal(type: GoalType.fixedTimeCritical),
        period: weekPeriod(),
        deficit: 1,
        candidateDays: [DayCapacity(sunday, 120)],
      );
      expect(
        result,
        isA<RedistributionNotAllowed>().having(
          (r) => r.reason,
          'reason',
          NotAllowedReason.goalNotFlexible,
        ),
      );
    });

    test('nothing to redistribute is an explicit answer', () {
      final result = proposeRedistribution(
        goal: projectGoal(),
        period: weekPeriod(),
        deficit: 0,
        candidateDays: const [],
      );
      expect(result, isA<RedistributionNotAllowed>());
    });
  });
}
