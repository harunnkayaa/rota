import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/core/time/period_range.dart';
import 'package:rota/features/goals/domain/daily_allocation.dart';
import 'package:rota/features/goals/domain/goal_period.dart';
import 'package:rota/features/goals/domain/progress_entry.dart';
import 'package:rota/features/planning/domain/deadline_pace.dart';

import '../../../helpers/builders.dart';

/// PTE exam on Sunday 15 Nov; the goal started two weeks before [monday].
final _examDay = LocalDate(2026, 11, 15);
final _goalStart = LocalDate(2026, 9, 14);

GoalPeriod _exam({int total = 2400}) => GoalPeriod(
  id: 'exam',
  goalId: 'goal-exam',
  periodType: PeriodType.custom,
  range: PeriodRange(_goalStart, _examDay),
  targetValue: total,
);

DeadlinePace _pace({
  required LocalDate today,
  List<DailyAllocation> allocations = const [],
  List<ProgressEntry> entries = const [],
  int freePerDay = 240,
  int total = 2400,
}) => computeDeadlinePace(
  period: _exam(total: total),
  allocations: allocations,
  entries: entries,
  today: today,
  week: PeriodRange.calendarWeekContaining(
    today,
    weekStartDay: DateTime.monday,
  ),
  freeCapacityOn: (_) => freePerDay,
);

ProgressEntry _did(LocalDate day, int minutes) =>
    entry(day, minutes, periodId: 'exam');

DailyAllocation _plan(LocalDate day, int minutes) =>
    allocation(day, minutes, periodId: 'exam');

void main() {
  group('pace', () {
    test('40 h goal, 8 h done, 48 days left → 4 h 40 min per week', () {
      final pace = _pace(
        today: monday,
        entries: [_did(LocalDate(2026, 9, 20), 480)],
      );

      expect(pace.daysLeft, 48);
      expect(pace.remaining, 1920);
      expect(pace.requiredPerWeek, 280);
      expect(pace.requiredThisWeek, 280);
    });

    test('a missed week raises the pace of the next one', () {
      final entries = [_did(LocalDate(2026, 9, 20), 480)];
      final thisWeek = _pace(today: monday, entries: entries);
      final nextWeek = _pace(today: monday.addDays(7), entries: entries);

      expect(nextWeek.requiredThisWeek, greaterThan(thisWeek.requiredThisWeek));
      expect(nextWeek.requiredThisWeek, 328); // ceil(1920 * 7 / 41)
    });

    test("work done during the week doesn't move this week's target", () {
      final monday120 = [_did(LocalDate(2026, 9, 20), 480), _did(monday, 120)];
      final pace = _pace(today: wednesday, entries: monday120);

      expect(pace.requiredThisWeek, 280);
      expect(pace.doneThisWeek, 120);
    });

    test('in the final week everything left is due', () {
      final lastMonday = LocalDate(2026, 11, 9);
      final pace = _pace(today: lastMonday, total: 600);

      expect(pace.daysLeft, 6);
      expect(pace.requiredThisWeek, 600);
      expect(pace.requiredPerWeek, 600);
    });
  });

  group('status', () {
    test('on track when done + planned covers this week', () {
      final pace = _pace(
        today: monday,
        allocations: [_plan(monday, 175), _plan(wednesday, 175)],
      );
      expect(pace.thisWeekGap, 0);
      expect(pace.status, DeadlineStatus.onTrack);
    });

    test('behind when this week is under-planned', () {
      final pace = _pace(today: monday, allocations: [_plan(monday, 180)]);
      // 2400 over 48 days → 350 this week; 180 planned.
      expect(pace.requiredThisWeek, 350);
      expect(pace.thisWeekGap, 170);
      expect(pace.status, DeadlineStatus.behindThisWeek);
    });

    test('not feasible when free capacity until the date is too small', () {
      final pace = _pace(today: monday, freePerDay: 30);
      // 48 days × 30 min = 1440 < 2400.
      expect(pace.availableUntilDue, 1440);
      expect(pace.shortfall, 960);
      expect(pace.status, DeadlineStatus.notFeasible);
    });

    test('completed once the total is reached', () {
      final pace = _pace(today: monday, entries: [_did(monday, 2400)]);
      expect(pace.status, DeadlineStatus.completed);
      expect(pace.requiredPerWeek, 0);
    });

    test('overdue on the due date with work left', () {
      final pace = _pace(today: _examDay, total: 600);
      expect(pace.daysLeft, 0);
      expect(pace.status, DeadlineStatus.overdue);
    });
  });

  group('proposeCatchUp', () {
    test('free capacity first, spread evenly', () {
      final p = proposeCatchUp(
        gap: 120,
        days: [wednesday, thursday],
        freeCapacityOn: (_) => 200,
      );
      expect(p.additions, {wednesday: 60, thursday: 60});
      expect(p.fromFreeCapacity, 120);
      expect(p.reductions, isEmpty);
      expect(p.shortfall, 0);
    });

    test('takes the rest from a goal the user allowed, same day', () {
      final p = proposeCatchUp(
        gap: 180,
        days: [wednesday, thursday],
        freeCapacityOn: (_) => 30,
        donors: [
          DonorPlan(
            periodId: 'project',
            plannedByDay: {wednesday: 240, thursday: 240},
          ),
        ],
      );
      expect(p.fromFreeCapacity, 60);
      expect(p.fromOtherGoals, 120);
      expect(p.reductions, {
        'project': {wednesday: 120},
      });
      expect(p.additions, {wednesday: 150, thursday: 30});
      expect(p.shortfall, 0);
    });

    test('never takes more than the other goal has planned', () {
      final p = proposeCatchUp(
        gap: 300,
        days: [wednesday],
        freeCapacityOn: (_) => 0,
        donors: [
          DonorPlan(periodId: 'project', plannedByDay: {wednesday: 60}),
        ],
      );
      expect(p.fromOtherGoals, 60);
      expect(p.shortfall, 240);
    });

    test('without permission no other goal is touched', () {
      final p = proposeCatchUp(
        gap: 300,
        days: [wednesday],
        freeCapacityOn: (_) => 100,
      );
      expect(p.reductions, isEmpty);
      expect(p.shortfall, 200);
    });
  });
}
