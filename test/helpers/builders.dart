import 'package:rota/core/time/local_date.dart';
import 'package:rota/core/time/period_range.dart';
import 'package:rota/features/goals/domain/daily_allocation.dart';
import 'package:rota/features/goals/domain/goal.dart';
import 'package:rota/features/goals/domain/goal_period.dart';
import 'package:rota/features/goals/domain/progress_entry.dart';

/// Test week: Monday 2026-09-28 .. Sunday 2026-10-04.
final monday = LocalDate(2026, 9, 28);
final tuesday = monday.addDays(1);
final wednesday = monday.addDays(2);
final thursday = monday.addDays(3);
final friday = monday.addDays(4);
final saturday = monday.addDays(5);
final sunday = monday.addDays(6);

Goal projectGoal({GoalType type = GoalType.flexibleQuota}) => Goal(
  id: 'goal-project',
  categoryId: 'cat-project',
  title: 'Proje geliştirme',
  goalType: type,
  measurementType: MeasurementType.durationMinutes,
);

GoalPeriod weekPeriod({String id = 'period-1', int target = 600}) => GoalPeriod(
  id: id,
  goalId: 'goal-project',
  periodType: PeriodType.calendarWeek,
  range: PeriodRange.calendarWeekContaining(
    monday,
    weekStartDay: DateTime.monday,
  ),
  targetValue: target,
);

DailyAllocation allocation(
  LocalDate date,
  int value, {
  String periodId = 'period-1',
}) => DailyAllocation(
  id: 'alloc-$periodId-$date',
  goalPeriodId: periodId,
  date: date,
  allocatedValue: value,
);

var _entryCounter = 0;

ProgressEntry entry(
  LocalDate date,
  int value, {
  String? id,
  String periodId = 'period-1',
  ProgressSource source = ProgressSource.manual,
}) => ProgressEntry(
  id: id ?? 'entry-${_entryCounter++}',
  goalPeriodId: periodId,
  valueDelta: value,
  source: source,
  occurredAt: DateTime.utc(date.year, date.month, date.day, 9),
  localDate: date,
);
