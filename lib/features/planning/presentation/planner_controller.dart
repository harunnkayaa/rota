import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/period_range.dart';
import '../../../core/utils/uuid.dart';
import '../../categories/domain/category.dart';
import '../../focus/domain/focus_session.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';
import '../../reminders/domain/reminder_planner.dart';
import '../../reports/domain/weekly_report.dart';
import '../../settings/domain/planner_settings.dart';
import '../data/planner_data.dart';
import '../data/planner_json.dart';
import '../data/planner_storage.dart';
import '../domain/capacity.dart';
import '../domain/deadline_pace.dart';
import '../domain/period_closing.dart';
import '../domain/plan_editing.dart';
import '../domain/progress_calculator.dart';
import '../domain/redistribution.dart';
import '../domain/week_rollover.dart';

enum LoadStatus { loading, ready, failed }

enum SaveStatus { saved, saving, failed }

/// Holds the planner state for the UI and turns user actions into domain
/// operations.
///
/// Every change is saved to [storage] in the background, in order. Phase 2
/// adds Supabase sync behind the same public methods, so screens don't
/// change.
class PlannerController extends ChangeNotifier {
  PlannerController({required this.clock, PlannerStorage? storage})
    : storage = storage ?? InMemoryPlannerStorage();

  final Clock clock;
  final PlannerStorage storage;

  PlannerSettings _settings = PlannerSettings();
  PlannerSettings get settings => _settings;

  CapacityModel get capacity => CapacityModel(
    defaultDailyMinutes: _settings.dailyCapacityMinutes,
    weekdayMinutes: _settings.weekdayCapacityMinutes,
  );

