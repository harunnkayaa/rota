import '../../../core/time/period_range.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';
import 'progress_calculator.dart';

enum PeriodOutcome { completed, partial, missed }

/// Frozen result of a closed period.
///
/// Holds copies (title, target, totals) instead of references, so renaming
/// or archiving the goal later never rewrites history.
class PeriodSnapshot {
  const PeriodSnapshot({
    required this.periodId,
    required this.goalId,
    required this.goalTitle,
    required this.measurementType,
    required this.range,
    required this.target,
    required this.achieved,
    required this.allocated,
    required this.closedAt,
  });

  static const int schemaVersion = 1;

  final String periodId;
  final String goalId;
  final String goalTitle;
  final MeasurementType measurementType;
  final PeriodRange range;
  final int target;
  final int achieved;
  final int allocated;
  final DateTime closedAt;

  int get shortfall => achieved >= target ? 0 : target - achieved;

  PeriodOutcome get outcome {
    if (achieved >= target) return PeriodOutcome.completed;
    if (achieved > 0) return PeriodOutcome.partial;
    return PeriodOutcome.missed;
  }

  /// Stored as `snapshot_json` in the period review (CLAUDE.md §9.10).
  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    'period_id': periodId,
    'goal_id': goalId,
    'goal_title': goalTitle,
    'measurement_type': measurementType.name,
    'start_date': range.start.toString(),
    'end_date_exclusive': range.endExclusive.toString(),
    'target': target,
    'achieved': achieved,
    'allocated': allocated,
    'outcome': outcome.name,
    'closed_at': closedAt.toIso8601String(),
  };
}

class PeriodCloseResult {
  const PeriodCloseResult(this.closedPeriod, this.snapshot);

  final GoalPeriod closedPeriod;
  final PeriodSnapshot snapshot;
}

PeriodCloseResult closePeriod({
  required Goal goal,
  required GoalPeriod period,
  required Iterable<DailyAllocation> allocations,
  required Iterable<ProgressEntry> entries,
  required DateTime closedAtUtc,
}) {
  if (period.goalId != goal.id) {
    throw ArgumentError('Period ${period.id} does not belong to ${goal.id}.');
  }
  final closed = period.close(closedAtUtc);
  return PeriodCloseResult(
    closed,
    PeriodSnapshot(
      periodId: period.id,
      goalId: goal.id,
      goalTitle: goal.title,
      measurementType: goal.measurementType,
      range: period.range,
      target: period.targetValue,
      achieved: periodProgress(period, entries),
      allocated: allocatedTotal(period, allocations),
      closedAt: closedAtUtc,
    ),
  );
}

/// Explicit carry-over chosen by the user: a new period that points back to
/// its source. Nothing is ever carried over automatically (CLAUDE.md §4.3).
GoalPeriod createCarryOver({
  required GoalPeriod closedPeriod,
  required PeriodSnapshot snapshot,
  required int amount,
  required String newPeriodId,
  required PeriodType periodType,
  required PeriodRange nextRange,
  required Iterable<GoalPeriod> existingPeriods,
}) {
  if (!closedPeriod.isClosed) {
    throw StateError('Only a closed period can be carried over.');
  }
  if (snapshot.periodId != closedPeriod.id) {
    throw ArgumentError('Snapshot does not belong to ${closedPeriod.id}.');
  }
  if (existingPeriods.any((p) => p.carryoverFromPeriodId == closedPeriod.id)) {
    throw StateError('Period ${closedPeriod.id} was already carried over.');
  }
  if (amount <= 0 || amount > snapshot.shortfall) {
    throw ArgumentError.value(
      amount,
      'amount',
      'Must be 1..${snapshot.shortfall}',
    );
  }
  if (nextRange.start.isBefore(closedPeriod.range.endExclusive)) {
    throw ArgumentError('Carry-over must start after the closed period.');
  }
  return GoalPeriod(
    id: newPeriodId,
    goalId: closedPeriod.goalId,
    periodType: periodType,
    range: nextRange,
    targetValue: amount,
    carryoverFromPeriodId: closedPeriod.id,
  );
}
