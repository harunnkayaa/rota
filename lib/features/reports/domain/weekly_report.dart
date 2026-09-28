import '../../../core/time/period_range.dart';
import '../../goals/domain/goal.dart';
import '../../planning/domain/period_closing.dart';

/// One goal's line in a week: what it asked for and what was done.
class GoalWeekLine {
  const GoalWeekLine({
    required this.goalId,
    required this.title,
    required this.categoryId,
    required this.target,
    required this.done,
  });

  final String goalId;
  final String title;
  final String categoryId;

  /// Weekly target, or this week's pace share for a goal with a due date.
  final int target;
  final int done;
}

/// Planned vs. done for one week (CLAUDE.md §13.6).
class WeekSummary {
  const WeekSummary({required this.range, required this.lines});

  final PeriodRange range;
  final List<GoalWeekLine> lines;

  int get target => lines.fold(0, (sum, l) => sum + l.target);
  int get done => lines.fold(0, (sum, l) => sum + l.done);

  /// 0..100; work beyond the target doesn't push it over 100.
  int get completionPercent {
    if (target == 0) return 0;
    final percent = done * 100 ~/ target;
    return percent > 100 ? 100 : percent;
  }

  /// Minutes done per category, largest first; categories with no work
  /// are left out.
  List<MapEntry<String, int>> get doneByCategory {
    final totals = <String, int>{};
    for (final line in lines) {
      totals[line.categoryId] = (totals[line.categoryId] ?? 0) + line.done;
    }
    return totals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}

/// Closed weekly goals grouped by week, newest first. Built from frozen
/// snapshots only, so renaming or archiving a goal later never changes
/// these numbers.
List<WeekSummary> weeklyHistory(Iterable<PeriodSnapshot> snapshots) {
  final byWeek = <PeriodRange, List<GoalWeekLine>>{};
  for (final s in snapshots) {
    if (s.goalType != GoalType.flexibleQuota) continue;
    (byWeek[s.range] ??= []).add(
      GoalWeekLine(
        goalId: s.goalId,
        title: s.goalTitle,
        categoryId: s.categoryId,
        target: s.target,
        done: s.achieved,
      ),
    );
  }
  return [
    for (final MapEntry(key: range, value: lines) in byWeek.entries)
      WeekSummary(range: range, lines: lines),
  ]..sort((a, b) => b.range.start.compareTo(a.range.start));
}

/// Closed goals with a due date, most recent date first.
List<PeriodSnapshot> finishedDeadlines(Iterable<PeriodSnapshot> snapshots) => [
  for (final s in snapshots)
    if (s.goalType == GoalType.deadline) s,
]..sort((a, b) => b.range.endExclusive.compareTo(a.range.endExclusive));
