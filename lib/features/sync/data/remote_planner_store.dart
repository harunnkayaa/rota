import 'package:supabase_flutter/supabase_flutter.dart';

import '../../planning/data/planner_data.dart';
import '../../planning/data/planner_json.dart';
import '../../planning/domain/period_closing.dart';

/// What the server holds for the signed-in user.
class RemoteState {
  const RemoteState({required this.data, required this.marker});

  final PlannerData data;

  /// Changes whenever any device pushes (the profile's updated_at). Null
  /// when this account has never been synced.
  final String? marker;
}

/// The server side of sync. Two implementations: Supabase, and an
/// in-memory fake for tests.
abstract interface class RemotePlannerStore {
  Future<RemoteState> fetch();

  /// Makes the server hold exactly [data] (progress is only ever added),
  /// and returns the new marker.
  Future<String> push(PlannerData data);

  /// Deletes the account and every row of it.
  Future<void> deleteAccount();
}

/// Row Level Security does the access control: every query only ever sees
/// the signed-in user's rows, and every insert is stamped with their id.
class SupabaseRemotePlannerStore implements RemotePlannerStore {
  SupabaseRemotePlannerStore(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in.');
    return id;
  }

  @override
  Future<RemoteState> fetch() async {
    final userId = _userId;
    final results = await Future.wait([
      _client.from('categories').select(),
      _client.from('goal_templates').select(),
      _client.from('goal_periods').select(),
      _client.from('daily_allocations').select(),
      _client.from('progress_entries').select(),
      _client.from('period_snapshots').select(),
      _client.from('focus_sessions').select().inFilter('status', [
        'running',
        'paused',
      ]),
      _client.from('profiles').select().eq('user_id', userId),
    ]);
    final [
      categories,
      goals,
      periods,
      allocations,
      entries,
      snapshots,
      focus,
      profiles,
    ] = results;
    final profile = profiles.isEmpty ? null : profiles.single;

    return RemoteState(
      marker: profile?['updated_at'] as String?,
      data: PlannerData(
        categories: [for (final r in categories) categoryFromRow(r)],
        goals: [for (final r in goals) goalFromRow(r)],
        periods: [for (final r in periods) periodFromRow(r)],
        allocations: [for (final r in allocations) allocationFromRow(r)],
        entries: [for (final r in entries) entryFromRow(r)],
        snapshots: [
          for (final r in snapshots)
            PeriodSnapshot.fromJson(
              r['snapshot_json']! as Map<String, Object?>,
            ),
        ],
        reviewedPeriodIds: {
          for (final r in snapshots)
            if (r['reviewed_at'] != null) r['period_id']! as String,
        },
        settings: profile == null ? null : settingsFromRow(profile),
        activeFocus: focus.isEmpty ? null : focusFromRow(focus.first),
      ),
    );
  }

  @override
  Future<String> push(PlannerData data) async {
    final userId = _userId;

    // Parents before children, so every foreign key already exists.
    await _upsert('categories', [
      for (final c in data.categories) categoryToRow(c),
    ]);
    await _upsert('goal_templates', [for (final g in data.goals) goalToRow(g)]);
    // A carry-over points to an earlier week: oldest first.
    final periods = [...data.periods]
      ..sort((a, b) => a.range.start.compareTo(b.range.start));
    await _upsert('goal_periods', [for (final p in periods) periodToRow(p)]);
    await _upsert('daily_allocations', [
      for (final a in data.allocations) allocationToRow(a),
    ]);

    // Progress is append-only; a retry with the same key is ignored.
    if (data.entries.isNotEmpty) {
      await _client
          .from('progress_entries')
          .upsert(
            [for (final e in data.entries) entryToRow(e)],
            onConflict: 'user_id,idempotency_key',
            ignoreDuplicates: true,
          );
    }
    if (data.snapshots.isNotEmpty) {
      await _client
          .from('period_snapshots')
          .upsert(
            [
              for (final s in data.snapshots)
                {
                  'period_id': s.periodId,
                  'snapshot_json': s.toJson(),
                  'closed_at': s.closedAt.toIso8601String(),
                },
            ],
            onConflict: 'period_id',
            ignoreDuplicates: true,
          );
    }
    if (data.reviewedPeriodIds.isNotEmpty) {
      await _client
          .from('period_snapshots')
          .update({'reviewed_at': DateTime.now().toUtc().toIso8601String()})
          .inFilter('period_id', data.reviewedPeriodIds.toList())
          .isFilter('reviewed_at', null);
    }

    // Removed here → removed there. Children first.
    await _deleteMissing('daily_allocations', {
      for (final a in data.allocations) a.id,
    });
    await _deleteMissing('goal_periods', {for (final p in data.periods) p.id});
    await _deleteMissing('goal_templates', {for (final g in data.goals) g.id});
    await _deleteMissing('categories', {for (final c in data.categories) c.id});

    await _client.from('focus_sessions').delete().eq('user_id', userId);
    if (data.activeFocus case final focus?) {
      await _client.from('focus_sessions').insert(focusToRow(focus));
    }

    // Always written last: its updated_at is the marker other devices use
    // to notice that something changed.
    final profile = await _client
        .from('profiles')
        .upsert({...settingsToRow(data.settings), 'user_id': userId})
        .select('updated_at')
        .single();
    return profile['updated_at']! as String;
  }

  @override
  Future<void> deleteAccount() => _client.rpc<void>('delete_my_account');

  Future<void> _upsert(String table, List<Row> rows) async {
    if (rows.isEmpty) return;
    await _client.from(table).upsert(rows);
  }

  Future<void> _deleteMissing(String table, Set<String> keep) async {
    final query = _client.from(table).delete().eq('user_id', _userId);
    if (keep.isEmpty) {
      await query;
    } else {
      await query.not('id', 'in', '(${keep.join(',')})');
    }
  }
}
