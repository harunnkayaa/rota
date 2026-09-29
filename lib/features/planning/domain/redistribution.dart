import 'dart:math';

import '../../../core/time/local_date.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';
import 'distribution.dart';
import 'progress_calculator.dart';

/// A past day whose plan was not reached.
class MissedAllocation {
  const MissedAllocation({
    required this.date,
    required this.allocated,
    required this.achieved,
  });

  final LocalDate date;
  final int allocated;
  final int achieved;

  int get shortfall => allocated - achieved;
}

/// Past days (before [today]) where progress stayed below the allocation.
///
/// This is a factual list; it does not mean the week is behind. Extra work on
/// another day can make up for it — see [unplannedRemaining].
List<MissedAllocation> detectMissedAllocations({
  required GoalPeriod period,
  required Iterable<DailyAllocation> allocations,
  required Iterable<ProgressEntry> entries,
  required LocalDate today,
}) {
  final missed = <MissedAllocation>[];
  for (final a in allocations) {
    if (a.goalPeriodId != period.id || !a.date.isBefore(today)) continue;
    final achieved = dailyProgress(period, a.date, entries);
    if (achieved < a.allocatedValue) {
      missed.add(
        MissedAllocation(
          date: a.date,
          allocated: a.allocatedValue,
          achieved: achieved,
        ),
      );
    }
  }
  return missed..sort((a, b) => a.date.compareTo(b.date));
}

/// What is still planned from [today] on, minus work already done on those
/// days: the plan that is left to carry out.
int remainingPlanned({
  required GoalPeriod period,
  required Iterable<DailyAllocation> allocations,
  required Iterable<ProgressEntry> entries,
  required LocalDate today,
}) {
  var stillPlanned = 0;
  for (final a in allocations) {
    if (a.goalPeriodId != period.id || a.date.isBefore(today)) continue;
    stillPlanned += max(
      0,
      a.allocatedValue - dailyProgress(period, a.date, entries),
    );
  }
  return stillPlanned;
}

/// The part of the remaining target that the current plan no longer covers:
/// remaining target − [remainingPlanned].
///
/// This is the "goal debt" of CLAUDE.md §10.3: it is shown to the user,
/// never moved silently.
int unplannedRemaining({
  required GoalPeriod period,
  required Iterable<DailyAllocation> allocations,
  required Iterable<ProgressEntry> entries,
  required LocalDate today,
}) {
  final planned = remainingPlanned(
    period: period,
    allocations: allocations,
    entries: entries,
    today: today,
  );
  return max(0, remainingTarget(period, entries) - planned);
}

/// Days of [period] that can still receive work.
List<LocalDate> remainingDays(
  GoalPeriod period,
  LocalDate today, {
  bool includeToday = false,
}) {
  return period.range.days
      .where((d) => includeToday ? !d.isBefore(today) : d.isAfter(today))
      .toList();
}

enum RedistributionStrategy {
  /// Same amount on every eligible day.
  even,

  /// More on days with more free capacity.
  capacityWeighted,
}

/// A day that could take more work. [freeMinutes] is null when capacity does
/// not apply (e.g. a pages goal).
class DayCapacity {
  const DayCapacity(this.date, this.freeMinutes);

  final LocalDate date;
  final int? freeMinutes;
}

sealed class RedistributionResult {
  const RedistributionResult();
}

enum NotAllowedReason { goalNotFlexible, periodClosed, nothingToRedistribute }

/// An explicit "no", so the UI can explain why instead of failing.
final class RedistributionNotAllowed extends RedistributionResult {
  const RedistributionNotAllowed(this.reason);

  final NotAllowedReason reason;
}

/// A suggestion only: nothing changes until the user applies it.
final class RedistributionProposal extends RedistributionResult {
  const RedistributionProposal({
    required this.deficit,
    required this.additions,
    required this.eligibleDayCount,
    required this.totalFreeCapacity,
  });

  /// What needed a new home.
  final int deficit;

  /// Extra amount per day; days that get nothing are omitted.
  final Map<LocalDate, int> additions;
  final int eligibleDayCount;

  /// Sum of free minutes on eligible days; null when capacity doesn't apply.
  final int? totalFreeCapacity;

  int get placed => additions.values.fold(0, (a, b) => a + b);

  /// What could not be placed without exceeding capacity or the daily limit.
  int get shortfall => deficit - placed;
  bool get isFeasible => shortfall == 0;
}

/// Deterministic, explainable redistribution (CLAUDE.md §10.1).
RedistributionResult proposeRedistribution({
  required Goal goal,
  required GoalPeriod period,
  required int deficit,
  required List<DayCapacity> candidateDays,
  RedistributionStrategy strategy = RedistributionStrategy.even,
  int? maxDailyAddition,
  int block = 1,
}) {
  if (!goal.goalType.isRedistributable) {
    return const RedistributionNotAllowed(NotAllowedReason.goalNotFlexible);
  }
  if (period.isClosed) {
    return const RedistributionNotAllowed(NotAllowedReason.periodClosed);
  }
  if (deficit <= 0) {
    return const RedistributionNotAllowed(
      NotAllowedReason.nothingToRedistribute,
    );
  }

  final days = [
    for (final d in candidateDays)
      if (d.freeMinutes == null || d.freeMinutes! > 0) d,
  ]..sort((a, b) => a.date.compareTo(b.date));

  final hasCapacity = days.every((d) => d.freeMinutes != null);
  if (strategy == RedistributionStrategy.capacityWeighted && !hasCapacity) {
    throw ArgumentError('capacityWeighted needs free capacity for every day.');
  }

  final weights = [
    for (final d in days)
      strategy == RedistributionStrategy.even ? 1 : d.freeMinutes!,
  ];
  final caps = [
    for (final d in days)
      switch ((d.freeMinutes, maxDailyAddition)) {
        (null, final limit) => limit,
        (final free, null) => free,
        (final free!, final limit!) => min(free, limit),
      },
  ];
  final shares = splitWithCaps(deficit, weights, caps, block: block);

  return RedistributionProposal(
    deficit: deficit,
    additions: {
      for (var i = 0; i < days.length; i++)
        if (shares[i] > 0) days[i].date: shares[i],
    },
    eligibleDayCount: days.length,
    totalFreeCapacity: hasCapacity
        ? days.fold<int>(0, (sum, d) => sum + d.freeMinutes!)
        : null,
  );
}
