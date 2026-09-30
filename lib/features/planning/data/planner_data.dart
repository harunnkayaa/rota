import '../../categories/domain/category.dart';
import '../../focus/domain/focus_session.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';
import '../../schedule/domain/time_block.dart';
import '../../settings/domain/planner_settings.dart';
import '../domain/period_closing.dart';

/// Everything the planner stores, as one value. Saved and loaded as a unit.
class PlannerData {
  PlannerData({
    this.categories = const [],
    this.goals = const [],
    this.periods = const [],
    this.allocations = const [],
    this.entries = const [],
    this.snapshots = const [],
    this.reviewedPeriodIds = const {},
    PlannerSettings? settings,
    this.activeFocus,
    this.blocks = const [],
  }) : settings = settings ?? PlannerSettings();

  final List<GoalCategory> categories;
  final List<Goal> goals;
  final List<GoalPeriod> periods;
  final List<DailyAllocation> allocations;
  final List<ProgressEntry> entries;

  /// Frozen results of closed periods, for reports and carry-over.
  final List<PeriodSnapshot> snapshots;

  /// Closed periods whose summary the user has already seen.
  final Set<String> reviewedPeriodIds;
  final PlannerSettings settings;

  /// A focus timer that was running when the app was last closed.
  final FocusSession? activeFocus;

  /// The day's time slots ("09:00–11:00 Proje", "Mola").
  final List<TimeBlock> blocks;
}
