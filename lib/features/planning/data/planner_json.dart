import 'dart:convert';

import '../../../core/time/local_date.dart';
import '../../../core/time/period_range.dart';
import '../../categories/domain/category.dart';
import '../../goals/domain/daily_allocation.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_period.dart';
import '../../goals/domain/progress_entry.dart';
import 'planner_data.dart';

/// Bump when the stored shape changes, and add a migration in [decodePlannerData].
const plannerSchemaVersion = 1;

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
});

/// Throws [FormatException] for anything that isn't a valid save file.
///
/// Every record goes back through the domain constructors, so stored data
/// that breaks an invariant is refused instead of silently loaded.
PlannerData decodePlannerData(String source) {
  try {
    final root = jsonDecode(source) as Map<String, Object?>;
    final version = root['schema_version'] as int;
    if (version != plannerSchemaVersion) {
      throw FormatException('Unsupported schema version $version');
    }
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
      goals: [
        for (final m in _list(root, 'goals'))
          Goal(
            id: m['id'] as String,
            categoryId: m['category_id'] as String,
            title: m['title'] as String,
            goalType: GoalType.values.byName(m['goal_type'] as String),
            measurementType: MeasurementType.values.byName(
              m['measurement_type'] as String,
            ),
            isSensitive: m['is_sensitive'] as bool,
            isActive: m['is_active'] as bool,
          ),
      ],
      periods: [for (final m in _list(root, 'goal_periods')) _period(m)],
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
    );
  } on FormatException {
    rethrow;
  } on Object catch (e) {
    // Wrong types (TypeError), unknown enum names or broken invariants
    // (ArgumentError) all mean the same thing to the caller: unreadable.
    throw FormatException('Invalid planner data: ${e.runtimeType}');
  }
}

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
