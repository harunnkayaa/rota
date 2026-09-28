import 'dart:convert';

import '../../../core/time/local_date.dart';
import '../../../core/time/period_range.dart';
import '../../categories/domain/category.dart';
import '../../focus/domain/focus_session.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';
import '../../reminders/domain/reminder_planner.dart';
import '../../settings/domain/planner_settings.dart';
import '../domain/period_closing.dart';
import 'planner_data.dart';

/// Bump when the stored shape changes, and add a migration in
/// [decodePlannerData].
///
/// v1 → v2: goals got `default_target_value`; period snapshots, reviewed
/// periods, settings and the active focus session were added.
const plannerSchemaVersion = 2;

/// Keys match the future SQL column names (CLAUDE.md §9), so the same
/// mapping carries over to Supabase rows in Phase 2.
String encodePlannerData(PlannerData data) => jsonEncode({
  'schema_version': plannerSchemaVersion,
  'categories': [
    for (final c in data.categories)
      {
        'id': c.id,
        'name': c.name,
        'icon_key': c.iconKey,
        'preset': c.preset?.name,
        'is_sensitive': c.isSensitive,
        'is_archived': c.isArchived,
      },
  ],
  'goals': [
    for (final g in data.goals)
      {
        'id': g.id,
        'category_id': g.categoryId,
        'title': g.title,
        'goal_type': g.goalType.name,
        'measurement_type': g.measurementType.name,
        'default_target_value': g.defaultTargetValue,
        'is_sensitive': g.isSensitive,
        'is_active': g.isActive,
      },
  ],
  'goal_periods': [
    for (final p in data.periods)
      {
        'id': p.id,
        'goal_template_id': p.goalId,
        'period_type': p.periodType.name,
        'start_date': p.range.start.toString(),
        'end_date_exclusive': p.range.endExclusive.toString(),
        'target_value': p.targetValue,
        'carryover_from_period_id': p.carryoverFromPeriodId,
        'closed_at': p.closedAt?.toIso8601String(),
      },
  ],
  'daily_allocations': [
    for (final a in data.allocations)
      {
        'id': a.id,
        'goal_period_id': a.goalPeriodId,
        'target_date': a.date.toString(),
        'allocated_value': a.allocatedValue,
      },
  ],
  'progress_entries': [
    for (final e in data.entries)
      {
        'id': e.id,
        'goal_period_id': e.goalPeriodId,
        'value_delta': e.valueDelta,
        'source': e.source.name,
        'occurred_at': e.occurredAt.toIso8601String(),
        'local_date': e.localDate.toString(),
        'idempotency_key': e.idempotencyKey,
        'note': e.note,
      },
  ],
  'period_snapshots': [for (final s in data.snapshots) s.toJson()],
  'reviewed_period_ids': data.reviewedPeriodIds.toList()..sort(),
  'settings': {
    'daily_capacity_minutes': data.settings.dailyCapacityMinutes,
    'weekday_capacity_minutes': {
      for (final MapEntry(key: day, value: minutes)
          in data.settings.weekdayCapacityMinutes.entries)
        '$day': minutes,
    },
    'week_start_day': data.settings.weekStartDay,
    'reminders': {
      'enabled': data.settings.reminders.enabled,
      'daily_time_minutes': data.settings.reminders.dailyTimeMinutes,
      'quiet_start_minutes': data.settings.reminders.quietStartMinutes,
      'quiet_end_minutes': data.settings.reminders.quietEndMinutes,
      'daily_budget': data.settings.reminders.dailyBudget,
      'show_sensitive_details': data.settings.reminders.showSensitiveDetails,
    },
  },
  'active_focus': switch (data.activeFocus) {
    null => null,
    final f => {
      'id': f.id,
      'goal_period_id': f.goalPeriodId,
      'started_at': f.startedAt.toIso8601String(),
      'paused_at': f.pausedAt?.toIso8601String(),
      'paused_seconds': f.pausedSeconds,
    },
  },
});

