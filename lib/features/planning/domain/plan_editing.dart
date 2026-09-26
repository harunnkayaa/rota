import '../../../core/time/local_date.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal_period.dart';

enum PlanEditRejection {
  periodClosed,
  dateOutsidePeriod,

  /// Past days are history: "planned vs. done" must stay honest.
  dateInPast,
  invalidAmount,
}

class PlanEditRejectedException implements Exception {
  const PlanEditRejectedException(this.reason, [this.date]);

  final PlanEditRejection reason;
  final LocalDate? date;

  @override
  String toString() => 'PlanEditRejectedException($reason, $date)';
}

/// Returns [allocations] with [changes] applied to [period].
///
/// [changes] maps a day to its new planned amount; 0 removes that day's
/// plan. Allocations of other periods are returned untouched. Throws
/// [PlanEditRejectedException] and changes nothing if any day is invalid.
///
/// Example (CLAUDE.md scenario): Monday 240 planned, 180 done; on Tuesday the
/// user raises Tuesday from 120 to 180 → the 60-minute debt is covered.
List<DailyAllocation> applyPlanChanges({
  required GoalPeriod period,
  required List<DailyAllocation> allocations,
  required Map<LocalDate, int> changes,
  required LocalDate today,
  required String Function() newId,
}) {
  if (period.isClosed) {
    throw const PlanEditRejectedException(PlanEditRejection.periodClosed);
  }
  for (final MapEntry(key: date, value: amount) in changes.entries) {
    if (!period.range.contains(date)) {
      throw PlanEditRejectedException(
        PlanEditRejection.dateOutsidePeriod,
        date,
      );
    }
    if (date.isBefore(today)) {
      throw PlanEditRejectedException(PlanEditRejection.dateInPast, date);
    }
    if (amount < 0 || amount > Duration.minutesPerDay) {
      throw PlanEditRejectedException(PlanEditRejection.invalidAmount, date);
    }
  }

  final result = [
    for (final a in allocations)
      if (a.goalPeriodId != period.id || !changes.containsKey(a.date)) a,
  ];
  for (final MapEntry(key: date, value: amount) in changes.entries) {
    if (amount == 0) continue;
    final existing = allocations.where(
      (a) => a.goalPeriodId == period.id && a.date == date,
    );
    result.add(
      existing.isEmpty
          ? DailyAllocation(
              id: newId(),
              goalPeriodId: period.id,
              date: date,
              allocatedValue: amount,
            )
          // Keeping the id lets a later sync treat this as an update.
          : existing.first.withValue(amount),
    );
  }
  return result;
}
