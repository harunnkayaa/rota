import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/period_range.dart';
import 'package:rota/features/goals/domain/goal.dart';
import 'package:rota/features/goals/domain/goal_period.dart';
import 'package:rota/features/planning/domain/period_closing.dart';
import 'package:rota/features/reports/domain/weekly_report.dart';

import '../../../helpers/builders.dart';

PeriodSnapshot _snapshot({
  required String goalId,
  required String categoryId,
  required PeriodRange range,
  required int target,
  required int achieved,
  GoalType type = GoalType.flexibleQuota,
}) {
  final goal = Goal(
    id: goalId,
    categoryId: categoryId,
    title: goalId,
    goalType: type,
    measurementType: MeasurementType.durationMinutes,
  );
  return closePeriod(
    goal: goal,
    period: GoalPeriod(
      id: '$goalId-${range.start}',
      goalId: goalId,
      periodType: type == GoalType.deadline
          ? PeriodType.custom
          : PeriodType.calendarWeek,
      range: range,
      targetValue: target,
    ),
    allocations: const [],
    entries: [
      if (achieved > 0)
        entry(range.start, achieved, periodId: '$goalId-${range.start}'),
    ],
    closedAtUtc: DateTime.utc(2026, 10, 20),
  ).snapshot;
}

void main() {
  final week1 = PeriodRange.rolling7Days(monday);
  final week2 = PeriodRange.rolling7Days(monday.addDays(7));

  test('groups closed weekly goals by week, newest first', () {
    final history = weeklyHistory([
      _snapshot(
        goalId: 'a',
        categoryId: 'x',
        range: week1,
        target: 600,
        achieved: 300,
      ),
      _snapshot(
        goalId: 'b',
        categoryId: 'y',
        range: week1,
        target: 200,
        achieved: 200,
      ),
      _snapshot(
        goalId: 'a',
        categoryId: 'x',
        range: week2,
        target: 600,
        achieved: 600,
      ),
    ]);

    expect(history.map((w) => w.range), [week2, week1]);
    expect(history.last.target, 800);
    expect(history.last.done, 500);
    expect(history.last.completionPercent, 62);
  });

  test('completion never goes above 100%', () {
    final history = weeklyHistory([
      _snapshot(
        goalId: 'a',
        categoryId: 'x',
        range: week1,
        target: 100,
        achieved: 250,
      ),
    ]);
    expect(history.single.completionPercent, 100);
  });

  test('work per category, largest first, empty ones left out', () {
    final week = weeklyHistory([
      _snapshot(
        goalId: 'a',
        categoryId: 'career',
        range: week1,
        target: 600,
        achieved: 120,
      ),
      _snapshot(
        goalId: 'b',
        categoryId: 'health',
        range: week1,
        target: 200,
        achieved: 180,
      ),
      _snapshot(
        goalId: 'c',
        categoryId: 'career',
        range: week1,
        target: 100,
        achieved: 90,
      ),
      _snapshot(
        goalId: 'd',
        categoryId: 'reading',
        range: week1,
        target: 100,
        achieved: 0,
      ),
    ]).single;

    expect(week.doneByCategory.map((e) => (e.key, e.value)), [
      ('career', 210),
      ('health', 180),
    ]);
  });

  test('a 7-day deadline goal is not mistaken for a weekly goal', () {
    final snapshots = [
      _snapshot(
        goalId: 'exam',
        categoryId: 'x',
        range: week1,
        target: 300,
        achieved: 300,
        type: GoalType.deadline,
      ),
    ];
    expect(weeklyHistory(snapshots), isEmpty);
    expect(finishedDeadlines(snapshots).single.goalId, 'exam');
  });
}
