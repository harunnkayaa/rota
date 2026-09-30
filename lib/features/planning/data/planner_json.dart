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
import '../../schedule/domain/time_block.dart';
import '../../settings/domain/planner_settings.dart';
import '../domain/period_closing.dart';
import 'planner_data.dart';

/// Bump when the stored shape changes, and add a migration in
/// [decodePlannerData].
///
/// v1 → v2: goals got `default_target_value`; period snapshots, reviewed
/// periods, settings and the active focus session were added.
/// v2 → v3: time blocks (the day's schedule) were added.
const plannerSchemaVersion = 3;

// ---------------------------------------------------------------------------
// Row mappers. Keys are the SQL column names (supabase/migrations), so the
// save file and the database use exactly the same shape. Readers ignore
// extra server columns (user_id, created_at, version, ...).
// ---------------------------------------------------------------------------

typedef Row = Map<String, Object?>;

Row categoryToRow(GoalCategory c) => {
  'id': c.id,
  'name': c.name,
  'icon_key': c.iconKey,
  'preset': c.preset?.name,
  'is_sensitive': c.isSensitive,
  'is_archived': c.isArchived,
};

GoalCategory categoryFromRow(Row m) => GoalCategory(
  id: m['id']! as String,
  name: m['name']! as String,
  iconKey: m['icon_key']! as String,
  preset: _enumOrNull(PresetCategory.values, m['preset']),
  isSensitive: m['is_sensitive']! as bool,
  isArchived: m['is_archived']! as bool,
);

Row goalToRow(Goal g) => {
  'id': g.id,
  'category_id': g.categoryId,
  'title': g.title,
  'goal_type': g.goalType.name,
  'measurement_type': g.measurementType.name,
  'default_target_value': g.defaultTargetValue,
  'is_sensitive': g.isSensitive,
  'is_active': g.isActive,
};

Goal goalFromRow(Row m) => Goal(
  id: m['id']! as String,
  categoryId: m['category_id']! as String,
  title: m['title']! as String,
  goalType: GoalType.values.byName(m['goal_type']! as String),
  measurementType: MeasurementType.values.byName(
    m['measurement_type']! as String,
  ),
  defaultTargetValue: m['default_target_value'] as int?,
  isSensitive: m['is_sensitive']! as bool,
  isActive: m['is_active']! as bool,
);

Row periodToRow(GoalPeriod p) => {
  'id': p.id,
  'goal_template_id': p.goalId,
  'period_type': p.periodType.name,
  'start_date': p.range.start.toString(),
  'end_date_exclusive': p.range.endExclusive.toString(),
  'target_value': p.targetValue,
  'carryover_from_period_id': p.carryoverFromPeriodId,
  'closed_at': p.closedAt?.toIso8601String(),
};

GoalPeriod periodFromRow(Row m) {
  final period = GoalPeriod(
    id: m['id']! as String,
    goalId: m['goal_template_id']! as String,
    periodType: PeriodType.values.byName(m['period_type']! as String),
    range: PeriodRange(
      LocalDate.parse(m['start_date']! as String),
      LocalDate.parse(m['end_date_exclusive']! as String),
    ),
    targetValue: m['target_value']! as int,
    carryoverFromPeriodId: m['carryover_from_period_id'] as String?,
  );
  final closedAt = m['closed_at'] as String?;
  // Re-closing goes through the same checks as closing did originally.
  return closedAt == null ? period : period.close(DateTime.parse(closedAt));
}

Row allocationToRow(DailyAllocation a) => {
  'id': a.id,
  'goal_period_id': a.goalPeriodId,
  'target_date': a.date.toString(),
  'allocated_value': a.allocatedValue,
};

DailyAllocation allocationFromRow(Row m) => DailyAllocation(
  id: m['id']! as String,
  goalPeriodId: m['goal_period_id']! as String,
  date: LocalDate.parse(m['target_date']! as String),
  allocatedValue: m['allocated_value']! as int,
);

Row blockToRow(TimeBlock b) => {
  'id': b.id,
  'block_date': b.date.toString(),
  'start_minute': b.startMinute,
  'end_minute': b.endMinute,
  'kind': b.kind.name,
  'goal_period_id': b.goalPeriodId,
  'title': b.title,
  'remind': b.remind,
};

TimeBlock blockFromRow(Row m) => TimeBlock(
  id: m['id']! as String,
  date: LocalDate.parse(m['block_date']! as String),
  startMinute: m['start_minute']! as int,
  endMinute: m['end_minute']! as int,
  kind: TimeBlockKind.values.byName(m['kind']! as String),
  goalPeriodId: m['goal_period_id'] as String?,
  title: m['title'] as String?,
  remind: m['remind']! as bool,
);

Row entryToRow(ProgressEntry e) => {
  'id': e.id,
  'goal_period_id': e.goalPeriodId,
  'value_delta': e.valueDelta,
  'source': e.source.name,
  'occurred_at': e.occurredAt.toIso8601String(),
  'local_date': e.localDate.toString(),
  'idempotency_key': e.idempotencyKey,
  'note': e.note,
};

