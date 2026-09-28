import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/core/time/period_range.dart';
import 'package:rota/features/goals/domain/daily_allocation.dart';
import 'package:rota/features/goals/domain/goal.dart';
import 'package:rota/features/goals/domain/goal_period.dart';
import 'package:rota/features/goals/domain/progress_entry.dart';
import 'package:rota/features/planning/domain/period_closing.dart';
import 'package:rota/features/planning/domain/week_rollover.dart';

import '../../../helpers/builders.dart';

/// Week of [monday]: 28 Sep – 4 Oct. The next week starts 5 Oct.
final _nextMonday = monday.addDays(7);
final _nextWednesday = monday.addDays(9);

Goal _weekly({bool active = true, int target = 600}) {
  final goal = Goal(
    id: 'goal-project',
    categoryId: 'cat-project',
    title: 'Proje',
    goalType: GoalType.flexibleQuota,
    measurementType: MeasurementType.durationMinutes,
    defaultTargetValue: target,
  );
  return active ? goal : goal.archived();
}

RolloverPlan _roll({
  required List<Goal> goals,
  List<GoalPeriod>? periods,
  List<DailyAllocation> allocations = const [],
  List<ProgressEntry> entries = const [],
  required LocalDate today,
}) {
  var ids = 0;
  return planWeekRollover(
    goals: goals,
    periods: periods ?? [weekPeriod()],
    allocations: allocations,
    entries: entries,
    today: today,
    currentWeek: PeriodRange.calendarWeekContaining(
      today,
      weekStartDay: DateTime.monday,
    ),
    nowUtc: DateTime.utc(2026, 10, 5),
    newId: () => 'new-${ids++}',
  );
}

void main() {
  test('nothing to do in the middle of a running week', () {
    expect(_roll(goals: [_weekly()], today: wednesday).isEmpty, isTrue);
  });

  test('a new week closes the old one with its result', () {
    final plan = _roll(
      goals: [_weekly()],
      entries: [entry(monday, 420)],
      today: _nextMonday,
    );

    final closed = plan.closed.single;
    expect(closed.closedPeriod.isClosed, isTrue);
    expect(closed.snapshot.achieved, 420);
    expect(closed.snapshot.shortfall, 180);
    expect(closed.snapshot.outcome, PeriodOutcome.partial);
  });

  test('the new week keeps the default target, not last week\'s total', () {
    final plan = _roll(goals: [_weekly()], today: _nextMonday);

    final week = plan.opened.single;
    expect(week.targetValue, 600);
    expect(week.range.start, _nextMonday);
    expect(week.carryoverFromPeriodId, isNull, reason: 'no silent carry-over');
  });

  test('the day pattern is copied from today on', () {
    final plan = _roll(
      goals: [_weekly()],
      allocations: [
        allocation(monday, 240),
        allocation(tuesday, 120),
        allocation(thursday, 240),
      ],
      today: _nextWednesday,
    );

    final byWeekday = {
      for (final a in plan.openedAllocations) a.date.weekday: a.allocatedValue,
    };
    // Monday and Tuesday of the new week are already past: not planned.
    expect(byWeekday, {DateTime.thursday: 240});
  });

  test('weeks away from the app are not created, only this week', () {
    final threeWeeksLater = monday.addDays(21);
    final plan = _roll(goals: [_weekly()], today: threeWeeksLater);
    expect(plan.opened.single.range.start, threeWeeksLater);
  });

  test('an archived goal is closed but not reopened', () {
    final plan = _roll(goals: [_weekly(active: false)], today: _nextMonday);
    expect(plan.closed, hasLength(1));
    expect(plan.opened, isEmpty);
  });

  test('a deadline goal is closed when its date passes and never reopened', () {
    final exam = Goal(
      id: 'goal-exam',
      categoryId: 'c',
      title: 'Sınav',
      goalType: GoalType.deadline,
      measurementType: MeasurementType.durationMinutes,
    );
    final period = GoalPeriod(
      id: 'exam',
      goalId: 'goal-exam',
      periodType: PeriodType.custom,
      range: PeriodRange(monday, thursday),
      targetValue: 300,
    );
    final plan = _roll(goals: [exam], periods: [period], today: thursday);
    expect(plan.closed.single.snapshot.goalType, GoalType.deadline);
    expect(plan.opened, isEmpty);
  });

  test('running it again after applying changes nothing', () {
    final first = _roll(goals: [_weekly()], today: _nextMonday);
    final second = _roll(
      goals: [_weekly()],
      periods: [first.closed.single.closedPeriod, ...first.opened],
      today: _nextMonday,
    );
    expect(second.isEmpty, isTrue);
  });

  group('carryOverIntoWeek', () {
    final snapshot = _roll(
      goals: [_weekly()],
      entries: [entry(monday, 420)],
      today: _nextMonday,
    ).closed.single.snapshot;
    final nextWeek = GoalPeriod(
      id: 'week-2',
      goalId: 'goal-project',
      periodType: PeriodType.calendarWeek,
      range: PeriodRange.rolling7Days(_nextMonday),
      targetValue: 600,
    );

    test('adds the shortfall to this week and links the source', () {
      final updated = carryOverIntoWeek(
        week: nextWeek,
        snapshot: snapshot,
        amount: 180,
        existingPeriods: [nextWeek],
      );
      expect(updated.id, 'week-2');
      expect(updated.targetValue, 780);
      expect(updated.carryoverFromPeriodId, 'period-1');
    });

    test('only once, and never more than the shortfall', () {
      final once = carryOverIntoWeek(
        week: nextWeek,
        snapshot: snapshot,
        amount: 180,
        existingPeriods: [nextWeek],
      );
      expect(
        () => carryOverIntoWeek(
          week: once,
          snapshot: snapshot,
          amount: 60,
          existingPeriods: [once],
        ),
        throwsStateError,
      );
      expect(
        () => carryOverIntoWeek(
          week: nextWeek,
          snapshot: snapshot,
          amount: 181,
          existingPeriods: [nextWeek],
        ),
        throwsArgumentError,
      );
    });
  });
}
