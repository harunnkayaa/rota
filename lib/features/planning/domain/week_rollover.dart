import '../../../core/time/local_date.dart';
import '../../../core/time/period_range.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';
import 'period_closing.dart';

/// What happens when a new week begins (or the app is opened after days
/// away). Computed as a plan first, so it can be tested and applied in one
/// save.
class RolloverPlan {
  const RolloverPlan({
    required this.closed,
    required this.opened,
    required this.openedAllocations,
  });

  /// Periods that ended, now closed with a frozen snapshot.
  final List<PeriodCloseResult> closed;

  /// New weeks for active weekly goals.
  final List<GoalPeriod> opened;
  final List<DailyAllocation> openedAllocations;

  bool get isEmpty => closed.isEmpty && opened.isEmpty;
}

/// 1. Every open period whose last day is before [today] is closed.
/// 2. Every active weekly goal without a period for this week gets one,
///    with its default weekly target. Skipped weeks are not created.
/// 3. The new week copies the latest week's per-weekday plan, from today
///    on only (past days of this week stay unplanned).
///
/// Missing minutes are **not** carried over here; that is the user's
/// explicit choice afterwards (CLAUDE.md §4.3). Running this twice changes
/// nothing the second time.
RolloverPlan planWeekRollover({
  required List<Goal> goals,
  required List<GoalPeriod> periods,
  required List<DailyAllocation> allocations,
  required List<ProgressEntry> entries,
  required LocalDate today,
  required PeriodRange currentWeek,
  required DateTime nowUtc,
  required String Function() newId,
}) {
  final goalById = {for (final g in goals) g.id: g};

  final closed = [
    for (final p in periods)
      if (!p.isClosed && !today.isBefore(p.range.endExclusive))
        closePeriod(
          goal: goalById[p.goalId]!,
          period: p,
          allocations: allocations,
          entries: entries,
          closedAtUtc: nowUtc,
        ),
  ];

  final opened = <GoalPeriod>[];
  final openedAllocations = <DailyAllocation>[];
  for (final goal in goals) {
    final target = goal.defaultTargetValue;
    if (!goal.isActive ||
        goal.goalType != GoalType.flexibleQuota ||
        target == null) {
      continue;
    }
    final own = periods.where((p) => p.goalId == goal.id).toList()
      ..sort((a, b) => a.range.start.compareTo(b.range.start));
    if (own.isEmpty || own.any((p) => p.range.contains(today))) continue;
    final latest = own.last;
    if (latest.periodType != PeriodType.calendarWeek) continue;

    final period = GoalPeriod(
      id: newId(),
      goalId: goal.id,
      periodType: PeriodType.calendarWeek,
      range: currentWeek,
      targetValue: target,
    );
    opened.add(period);

    final pattern = {
      for (final a in allocations)
        if (a.goalPeriodId == latest.id) a.date.weekday: a.allocatedValue,
    };
    for (final day in currentWeek.days) {
      final minutes = pattern[day.weekday];
      if (day.isBefore(today) || minutes == null || minutes == 0) continue;
      openedAllocations.add(
        DailyAllocation(
          id: newId(),
          goalPeriodId: period.id,
          date: day,
          allocatedValue: minutes,
        ),
      );
    }
  }

  return RolloverPlan(
    closed: closed,
    opened: opened,
    openedAllocations: openedAllocations,
  );
}