ProgressEntry entryFromRow(Row m) => ProgressEntry(
  id: m['id']! as String,
  goalPeriodId: m['goal_period_id']! as String,
  valueDelta: m['value_delta']! as int,
  source: ProgressSource.values.byName(m['source']! as String),
  occurredAt: DateTime.parse(m['occurred_at']! as String).toUtc(),
  localDate: LocalDate.parse(m['local_date']! as String),
  idempotencyKey: m['idempotency_key']! as String,
  note: m['note'] as String?,
);

/// The settings part of a profile row / the save file.
Row settingsToRow(PlannerSettings s) => {
  'daily_capacity_minutes': s.dailyCapacityMinutes,
  'weekday_capacity_minutes': {
    for (final MapEntry(key: day, value: minutes)
        in s.weekdayCapacityMinutes.entries)
      '$day': minutes,
  },
  'week_start_day': s.weekStartDay,
  'reminders': {
    'enabled': s.reminders.enabled,
    'daily_time_minutes': s.reminders.dailyTimeMinutes,
    'quiet_start_minutes': s.reminders.quietStartMinutes,
    'quiet_end_minutes': s.reminders.quietEndMinutes,
    'daily_budget': s.reminders.dailyBudget,
    'show_sensitive_details': s.reminders.showSensitiveDetails,
  },
};

PlannerSettings settingsFromRow(Row m) => PlannerSettings(
  dailyCapacityMinutes: m['daily_capacity_minutes']! as int,
  weekdayCapacityMinutes: {
    for (final MapEntry(key: day, value: minutes)
        in (m['weekday_capacity_minutes']! as Map<String, Object?>).entries)
      int.parse(day): minutes! as int,
  },
  weekStartDay: m['week_start_day']! as int,
  // Missing or empty (older files, a fresh server profile): defaults.
  reminders: switch (m['reminders']) {
    final Map<String, Object?> r when r.isNotEmpty => ReminderSettings(
      enabled: r['enabled']! as bool,
      dailyTimeMinutes: r['daily_time_minutes']! as int,
      quietStartMinutes: r['quiet_start_minutes']! as int,
      quietEndMinutes: r['quiet_end_minutes']! as int,
      dailyBudget: r['daily_budget']! as int,
      showSensitiveDetails: r['show_sensitive_details']! as bool,
    ),
    null || Map<String, Object?>() => const ReminderSettings(),
    _ => throw const FormatException('reminders'),
  },
);

Row focusToRow(FocusSession f) => {
  'id': f.id,
  'goal_period_id': f.goalPeriodId,
  'started_at': f.startedAt.toIso8601String(),
  'paused_at': f.pausedAt?.toIso8601String(),
  'paused_seconds': f.pausedSeconds,
  'status': f.isPaused ? 'paused' : 'running',
};

FocusSession focusFromRow(Row m) => FocusSession(
  id: m['id']! as String,
  goalPeriodId: m['goal_period_id']! as String,
  startedAt: DateTime.parse(m['started_at']! as String).toUtc(),
  pausedAt: switch (m['paused_at']) {
    null => null,
    final String s => DateTime.parse(s).toUtc(),
    _ => throw const FormatException('paused_at'),
  },
  pausedSeconds: m['paused_seconds']! as int,
);

// ---------------------------------------------------------------------------
// Save file
// ---------------------------------------------------------------------------

String encodePlannerData(PlannerData data) => jsonEncode({
  'schema_version': plannerSchemaVersion,
  'categories': [for (final c in data.categories) categoryToRow(c)],
  'goals': [for (final g in data.goals) goalToRow(g)],
  'goal_periods': [for (final p in data.periods) periodToRow(p)],
  'daily_allocations': [for (final a in data.allocations) allocationToRow(a)],
  'progress_entries': [for (final e in data.entries) entryToRow(e)],
  'period_snapshots': [for (final s in data.snapshots) s.toJson()],
  'reviewed_period_ids': data.reviewedPeriodIds.toList()..sort(),
  'settings': settingsToRow(data.settings),
  'active_focus': switch (data.activeFocus) {
    null => null,
    final f => focusToRow(f),
  },
  'time_blocks': [for (final b in data.blocks) blockToRow(b)],
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
    final periods = [
      for (final m in _list(root, 'goal_periods')) periodFromRow(m),
    ];
    final goals = [for (final m in _list(root, 'goals')) goalFromRow(m)];

    return PlannerData(
      categories: [
        for (final m in _list(root, 'categories')) categoryFromRow(m),
      ],
      goals: version == 1 ? _migrateGoalsFromV1(goals, periods) : goals,
      periods: periods,
      allocations: [
        for (final m in _list(root, 'daily_allocations')) allocationFromRow(m),
      ],
      entries: [
        for (final m in _list(root, 'progress_entries')) entryFromRow(m),
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
          : settingsFromRow(root['settings'] as Map<String, Object?>),
      activeFocus: switch (root['active_focus']) {
        null => null,
        final Map<String, Object?> m => focusFromRow(m),
        _ => throw const FormatException('active_focus'),
      },
      blocks: version < 3
          ? const []
          : [for (final m in _list(root, 'time_blocks')) blockFromRow(m)],
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

List<Row> _list(Map<String, Object?> root, String key) =>
    (root[key] as List<Object?>).cast<Row>();

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) =>
    name == null ? null : values.byName(name as String);
