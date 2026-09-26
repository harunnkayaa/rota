import 'package:flutter/widgets.dart';

import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/period_range.dart';
import '../../../core/utils/uuid.dart';
import '../../categories/domain/category.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';
import '../domain/capacity.dart';
import '../domain/progress_calculator.dart';
import '../domain/redistribution.dart';

/// Until settings exist, every day offers 4 hours of plannable time.
const defaultDailyCapacityMinutes = 240;

/// Holds the planner state for the UI and turns user actions into domain
/// operations.
///
/// Phase 1: data lives in memory only. In Phase 2 the lists below are
/// replaced by a local store + Supabase sync; the public methods stay the
/// same, so screens don't change.
class PlannerController extends ChangeNotifier {
  PlannerController({
    required this.clock,
    CapacityModel? capacity,
    this.weekStartDay = DateTime.monday,
  }) : capacity =
           capacity ??
           CapacityModel(defaultDailyMinutes: defaultDailyCapacityMinutes);

  final Clock clock;
  final CapacityModel capacity;
  final int weekStartDay;

  final _categories = <GoalCategory>[];
  final _goals = <Goal>[];
  final _periods = <GoalPeriod>[];
  final _allocations = <DailyAllocation>[];
  final _entries = <ProgressEntry>[];

  LocalDate get today => clock.today();

  PeriodRange get currentWeek =>
      PeriodRange.calendarWeekContaining(today, weekStartDay: weekStartDay);

  List<GoalCategory> get categories =>
      List.unmodifiable(_categories.where((c) => !c.isArchived));

  /// Returns the existing copy when a preset was already picked, so the
  /// user never ends up with two "Kitap" categories.
  GoalCategory addCategory(String name, {PresetCategory? preset}) {
    if (preset != null) {
      for (final c in _categories) {
        if (c.preset == preset) return c;
      }
    }
    final category = GoalCategory(
      id: generateUuidV4(),
      name: name,
      iconKey: preset?.name ?? 'custom',
      preset: preset,
      isSensitive: preset?.isSensitive ?? false,
    );
    _categories.add(category);
    notifyListeners();
    return category;
  }

  /// Creates a flexible, minute-based goal for the current week and its
  /// daily plan in one step.
  GoalPeriod createWeeklyDurationGoal({
    required String categoryId,
    required String title,
    required int targetMinutes,
    required Map<LocalDate, int> dailyPlan,
  }) {
    final category = _categories.firstWhere((c) => c.id == categoryId);
    final week = currentWeek;
    if (dailyPlan.keys.any((d) => !week.contains(d))) {
      throw ArgumentError('Daily plan must stay inside $week.');
    }
    final goal = Goal(
      id: generateUuidV4(),
      categoryId: categoryId,
      title: title,
      goalType: GoalType.flexibleQuota,
      measurementType: MeasurementType.durationMinutes,
      isSensitive: category.isSensitive,
    );
    final period = GoalPeriod(
      id: generateUuidV4(),
      goalId: goal.id,
      periodType: PeriodType.calendarWeek,
      range: week,
      targetValue: targetMinutes,
    );
    _goals.add(goal);
    _periods.add(period);
    for (final MapEntry(key: date, value: minutes) in dailyPlan.entries) {
      if (minutes == 0) continue;
      _allocations.add(
        DailyAllocation(
          id: generateUuidV4(),
          goalPeriodId: period.id,
          date: date,
          allocatedValue: minutes,
        ),
      );
    }
    notifyListeners();
    return period;
  }

  /// Records work done today. Throws [ProgressRejectedException] when a
  /// domain rule forbids it; the UI turns the reason into a message.
  void addProgress(String periodId, int minutes, {String? note}) {
    final period = _period(periodId);
    final entry = ProgressEntry(
      id: generateUuidV4(),
      goalPeriodId: periodId,
      valueDelta: minutes,
      source: ProgressSource.manual,
      occurredAt: clock.nowUtc(),
      localDate: today,
      note: note,
    );
    validateNewEntry(period, entry, _entries);
    _entries.add(entry);
    notifyListeners();
  }

