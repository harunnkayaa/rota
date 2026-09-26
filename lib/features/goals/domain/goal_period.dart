import '../../../core/time/period_range.dart';

enum PeriodType { calendarWeek, rolling7Days, custom, daily }

enum PeriodStatus { open, closed }

/// One instance of a goal over a date range: "Proje, 600 dk, 28 Eyl – 4 Eki".
class GoalPeriod {
  factory GoalPeriod({
    required String id,
    required String goalId,
    required PeriodType periodType,
    required PeriodRange range,
    required int targetValue,
    String? carryoverFromPeriodId,
  }) {
    if (targetValue <= 0) {
      throw ArgumentError.value(targetValue, 'targetValue', 'Must be > 0');
    }
    final expectedLength = switch (periodType) {
      PeriodType.calendarWeek ||
      PeriodType.rolling7Days => PeriodRange.daysPerWeek,
      PeriodType.daily => 1,
      PeriodType.custom => null,
    };
    if (expectedLength != null && range.lengthInDays != expectedLength) {
      throw ArgumentError(
        '$periodType must span $expectedLength days, got $range.',
      );
    }
    return GoalPeriod._(
      id: id,
      goalId: goalId,
      periodType: periodType,
      range: range,
      targetValue: targetValue,
      status: PeriodStatus.open,
      carryoverFromPeriodId: carryoverFromPeriodId,
      closedAt: null,
    );
  }

  const GoalPeriod._({
    required this.id,
    required this.goalId,
    required this.periodType,
    required this.range,
    required this.targetValue,
    required this.status,
    required this.carryoverFromPeriodId,
    required this.closedAt,
  });

  final String id;
  final String goalId;
  final PeriodType periodType;
  final PeriodRange range;
  final int targetValue;
  final PeriodStatus status;

  /// Set only when the user explicitly chose to carry a shortfall over.
  final String? carryoverFromPeriodId;
  final DateTime? closedAt;

  bool get isClosed => status == PeriodStatus.closed;

  /// Changing the target keeps all progress; remaining/feasibility are
  /// derived, so they update automatically. Closed results are frozen.
  GoalPeriod withTarget(int newTarget) {
    if (isClosed) throw StateError('Cannot change target of a closed period.');
    if (newTarget <= 0) {
      throw ArgumentError.value(newTarget, 'newTarget', 'Must be > 0');
    }
    return _copy(targetValue: newTarget);
  }

  GoalPeriod close(DateTime closedAtUtc) {
    if (isClosed) throw StateError('Period $id is already closed.');
    if (!closedAtUtc.isUtc) {
      throw ArgumentError.value(closedAtUtc, 'closedAtUtc', 'Must be UTC');
    }
    return _copy(status: PeriodStatus.closed, closedAt: closedAtUtc);
  }

  GoalPeriod _copy({
    int? targetValue,
    PeriodStatus? status,
    DateTime? closedAt,
  }) {
    return GoalPeriod._(
      id: id,
      goalId: goalId,
      periodType: periodType,
      range: range,
      targetValue: targetValue ?? this.targetValue,
      status: status ?? this.status,
      carryoverFromPeriodId: carryoverFromPeriodId,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}
