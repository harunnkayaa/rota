import 'dart:math';

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
import '../data/planner_data.dart';
import '../data/planner_json.dart';
import '../data/planner_storage.dart';
import '../domain/capacity.dart';
import '../domain/plan_editing.dart';
import '../domain/progress_calculator.dart';
import '../domain/redistribution.dart';

/// Until settings exist, every day offers 4 hours of plannable time.
const defaultDailyCapacityMinutes = 240;

enum LoadStatus { loading, ready, failed }

enum SaveStatus { saved, saving, failed }

/// Holds the planner state for the UI and turns user actions into domain
/// operations.
///
/// Every change is saved to [storage] in the background, in order. Phase 2
/// adds Supabase sync behind the same public methods, so screens don't
/// change.
class PlannerController extends ChangeNotifier {
  PlannerController({
    required this.clock,
    PlannerStorage? storage,
    CapacityModel? capacity,
    this.weekStartDay = DateTime.monday,
  }) : storage = storage ?? InMemoryPlannerStorage(),
       capacity =
           capacity ??
           CapacityModel(defaultDailyMinutes: defaultDailyCapacityMinutes);

  final Clock clock;
  final PlannerStorage storage;
  final CapacityModel capacity;
  final int weekStartDay;

  LoadStatus _loadStatus = LoadStatus.ready;
  SaveStatus _saveStatus = SaveStatus.saved;
  Future<void> _saveChain = Future.value();

  LoadStatus get loadStatus => _loadStatus;
  SaveStatus get saveStatus => _saveStatus;

  /// Reads saved data. If it can't be read, the app stops in an error state
  /// and never writes, so unreadable data is not overwritten and lost.
  Future<void> load() async {
    _loadStatus = LoadStatus.loading;
    notifyListeners();
    try {
      final raw = await storage.read();
      final data = raw == null ? const PlannerData() : decodePlannerData(raw);
      _categories
        ..clear()
        ..addAll(data.categories);
      _goals
        ..clear()
        ..addAll(data.goals);
      _periods
        ..clear()
        ..addAll(data.periods);
      _allocations
        ..clear()
        ..addAll(data.allocations);
      _entries
        ..clear()
        ..addAll(data.entries);
      _loadStatus = LoadStatus.ready;
    } on Object catch (e) {
      // Type only: the saved content may contain personal goal titles.
      debugPrint('Planner load failed: ${e.runtimeType}');
      _loadStatus = LoadStatus.failed;
    }
    notifyListeners();
  }

  /// Completes when every change made so far has been written.
  Future<void> flush() => _saveChain;

  /// Writes the full current state again after a failed save.
  void retrySave() => _commit();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _commit() {
    notifyListeners();
    if (_loadStatus != LoadStatus.ready) return;
    // Encode now, so the saved snapshot matches this exact change even if
    // more changes happen before the write runs.
    final snapshot = encodePlannerData(
      PlannerData(
        categories: List.of(_categories),
        goals: List.of(_goals),
        periods: List.of(_periods),
        allocations: List.of(_allocations),
        entries: List.of(_entries),
      ),
    );
    _saveChain = _saveChain.then((_) => _write(snapshot));
  }

  Future<void> _write(String snapshot) async {
    _saveStatus = SaveStatus.saving;
    try {
      await storage.write(snapshot);
      _saveStatus = SaveStatus.saved;
    } on Object catch (e) {
      debugPrint('Planner save failed: ${e.runtimeType}');
      _saveStatus = SaveStatus.failed;
    }
    if (!_disposed) notifyListeners();
  }

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
    _commit();
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
    _commit();
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
    _commit();
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
      remainingMinutes: views.fold(0, (s, v) => s + v.todayRemaining),
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

  GoalProgressView goalView(String periodId) => _view(_period(periodId));

  /// Minutes planned on [date] by every goal except [excludePeriodId]; used
  /// to warn about capacity while a plan is being edited.
  int plannedOnExcluding(LocalDate date, {String? excludePeriodId}) =>
      _durationAllocations()
          .where((a) => a.date == date && a.goalPeriodId != excludePeriodId)
          .fold(0, (sum, a) => sum + a.allocatedValue);

  /// Sets the plan for the given days (0 removes a day). Throws
  /// [PlanEditRejectedException] for past days or invalid amounts.
  void updatePlan(String periodId, Map<LocalDate, int> changes) {
    final updated = applyPlanChanges(
      period: _period(periodId),
      allocations: _allocations,
      changes: changes,
      today: today,
      newId: generateUuidV4,
    );
    _allocations
      ..clear()
      ..addAll(updated);
    _commit();
  }

  /// What [changes] would do to the week, without saving anything.
  PlanPreview previewPlan(String periodId, Map<LocalDate, int> changes) {
    final period = _period(periodId);
    final draft = applyPlanChanges(
      period: period,
      allocations: _allocations,
      changes: changes,
      today: today,
      newId: () => 'preview',
    );
    return PlanPreview(
      remainingTarget: remainingTarget(period, _entries),
      remainingPlanned: remainingPlanned(
        period: period,
        allocations: draft,
        entries: _entries,
        today: today,
      ),
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
    _commit();
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
    _commit();
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
      debt: _debt(period),
      surplus: max(
        0,
        remainingPlanned(
              period: period,
              allocations: _allocations,
              entries: _entries,
              today: today,
            ) -
            remainingTarget(period, _entries),
      ),
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
    required this.surplus,
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

  /// Part of the remaining target no longer covered by the plan.
  final int debt;

  /// How much the plan from today on exceeds what is left of the target.
  /// Shortfalls of past days are settled, so they never count here.
  final int surplus;

  /// Today's plan minus today's work, never negative. Reminders always use
  /// this "not yet worked" amount (see docs/product/notification-rules.md).
  int get todayRemaining {
    final planned = todayAllocated ?? 0;
    return planned > todayDone ? planned - todayDone : 0;
  }

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

/// Live numbers shown while the user edits a plan. Past days are settled,
/// so the edit compares what is left to plan with what is left to do.
@immutable
class PlanPreview {
  const PlanPreview({
    required this.remainingTarget,
    required this.remainingPlanned,
  });

  final int remainingTarget;
  final int remainingPlanned;
}

@immutable
class TodaySummary {
  const TodaySummary({
    required this.plannedMinutes,
    required this.doneMinutes,
    required this.remainingMinutes,
    required this.capacity,
  });

  final int plannedMinutes;
  final int doneMinutes;

  /// Planned but not yet worked today — what reminders talk about.
  final int remainingMinutes;
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