  /// Open periods that include today, in creation order.
  List<GoalProgressView> activeGoals() => [
    for (final p in _periods)
      if (!p.isClosed && p.range.contains(today)) _view(p),
  ];

  /// Planned minutes vs. capacity for [date], across all time-based goals.
  CapacityCheck capacityOn(LocalDate date) =>
      checkCapacity(date, capacity, _durationAllocations());

  TodaySummary todaySummary() {
    final views = activeGoals();
    return TodaySummary(
      plannedMinutes: views.fold(0, (s, v) => s + (v.todayAllocated ?? 0)),
      doneMinutes: views.fold(0, (s, v) => s + v.todayDone),
      capacity: capacityOn(today),
    );
  }

  RedistributionResult proposeRedistributionFor(
    String periodId, {
    RedistributionStrategy strategy = RedistributionStrategy.even,
    bool includeToday = false,
  }) {
    final period = _period(periodId);
    return proposeRedistribution(
      goal: _goal(period.goalId),
      period: period,
      deficit: _debt(period),
      candidateDays: [
        for (final d in remainingDays(
          period,
          today,
          includeToday: includeToday,
        ))
          DayCapacity(d, capacityOn(d).free),
      ],
      strategy: strategy,
    );
  }

  /// Applies a proposal the user explicitly accepted.
  void applyProposal(String periodId, RedistributionProposal proposal) {
    for (final MapEntry(key: date, value: extra)
        in proposal.additions.entries) {
      final index = _allocations.indexWhere(
        (a) => a.goalPeriodId == periodId && a.date == date,
      );
      if (index == -1) {
        _allocations.add(
          DailyAllocation(
            id: generateUuidV4(),
            goalPeriodId: periodId,
            date: date,
            allocatedValue: extra,
          ),
        );
      } else {
        final current = _allocations[index];
        _allocations[index] = current.withValue(current.allocatedValue + extra);
      }
    }
    notifyListeners();
  }

  /// Fills the current week with two example goals and some past progress,
  /// so every feature (debt, redistribution, capacity) is visible at once.
  void loadSampleWeek(SampleWeekTexts texts) {
    final days = currentWeek.days.toList();
    final project = addCategory(
      texts.projectCategory,
      preset: PresetCategory.projectDevelopment,
    );
    final language = addCategory(
      texts.languageCategory,
      preset: PresetCategory.language,
    );

    final projectPeriod = createWeeklyDurationGoal(
      categoryId: project.id,
      title: texts.projectGoal,
      targetMinutes: 600,
      dailyPlan: {for (final d in days.take(5)) d: 120},
    );
    final languagePeriod = createWeeklyDurationGoal(
      categoryId: language.id,
      title: texts.languageGoal,
      targetMinutes: 360,
      dailyPlan: {
        for (final i in [0, 2, 4, 5]) days[i]: 90,
      },
    );

    const projectDone = [90, 120, 45, 150, 60];
    const languageDone = {0: 90, 2: 30};
    for (var i = 0; i < days.length; i++) {
      if (!days[i].isBefore(today)) break;
      if (i < projectDone.length) {
        _addPastEntry(projectPeriod.id, days[i], projectDone[i]);
      }
      if (languageDone[i] case final minutes?) {
        _addPastEntry(languagePeriod.id, days[i], minutes);
      }
    }
    notifyListeners();
  }

  void _addPastEntry(String periodId, LocalDate date, int minutes) {
    _entries.add(
      ProgressEntry(
        id: generateUuidV4(),
        goalPeriodId: periodId,
        valueDelta: minutes,
        source: ProgressSource.manual,
        occurredAt: DateTime.utc(date.year, date.month, date.day, 12),
        localDate: date,
      ),
    );
  }