  int get weekStartDay => _settings.weekStartDay;

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
      final data = raw == null ? PlannerData() : decodePlannerData(raw);
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
      _snapshots
        ..clear()
        ..addAll(data.snapshots);
      _reviewed
        ..clear()
        ..addAll(data.reviewedPeriodIds);
      _settings = data.settings;
      _activeFocus = data.activeFocus;
      _loadStatus = LoadStatus.ready;
    } on Object catch (e) {
      // Type only: the saved content may contain personal goal titles.
      debugPrint('Planner load failed: ${e.runtimeType}');
      _loadStatus = LoadStatus.failed;
    }
    notifyListeners();
    if (_loadStatus == LoadStatus.ready) refreshDay();
  }

  /// Call when the app comes back to the foreground or the day may have
  /// changed: closes ended periods and opens this week's periods.
  void refreshDay() {
    if (_loadStatus != LoadStatus.ready) return;
    final plan = planWeekRollover(
      goals: _goals,
      periods: _periods,
      allocations: _allocations,
      entries: _entries,
      today: today,
      currentWeek: currentWeek,
      nowUtc: clock.nowUtc(),
      newId: generateUuidV4,
    );
    if (plan.isEmpty) {
      notifyListeners();
      return;
    }
    for (final result in plan.closed) {
      final index = _periods.indexWhere((p) => p.id == result.closedPeriod.id);
      _periods[index] = result.closedPeriod;
      _snapshots.add(result.snapshot);
    }
    _periods.addAll(plan.opened);
    _allocations.addAll(plan.openedAllocations);
    _commit();
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
    final snapshot = encodePlannerData(_currentData());
    _saveChain = _saveChain.then((_) => _write(snapshot));
  }

  PlannerData _currentData() => PlannerData(
    categories: List.of(_categories),
    goals: List.of(_goals),
    periods: List.of(_periods),
    allocations: List.of(_allocations),
    entries: List.of(_entries),
    snapshots: List.of(_snapshots),
    reviewedPeriodIds: Set.of(_reviewed),
    settings: _settings,
    activeFocus: _activeFocus,
  );

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
  final _snapshots = <PeriodSnapshot>[];
  final _reviewed = <String>{};
  FocusSession? _activeFocus;

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
      defaultTargetValue: targetMinutes,
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
    _allocations.addAll(_allocationsFor(period.id, dailyPlan));
    _commit();
    return period;
  }

  /// Creates a goal with a due date ("PTE sınavı, 15 Kasım, 40 saat").
  /// Work is planned from today until the day before [dueDate].
  GoalPeriod createDeadlineGoal({
    required String categoryId,
    required String title,
    required int totalMinutes,
    required LocalDate dueDate,
    required Map<LocalDate, int> dailyPlan,
  }) {
    final category = _categories.firstWhere((c) => c.id == categoryId);
    if (!today.isBefore(dueDate)) {
      throw ArgumentError.value(dueDate, 'dueDate', 'Must be after today');
    }
    final range = PeriodRange(today, dueDate);
    if (dailyPlan.keys.any((d) => !range.contains(d))) {
      throw ArgumentError('Daily plan must stay inside $range.');
    }
    final goal = Goal(
      id: generateUuidV4(),
      categoryId: categoryId,
      title: title,
      goalType: GoalType.deadline,
      measurementType: MeasurementType.durationMinutes,
      isSensitive: category.isSensitive,
    );
    final period = GoalPeriod(
      id: generateUuidV4(),
      goalId: goal.id,
      periodType: PeriodType.custom,
      range: range,
      targetValue: totalMinutes,
    );
    _goals.add(goal);
    _periods.add(period);
    _allocations.addAll(_allocationsFor(period.id, dailyPlan));
    _commit();
    return period;
  }

  /// Pace of a deadline goal that is still being filled in on the form.
  DeadlinePace previewDeadline({
    required int totalMinutes,
    required LocalDate dueDate,
    required Map<LocalDate, int> dailyPlan,
  }) {
    const draftId = 'draft';
    final period = GoalPeriod(
      id: draftId,
      goalId: draftId,
      periodType: PeriodType.custom,
      range: PeriodRange(today, dueDate),
      targetValue: totalMinutes,
    );
    return computeDeadlinePace(
      period: period,
      allocations: _allocationsFor(draftId, dailyPlan),
      entries: const [],
      today: today,
      week: currentWeek,
      freeCapacityOn: freeCapacityFor,
    );
  }

  /// Capacity left on [day] after every goal except [periodId]; a goal's
  /// own plan is time it may use.
  int freeCapacityFor(LocalDate day, {String? periodId}) => max(
    0,
    capacity.capacityOn(day) -
        plannedOnExcluding(day, excludePeriodId: periodId),
  );

  /// Changes a goal's target; progress is kept and every derived number
  /// (pace, remaining, debt) follows automatically. For a weekly goal the
  /// new value also becomes the target of the weeks that follow.
  void updateTarget(String periodId, int targetMinutes) {
    final index = _periods.indexWhere((p) => p.id == periodId);
    final period = _periods[index];
    _periods[index] = period.withTarget(targetMinutes);
    final goalIndex = _goals.indexWhere((g) => g.id == period.goalId);
    if (_goals[goalIndex].goalType == GoalType.flexibleQuota) {
      _goals[goalIndex] = _goals[goalIndex].withDefaultTarget(targetMinutes);
    }
    _commit();
  }

  /// Stops a goal: it leaves Today and Week and no new weeks are opened.
  /// Its history stays in reports.
  void archiveGoal(String goalId) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    _goals[index] = _goals[index].archived();
    _commit();
  }

  /// Name of any category, including archived ones (reports keep history).
  String categoryName(String categoryId) {
    for (final c in _categories) {
      if (c.id == categoryId) return c.name;
    }
    return '';
  }

  GoalCategory? categoryById(String categoryId) {
    for (final c in _categories) {
      if (c.id == categoryId) return c;
    }
    return null;
  }

  /// This week so far: weekly goals against their target, deadline goals
  /// against this week's pace share.
  WeekSummary currentWeekSummary() => WeekSummary(
    range: currentWeek,
    lines: [
      for (final v in activeGoals())
        GoalWeekLine(
          goalId: v.goal.id,
          title: v.goal.title,
          categoryId: v.goal.categoryId,
          target: v.pace?.requiredThisWeek ?? v.period.targetValue,
          done: v.pace?.doneThisWeek ?? v.periodDone,
        ),
    ],
  );

  /// Every frozen result of a closed period, newest week first.
  List<PeriodSnapshot> get snapshots {
    final sorted = List<PeriodSnapshot>.of(_snapshots)
      ..sort((a, b) => b.range.start.compareTo(a.range.start));
    return List.unmodifiable(sorted);
  }

  /// Results the user hasn't looked at yet (shown once, on Today).
  List<PeriodSnapshot> get pendingReviews => [
    for (final s in snapshots)
      if (!_reviewed.contains(s.periodId)) s,
  ];

  void markReviewed() {
    _reviewed.addAll(_snapshots.map((s) => s.periodId));
    _commit();
  }

  /// This week's open period of [goalId], if the goal is still running.
  GoalPeriod? currentPeriodOf(String goalId) {
    for (final p in _periods) {
      if (p.goalId == goalId && !p.isClosed && p.range.contains(today)) {
        return p;
      }
    }
    return null;
  }

  /// Whether [snapshot]'s shortfall can still be added to this week.
  bool canCarryOver(PeriodSnapshot snapshot) {
    final week = currentPeriodOf(snapshot.goalId);
    return snapshot.shortfall > 0 &&
        snapshot.goalType == GoalType.flexibleQuota &&
        week != null &&
        week.carryoverFromPeriodId == null &&
        !_periods.any((p) => p.carryoverFromPeriodId == snapshot.periodId);
  }

  /// Adds last week's shortfall to this week's target — only when the
  /// user asks for it (CLAUDE.md §4.3).
  void carryOver(PeriodSnapshot snapshot) {
    final week = currentPeriodOf(snapshot.goalId)!;
    final updated = carryOverIntoWeek(
      week: week,
      snapshot: snapshot,
      amount: snapshot.shortfall,
      existingPeriods: _periods,
    );
    _periods[_periods.indexWhere((p) => p.id == week.id)] = updated;
    _commit();
  }

  /// Everything Rota stores about the user, as readable JSON
  /// (CLAUDE.md §4.6: the data belongs to the user).
  String exportJson() => const JsonEncoder.withIndent(
    '  ',
  ).convert(jsonDecode(encodePlannerData(_currentData())));

  /// Permanently removes every goal, plan, entry, result and setting from
  /// this device. The empty state is saved right away.
  void deleteAllData() {
    _categories.clear();
    _goals.clear();
    _periods.clear();
    _allocations.clear();
    _entries.clear();
    _snapshots.clear();
    _reviewed.clear();
    _settings = PlannerSettings();
    _activeFocus = null;
    _commit();
  }

  /// New capacity or week start. Existing weeks keep their dates; a new
  /// week start applies from the next week that is opened.
  void updateSettings(PlannerSettings settings) {
    _settings = settings;
    _commit();
  }

  /// The running or paused focus timer, if any.
  FocusSession? get activeFocus => _activeFocus;

  void startFocus(String periodId) {
    if (_activeFocus != null) {
      throw StateError('A focus session is already running.');
    }
    _activeFocus = FocusSession(
      id: generateUuidV4(),
      goalPeriodId: periodId,
      startedAt: clock.nowUtc(),
    );
    _commit();
  }

  void pauseFocus() {
    _activeFocus = _activeFocus?.pause(clock.nowUtc());
    _commit();
  }

  void resumeFocus() {
    _activeFocus = _activeFocus?.resume(clock.nowUtc());
    _commit();
  }

  /// Ends the timer and records the worked minutes as progress. Returns the
  /// minutes recorded (0 when less than a minute was worked). Throws
  /// [ProgressRejectedException] if the goal's period no longer accepts
  /// progress; the session is then kept so nothing is lost.
  int finishFocus({String? note}) {
    final session = _activeFocus;
    if (session == null) return 0;
    final minutes = session.workedMinutes(clock.nowUtc());
    if (minutes > 0) {
      final period = _period(session.goalPeriodId);
      final entry = ProgressEntry(
        id: generateUuidV4(),
        goalPeriodId: period.id,
        valueDelta: minutes,
        source: ProgressSource.focusTimer,
        occurredAt: clock.nowUtc(),
        localDate: today,
        idempotencyKey: session.idempotencyKey,
        note: note,
      );
      validateNewEntry(period, entry, _entries);
      _entries.add(entry);
    }
    _activeFocus = null;
    _commit();
    return minutes;
  }

  /// Throws the timer away without recording anything.
  void cancelFocus() {
    _activeFocus = null;
    _commit();
  }

  /// Other flexible goals with time planned but not yet done on the days a
  /// deadline goal could catch up. Only these may give time, and only with
  /// the user's explicit choice.
  List<GoalProgressView> catchUpDonors(String periodId) {
    final days = _catchUpDays(_period(periodId)).toSet();
    return [
      for (final v in activeGoals())
        if (v.period.id != periodId &&
            v.goal.goalType.isRedistributable &&
            v.days.any((d) => days.contains(d.date) && d.shortfall > 0))
          v,
    ];
  }

  CatchUpProposal proposeCatchUpFor(
    String periodId, {
    Set<String> donorPeriodIds = const {},
  }) {
    final period = _period(periodId);
    final days = _catchUpDays(period);
    return proposeCatchUp(
      gap: _view(period).pace?.thisWeekGap ?? 0,
      days: days,
      freeCapacityOn: (d) => capacityOn(d).free,
      donors: [
        for (final v in catchUpDonors(periodId))
          if (donorPeriodIds.contains(v.period.id))
            DonorPlan(
              periodId: v.period.id,
              plannedByDay: {
                for (final d in v.days)
                  if (days.contains(d.date) && d.shortfall > 0)
                    d.date: d.shortfall,
              },
            ),
      ],
    );
  }

  /// Applies a catch-up the user accepted: adds to the deadline goal and
  /// takes the same minutes from the chosen goals, all in one save.
  void applyCatchUp(String periodId, CatchUpProposal proposal) {
    int allocated(String id, LocalDate day) => _allocations
        .where((a) => a.goalPeriodId == id && a.date == day)
        .fold(0, (sum, a) => sum + a.allocatedValue);

    var updated = List.of(_allocations);
    final changes = {
      periodId: {
        for (final MapEntry(key: day, value: extra)
            in proposal.additions.entries)
          day: allocated(periodId, day) + extra,
      },
      for (final MapEntry(key: donorId, value: byDay)
          in proposal.reductions.entries)
        donorId: {
          for (final MapEntry(key: day, value: taken) in byDay.entries)
            day: allocated(donorId, day) - taken,
        },
    };
    for (final MapEntry(key: id, value: dayChanges) in changes.entries) {
      updated = applyPlanChanges(
        period: _period(id),
        allocations: updated,
        changes: dayChanges,
        today: today,
        newId: generateUuidV4,
      );
    }
    _allocations
      ..clear()
      ..addAll(updated);
    _commit();
  }

  List<LocalDate> _catchUpDays(GoalPeriod period) => [
    for (final d in currentWeek.days)
      if (!d.isBefore(today) && period.range.contains(d)) d,
  ];

  List<DailyAllocation> _allocationsFor(
    String periodId,
    Map<LocalDate, int> plan,
  ) => [
    for (final MapEntry(key: date, value: minutes) in plan.entries)
      if (minutes > 0)
        DailyAllocation(
          id: periodId == 'draft' ? 'draft-$date' : generateUuidV4(),
          goalPeriodId: periodId,
          date: date,
          allocatedValue: minutes,
        ),
  ];

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
      if (!p.isClosed && p.range.contains(today) && _goal(p.goalId).isActive)
        _view(p),
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

  /// What reminders could talk about today and tomorrow — always the time
  /// not yet worked (docs/product/notification-rules.md). Planning which of
  /// these become notifications is up to the reminder rules.
  List<ReminderCandidate> reminderCandidates() {
    final tomorrow = today.addDays(1);
    return [
      for (final v in activeGoals()) ...[
        if (v.todayRemaining > 0)
          ReminderCandidate(
            kind: ReminderKind.todayRemaining,
            periodId: v.period.id,
            date: today,
            goalTitle: v.goal.title,
            minutes: v.todayRemaining,
            isSensitive: v.goal.isSensitive,
          ),
        if (v.pace case final pace?
            when pace.status == DeadlineStatus.behindThisWeek)
          ReminderCandidate(
            kind: ReminderKind.paceBehind,
            periodId: v.period.id,
            date: today,
            goalTitle: v.goal.title,
            minutes: pace.thisWeekGap,
            isSensitive: v.goal.isSensitive,
          ),
        for (final d in v.days)
          if (d.date == tomorrow && d.inPeriod && d.shortfall > 0)
            ReminderCandidate(
              kind: ReminderKind.todayRemaining,
              periodId: v.period.id,
              date: tomorrow,
              goalTitle: v.goal.title,
              minutes: d.shortfall,
              isSensitive: v.goal.isSensitive,
            ),
      ],
    ];
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
    if (_goal(period.goalId).goalType == GoalType.deadline) {
      final pace = _pace(period, draft);
      return PlanPreview(
        remainingTarget: max(0, pace.requiredThisWeek - pace.doneThisWeek),
        remainingPlanned: pace.plannedRestOfWeek,
        weekPace: true,
      );
    }
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

    final isDeadline = goal.goalType == GoalType.deadline;
    return GoalProgressView(
      period: period,
      goal: goal,
      pace: isDeadline ? _pace(period, _allocations) : null,
      category: _categories.firstWhere((c) => c.id == goal.categoryId),
      todayAllocated: allocatedOn(today),
      todayDone: dailyProgress(period, today, _entries),
      periodDone: periodProgress(period, _entries),
      // A deadline goal spans many weeks: its plan beyond this week is
      // intentionally empty, so it is judged by pace, not by debt.
      debt: isDeadline ? 0 : _debt(period),
      surplus: isDeadline
          ? 0
          : max(
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
        for (final d in currentWeek.days)
          DayProgress(
            date: d,
            allocated: allocatedOn(d) ?? 0,
            done: dailyProgress(period, d, _entries),
            today: today,
            inPeriod: period.range.contains(d),
          ),
      ],
    );
  }

  DeadlinePace _pace(GoalPeriod period, List<DailyAllocation> allocations) =>
      computeDeadlinePace(
        period: period,
        allocations: allocations,
        entries: _entries,
        today: today,
        week: currentWeek,
        freeCapacityOn: (d) => freeCapacityFor(d, periodId: period.id),
      );

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
    required this.pace,
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

  /// Set for goals with a due date; null for weekly goals.
  final DeadlinePace? pace;

  bool get isDeadline => pace != null;

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
    this.inPeriod = true,
  }) : _today = today;

  final LocalDate date;
  final int allocated;
  final int done;
  final LocalDate _today;

  /// False for days of this week outside the goal's own dates (a deadline
  /// goal that starts mid-week or ends before Sunday).
  final bool inPeriod;

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
    this.weekPace = false,
  });

  final int remainingTarget;
  final int remainingPlanned;

  /// True for deadline goals: the numbers are this week's pace share, not
  /// the whole target.
  final bool weekPace;
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
