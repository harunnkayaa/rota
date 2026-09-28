import 'dart:math';

import '../../../core/time/local_date.dart';
import '../../../core/time/period_range.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';
import 'distribution.dart';
import 'progress_calculator.dart';

enum DeadlineStatus {
  /// The total target is reached.
  completed,

  /// This week's share is covered by work done and work planned.
  onTrack,

  /// This week's plan is below the pace the deadline needs.
  behindThisWeek,

  /// Even all free capacity until the deadline would not be enough.
  notFeasible,

  /// The date has passed with work remaining.
  overdue,
}

/// Where a goal with a due date stands, planned backwards from that date
/// (CLAUDE.md §6.4).
///
/// Example: 40 h until 15 Nov, 8 h done, 48 days left → 32 h remaining,
/// about 4 h 40 min per week. Nothing is stored: the pace is recomputed
/// from entries every time, so a missed week automatically raises the
/// pace of the weeks that follow.
class DeadlinePace {
  const DeadlinePace({
    required this.total,
    required this.done,
    required this.dueDate,
    required this.daysLeft,
    required this.requiredThisWeek,
    required this.doneThisWeek,
    required this.plannedRestOfWeek,
    required this.availableUntilDue,
  });

  final int total;
  final int done;

  /// The event day (exam, interview, delivery). Work is planned before it.
  final LocalDate dueDate;

  /// Days from today (inclusive) to [dueDate] (exclusive).
  final int daysLeft;

  /// This week's fair share of the work, fixed at the start of the week so
  /// progress made during the week doesn't move the goalposts.
  final int requiredThisWeek;
  final int doneThisWeek;

  /// Still planned from today to the end of this week (not yet done).
  final int plannedRestOfWeek;

  /// Free minutes left for this goal until the deadline, after every other
  /// goal's plan.
  final int availableUntilDue;

  int get remaining => max(0, total - done);

  /// Average weekly pace from today to the deadline.
  int get requiredPerWeek {
    if (remaining == 0) return 0;
    if (daysLeft <= DateTime.daysPerWeek) return remaining;
    return _ceilDiv(remaining * DateTime.daysPerWeek, daysLeft);
  }

  /// This week's share that is neither done nor planned.
  int get thisWeekGap =>
      max(0, requiredThisWeek - doneThisWeek - plannedRestOfWeek);

  /// What stays undone even if every free minute until the deadline is used.
  int get shortfall => max(0, remaining - availableUntilDue);

  DeadlineStatus get status {
    if (remaining == 0) return DeadlineStatus.completed;
    if (daysLeft == 0) return DeadlineStatus.overdue;
    if (shortfall > 0) return DeadlineStatus.notFeasible;
    if (thisWeekGap > 0) return DeadlineStatus.behindThisWeek;
    return DeadlineStatus.onTrack;
  }
}

