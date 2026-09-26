import 'dart:math';

import '../../../core/time/local_date.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';

/// Keeps the first entry per idempotency key.
///
/// A retried offline sync can deliver the same entry twice; it must count
/// once. Every total below goes through this function.
List<ProgressEntry> uniqueEntries(Iterable<ProgressEntry> entries) {
  final seen = <String>{};
  return [
    for (final entry in entries)
      if (seen.add(entry.idempotencyKey)) entry,
  ];
}

/// Everything achieved in [period] — the "90" in "90/600".
int periodProgress(GoalPeriod period, Iterable<ProgressEntry> entries) {
  return uniqueEntries(entries)
      .where((e) => e.goalPeriodId == period.id)
      .fold(0, (sum, e) => sum + e.valueDelta);
}

/// Achieved on one [date] — the "90" in "90/120". Same entries as
/// [periodProgress], filtered by day, so the two can never disagree.
int dailyProgress(
  GoalPeriod period,
  LocalDate date,
  Iterable<ProgressEntry> entries,
) {
  return uniqueEntries(entries)
      .where((e) => e.goalPeriodId == period.id && e.localDate == date)
      .fold(0, (sum, e) => sum + e.valueDelta);
}

int remainingTarget(GoalPeriod period, Iterable<ProgressEntry> entries) =>
    max(0, period.targetValue - periodProgress(period, entries));

int allocatedTotal(GoalPeriod period, Iterable<DailyAllocation> allocations) {
  return allocations
      .where((a) => a.goalPeriodId == period.id)
      .fold(0, (sum, a) => sum + a.allocatedValue);
}

/// Target minus everything spread over days. Negative means more is planned
/// than the target requires.
int unallocatedAmount(
  GoalPeriod period,
  Iterable<DailyAllocation> allocations,
) => period.targetValue - allocatedTotal(period, allocations);

enum ProgressRejection {
  wrongPeriod,
  periodClosed,
  dateOutsidePeriod,
  totalWouldBeNegative,
}

/// A progress entry that breaks a rule the user can trigger from the UI.
class ProgressRejectedException implements Exception {
  const ProgressRejectedException(this.reason);

  final ProgressRejection reason;

  @override
  String toString() => 'ProgressRejectedException($reason)';
}

/// Checks [entry] before it is appended to [existing].
///
/// Throws [ProgressRejectedException]. Entries for closed periods are
/// rejected for now; how late offline entries are handled is an open product
/// decision (see docs/product/open-decisions.md).
void validateNewEntry(
  GoalPeriod period,
  ProgressEntry entry,
  Iterable<ProgressEntry> existing,
) {
  if (entry.goalPeriodId != period.id) {
    throw const ProgressRejectedException(ProgressRejection.wrongPeriod);
  }
  if (period.isClosed) {
    throw const ProgressRejectedException(ProgressRejection.periodClosed);
  }
  if (!period.range.contains(entry.localDate)) {
    throw const ProgressRejectedException(ProgressRejection.dateOutsidePeriod);
  }
  if (periodProgress(period, existing) + entry.valueDelta < 0) {
    throw const ProgressRejectedException(
      ProgressRejection.totalWouldBeNegative,
    );
  }
}