  GoalProgressView _view(GoalPeriod period) {
    final goal = _goal(period.goalId);
    final allocations = _allocations.where((a) => a.goalPeriodId == period.id);
    int? allocatedOn(LocalDate d) {
      for (final a in allocations) {
        if (a.date == d) return a.allocatedValue;
      }
      return null;
    }

    return GoalProgressView(
      period: period,
      goal: goal,
      category: _categories.firstWhere((c) => c.id == goal.categoryId),
      todayAllocated: allocatedOn(today),
      todayDone: dailyProgress(period, today, _entries),
      periodDone: periodProgress(period, _entries),
      unallocated: unallocatedAmount(period, _allocations),
      debt: _debt(period),
      days: [
        for (final d in period.range.days)
          DayProgress(
            date: d,
            allocated: allocatedOn(d) ?? 0,
            done: dailyProgress(period, d, _entries),
            today: today,
          ),
      ],
    );
  }

  int _debt(GoalPeriod period) => unplannedRemaining(
    period: period,
    allocations: _allocations,
    entries: _entries,
    today: today,
  );

  Iterable<DailyAllocation> _durationAllocations() {
    final durationPeriodIds = {
      for (final p in _periods)
        if (!p.isClosed && _goal(p.goalId).measurementType.consumesCapacity)
          p.id,
    };
    return _allocations.where(
      (a) => durationPeriodIds.contains(a.goalPeriodId),
    );
  }

  GoalPeriod _period(String id) => _periods.firstWhere((p) => p.id == id);

  Goal _goal(String id) => _goals.firstWhere((g) => g.id == id);
}

/// Localized names used by [PlannerController.loadSampleWeek].
class SampleWeekTexts {
  const SampleWeekTexts({
    required this.projectCategory,
    required this.languageCategory,
    required this.projectGoal,
    required this.languageGoal,
  });

  final String projectCategory;
  final String languageCategory;
  final String projectGoal;
  final String languageGoal;
}

/// Everything a goal card needs, computed once per build.
@immutable
class GoalProgressView {
  const GoalProgressView({
    required this.period,
    required this.goal,
    required this.category,
    required this.todayAllocated,
    required this.todayDone,
    required this.periodDone,
    required this.unallocated,
    required this.debt,
    required this.days,
  });

  final GoalPeriod period;
  final Goal goal;
  final GoalCategory category;

  /// Null when nothing is planned for today.
  final int? todayAllocated;
  final int todayDone;
  final int periodDone;
  final int unallocated;

  /// Part of the remaining target no longer covered by the plan.
  final int debt;
  final List<DayProgress> days;
}

enum DayStatus { unplanned, done, missed, today, upcoming }

@immutable
class DayProgress {
  const DayProgress({
    required this.date,
    required this.allocated,
    required this.done,
    required LocalDate today,
  }) : _today = today;

  final LocalDate date;
  final int allocated;
  final int done;
  final LocalDate _today;

  int get shortfall => allocated > done ? allocated - done : 0;

  DayStatus get status {
    if (allocated == 0 && done == 0) return DayStatus.unplanned;
    if (done >= allocated) return DayStatus.done;
    if (date.isBefore(_today)) return DayStatus.missed;
    if (date == _today) return DayStatus.today;
    return DayStatus.upcoming;
  }
}

@immutable
class TodaySummary {
  const TodaySummary({
    required this.plannedMinutes,
    required this.doneMinutes,
    required this.capacity,
  });

  final int plannedMinutes;
  final int doneMinutes;
  final CapacityCheck capacity;
}

/// Makes the [PlannerController] available to every screen below it and
/// rebuilds them when it notifies.
class PlannerScope extends InheritedNotifier<PlannerController> {
  const PlannerScope({
    required PlannerController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static PlannerController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlannerScope>();
    assert(scope != null, 'No PlannerScope above this widget.');
    return scope!.notifier!;
  }
}
