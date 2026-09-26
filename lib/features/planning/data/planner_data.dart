import '../../categories/domain/category.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';

/// Everything the planner stores, as one value. Saved and loaded as a unit.
class PlannerData {
  const PlannerData({
    this.categories = const [],
    this.goals = const [],
    this.periods = const [],
    this.allocations = const [],
    this.entries = const [],
  });

  final List<GoalCategory> categories;
  final List<Goal> goals;
  final List<GoalPeriod> periods;
  final List<DailyAllocation> allocations;
  final List<ProgressEntry> entries;
}