/// Throws [FormatException] for anything that isn't a valid save file.
///
/// Every record goes back through the domain constructors, so stored data
/// that breaks an invariant is refused instead of silently loaded.
PlannerData decodePlannerData(String source) {
  try {
    final root = jsonDecode(source) as Map<String, Object?>;
    final version = root['schema_version'] as int;
    if (version < 1 || version > plannerSchemaVersion) {
      throw FormatException('Unsupported schema version $version');
    }
    final periods = [for (final m in _list(root, 'goal_periods')) _period(m)];
    final goals = [for (final m in _list(root, 'goals')) _goal(m)];

    return PlannerData(
      categories: [
        for (final m in _list(root, 'categories'))
          GoalCategory(
            id: m['id'] as String,
            name: m['name'] as String,
            iconKey: m['icon_key'] as String,
            preset: _enumOrNull(PresetCategory.values, m['preset']),
            isSensitive: m['is_sensitive'] as bool,
            isArchived: m['is_archived'] as bool,
          ),
      ],
      goals: version == 1 ? _migrateGoalsFromV1(goals, periods) : goals,
      periods: periods,
      allocations: [
        for (final m in _list(root, 'daily_allocations'))
          DailyAllocation(
            id: m['id'] as String,
            goalPeriodId: m['goal_period_id'] as String,
            date: LocalDate.parse(m['target_date'] as String),
            allocatedValue: m['allocated_value'] as int,
          ),
      ],
      entries: [
        for (final m in _list(root, 'progress_entries'))
          ProgressEntry(
            id: m['id'] as String,
            goalPeriodId: m['goal_period_id'] as String,
            valueDelta: m['value_delta'] as int,
            source: ProgressSource.values.byName(m['source'] as String),
            occurredAt: DateTime.parse(m['occurred_at'] as String),
            localDate: LocalDate.parse(m['local_date'] as String),
            idempotencyKey: m['idempotency_key'] as String,
            note: m['note'] as String?,
          ),
      ],
      snapshots: version == 1
          ? const []
          : [
              for (final m in _list(root, 'period_snapshots'))
                PeriodSnapshot.fromJson(m),
            ],
      reviewedPeriodIds: version == 1
          ? const {}
          : {
              for (final id in root['reviewed_period_ids'] as List<Object?>)
                id as String,
            },
      settings: version == 1
          ? null
          : _settings(root['settings'] as Map<String, Object?>),
      activeFocus: switch (root['active_focus']) {
        null => null,
        final Map<String, Object?> m => FocusSession(
          id: m['id'] as String,
          goalPeriodId: m['goal_period_id'] as String,
          startedAt: DateTime.parse(m['started_at'] as String),
          pausedAt: switch (m['paused_at']) {
            null => null,
            final String s => DateTime.parse(s),
            _ => throw const FormatException('paused_at'),
          },
          pausedSeconds: m['paused_seconds'] as int,
        ),
        _ => throw const FormatException('active_focus'),
      },
    );
  } on FormatException {
    rethrow;
  } on Object catch (e) {
    // Wrong types (TypeError), unknown enum names or broken invariants
    // (ArgumentError) all mean the same thing to the caller: unreadable.
    throw FormatException('Invalid planner data: ${e.runtimeType}');
  }
}

/// v1 had no weekly default: take it from each weekly goal's latest week.
List<Goal> _migrateGoalsFromV1(List<Goal> goals, List<GoalPeriod> periods) => [
  for (final goal in goals)
    switch ([
      for (final p in periods)
        if (p.goalId == goal.id && p.periodType == PeriodType.calendarWeek) p,
    ]..sort((a, b) => a.range.start.compareTo(b.range.start))) {
      [..., final latest] when goal.goalType == GoalType.flexibleQuota =>
        goal.withDefaultTarget(latest.targetValue),
      _ => goal,
    },
];

Goal _goal(Map<String, Object?> m) => Goal(
  id: m['id'] as String,
  categoryId: m['category_id'] as String,
  title: m['title'] as String,
  goalType: GoalType.values.byName(m['goal_type'] as String),
  measurementType: MeasurementType.values.byName(
    m['measurement_type'] as String,
  ),
  defaultTargetValue: m['default_target_value'] as int?,
  isSensitive: m['is_sensitive'] as bool,
  isActive: m['is_active'] as bool,
);

PlannerSettings _settings(Map<String, Object?> m) => PlannerSettings(
  dailyCapacityMinutes: m['daily_capacity_minutes'] as int,
  weekdayCapacityMinutes: {
    for (final MapEntry(key: day, value: minutes)
        in (m['weekday_capacity_minutes'] as Map<String, Object?>).entries)
      int.parse(day): minutes as int,
  },
  weekStartDay: m['week_start_day'] as int,
  // Added within v2: files saved before reminders existed use defaults.
  reminders: switch (m['reminders']) {
    null => const ReminderSettings(),
    final Map<String, Object?> r => ReminderSettings(
      enabled: r['enabled'] as bool,
      dailyTimeMinutes: r['daily_time_minutes'] as int,
      quietStartMinutes: r['quiet_start_minutes'] as int,
      quietEndMinutes: r['quiet_end_minutes'] as int,
      dailyBudget: r['daily_budget'] as int,
      showSensitiveDetails: r['show_sensitive_details'] as bool,
    ),
    _ => throw const FormatException('reminders'),
  },
);

GoalPeriod _period(Map<String, Object?> m) {
  final period = GoalPeriod(
    id: m['id'] as String,
    goalId: m['goal_template_id'] as String,
    periodType: PeriodType.values.byName(m['period_type'] as String),
    range: PeriodRange(
      LocalDate.parse(m['start_date'] as String),
      LocalDate.parse(m['end_date_exclusive'] as String),
    ),
    targetValue: m['target_value'] as int,
    carryoverFromPeriodId: m['carryover_from_period_id'] as String?,
  );
  final closedAt = m['closed_at'] as String?;
  // Re-closing goes through the same checks as closing did originally.
  return closedAt == null ? period : period.close(DateTime.parse(closedAt));
}

List<Map<String, Object?>> _list(Map<String, Object?> root, String key) =>
    (root[key] as List<Object?>).cast<Map<String, Object?>>();

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) =>
    name == null ? null : values.byName(name as String);