/// [period] runs from the goal's start to its due date (exclusive).
/// [freeCapacityOn] returns a day's free minutes for this goal, i.e.
/// capacity minus what other goals plan that day.
DeadlinePace computeDeadlinePace({
  required GoalPeriod period,
  required Iterable<DailyAllocation> allocations,
  required Iterable<ProgressEntry> entries,
  required LocalDate today,
  required PeriodRange week,
  required int Function(LocalDate day) freeCapacityOn,
}) {
  final due = period.range.endExclusive;
  final done = periodProgress(period, entries);
  final remaining = max(0, period.targetValue - done);
  final daysLeft = max(0, today.daysUntil(due));

  int allocatedOn(LocalDate day) {
    for (final a in allocations) {
      if (a.goalPeriodId == period.id && a.date == day) return a.allocatedValue;
    }
    return 0;
  }

  // This week, clipped to the goal's own dates.
  final windowStart = _later(week.start, period.range.start);
  final windowEnd = _earlier(week.endExclusive, due);
  var doneThisWeek = 0;
  var plannedRestOfWeek = 0;
  var requiredThisWeek = 0;
  if (windowStart.isBefore(windowEnd)) {
    for (final day in PeriodRange(windowStart, windowEnd).days) {
      final doneOn = dailyProgress(period, day, entries);
      doneThisWeek += doneOn;
      if (!day.isBefore(today)) {
        plannedRestOfWeek += max(0, allocatedOn(day) - doneOn);
      }
    }
    final remainingAtWeekStart = remaining + doneThisWeek;
    requiredThisWeek = min(
      remainingAtWeekStart,
      _ceilDiv(
        remainingAtWeekStart * windowStart.daysUntil(windowEnd),
        windowStart.daysUntil(due),
      ),
    );
  }

  var availableUntilDue = 0;
  for (var day = today; day.isBefore(due); day = day.addDays(1)) {
    availableUntilDue += freeCapacityOn(day);
  }

  return DeadlinePace(
    total: period.targetValue,
    done: done,
    dueDate: due,
    daysLeft: daysLeft,
    requiredThisWeek: requiredThisWeek,
    doneThisWeek: doneThisWeek,
    plannedRestOfWeek: plannedRestOfWeek,
    availableUntilDue: availableUntilDue,
  );
}

/// Another flexible goal the user allowed Rota to take time from.
class DonorPlan {
  const DonorPlan({required this.periodId, required this.plannedByDay});

  final String periodId;

  /// Planned-but-not-done minutes per day; only this part can be given up.
  final Map<LocalDate, int> plannedByDay;
}

/// A catch-up suggestion. Nothing changes until the user applies it.
class CatchUpProposal {
  const CatchUpProposal({
    required this.additions,
    required this.reductions,
    required this.fromFreeCapacity,
    required this.fromOtherGoals,
    required this.shortfall,
  });

  /// Extra minutes for the deadline goal per day.
  final Map<LocalDate, int> additions;

  /// Minutes taken from other goals: periodId → day → minutes.
  final Map<String, Map<LocalDate, int>> reductions;
  final int fromFreeCapacity;
  final int fromOtherGoals;

  /// What could not be placed this week.
  final int shortfall;

  bool get isEmpty => additions.isEmpty;
}

/// Places [gap] minutes on [days]: first into free capacity, spread evenly;
/// then, only if needed, by moving time from [donors] in the given order
/// (earliest day first). Moving time keeps each day's total unchanged, so
/// no day becomes more overloaded than before.
CatchUpProposal proposeCatchUp({
  required int gap,
  required List<LocalDate> days,
  required int Function(LocalDate day) freeCapacityOn,
  List<DonorPlan> donors = const [],
}) {
  final sortedDays = [...days]..sort();
  final fromFree = splitWithCaps(gap, List.filled(sortedDays.length, 1), [
    for (final d in sortedDays) freeCapacityOn(d),
  ]);
  final additions = <LocalDate, int>{
    for (var i = 0; i < sortedDays.length; i++)
      if (fromFree[i] > 0) sortedDays[i]: fromFree[i],
  };
  final placedFree = fromFree.fold(0, (a, b) => a + b);

  var needed = gap - placedFree;
  final reductions = <String, Map<LocalDate, int>>{};
  for (final donor in donors) {
    for (final day in sortedDays) {
      if (needed == 0) break;
      final take = min(needed, donor.plannedByDay[day] ?? 0);
      if (take == 0) continue;
      (reductions[donor.periodId] ??= {})[day] = take;
      additions[day] = (additions[day] ?? 0) + take;
      needed -= take;
    }
  }

  return CatchUpProposal(
    additions: additions,
    reductions: reductions,
    fromFreeCapacity: placedFree,
    fromOtherGoals: gap - placedFree - needed,
    shortfall: needed,
  );
}

int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;

LocalDate _later(LocalDate a, LocalDate b) => a.isAfter(b) ? a : b;

LocalDate _earlier(LocalDate a, LocalDate b) => a.isBefore(b) ? a : b;
