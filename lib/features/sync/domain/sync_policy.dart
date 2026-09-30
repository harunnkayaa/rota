import 'dart:convert';

import '../../goals/domain/progress_entry.dart';
import '../../planning/data/planner_data.dart';
import '../../planning/data/planner_json.dart';

enum SyncAction {
  /// Both sides are the same as after the last sync.
  none,

  /// Only this device changed: send it to the server.
  push,

  /// Only the server changed (another device): take the server's copy.
  pull,

  /// Both changed since the last sync: ask the user, never overwrite
  /// silently.
  conflict,
}

/// Decides what a sync should do.
///
/// [lastServerMarker] is the server's change marker seen at the last
/// successful sync on this device (null: never synced with this account).
/// [serverMarker] is the marker now.
SyncAction decideSync({
  required bool localDirty,
  required String? lastServerMarker,
  required String? serverMarker,
  required bool localEmpty,
  required bool serverEmpty,
}) {
  if (lastServerMarker == null) {
    // First sync of this account on this device.
    if (serverEmpty) return localEmpty ? SyncAction.none : SyncAction.push;
    if (localEmpty) return SyncAction.pull;
    return SyncAction.conflict;
  }
  final serverChanged = serverMarker != lastServerMarker;
  return switch ((localDirty, serverChanged)) {
    (false, false) => SyncAction.none,
    (false, true) => SyncAction.pull,
    (true, false) => SyncAction.push,
    (true, true) => SyncAction.conflict,
  };
}

/// Result of resolving a conflict in favour of one side.
class ConflictResolution {
  const ConflictResolution(this.data, {required this.unmatchedEntries});

  final PlannerData data;

  /// Progress from the other side whose goal doesn't exist in the chosen
  /// side, so it could not be kept (shown to the user, never silent).
  final int unmatchedEntries;
}

/// Keeps [winner]'s plans and settings, and adds every progress entry of
/// [other] that belongs to a period the winner has. Work logged on either
/// device is never lost just because the user picked the other side's
/// plan. Entries are matched by idempotency key, so nothing counts twice.
ConflictResolution resolveConflict({
  required PlannerData winner,
  required PlannerData other,
}) {
  final periodIds = {for (final p in winner.periods) p.id};
  final keys = {for (final e in winner.entries) e.idempotencyKey};
  final extra = <ProgressEntry>[];
  var unmatched = 0;
  for (final e in other.entries) {
    if (keys.contains(e.idempotencyKey)) continue;
    if (periodIds.contains(e.goalPeriodId)) {
      extra.add(e);
      keys.add(e.idempotencyKey);
    } else {
      unmatched++;
    }
  }
  return ConflictResolution(
    PlannerData(
      categories: winner.categories,
      goals: winner.goals,
      periods: winner.periods,
      allocations: winner.allocations,
      entries: [...winner.entries, ...extra],
      snapshots: winner.snapshots,
      reviewedPeriodIds: winner.reviewedPeriodIds,
      settings: winner.settings,
      activeFocus: winner.activeFocus,
      // The day's schedule is part of the plan: the chosen side's.
      blocks: winner.blocks,
    ),
    unmatchedEntries: unmatched,
  );
}

/// Combines two devices' changes made since their common [base] (the data
/// of the last sync on this device). Returns null when both changed the
/// same record differently: that is a real conflict and the user decides.
///
/// Per record (by id): changed on one side only → that side; same change on
/// both → either; different changes → conflict. Progress entries are
/// append-only, so both sides' entries are kept. A closed week keeps the
/// server's snapshot: each device closes it on its own, with only the
/// closing time differing.
PlannerData? mergeThreeWay({
  required PlannerData base,
  required PlannerData local,
  required PlannerData server,
}) {
  final categories = _mergeRecords(
    base.categories,
    local.categories,
    server.categories,
    id: (c) => c.id,
    row: categoryToRow,
  );
  final goals = _mergeRecords(
    base.goals,
    local.goals,
    server.goals,
    id: (g) => g.id,
    row: goalToRow,
  );
  final periods = _mergeRecords(
    base.periods,
    local.periods,
    server.periods,
    id: (p) => p.id,
    row: periodToRow,
    // Both closed it: the same week result, closed at different moments.
    bothChanged: (l, s) => l.isClosed && s.isClosed ? s : null,
  );
  final allocations = _mergeRecords(
    base.allocations,
    local.allocations,
    server.allocations,
    id: (a) => a.id,
    row: allocationToRow,
  );
  final snapshots = _mergeRecords(
    base.snapshots,
    local.snapshots,
    server.snapshots,
    id: (x) => x.periodId,
    row: (x) => x.toJson(),
    bothChanged: (l, s) => s,
  );
  final blocks = _mergeRecords(
    base.blocks,
    local.blocks,
    server.blocks,
    id: (b) => b.id,
    row: blockToRow,
  );
  final settings = _mergeValue(
    base.settings,
    local.settings,
    server.settings,
    settingsToRow,
  );
  final focus = _mergeValue(
    base.activeFocus,
    local.activeFocus,
    server.activeFocus,
    (f) => f == null ? null : focusToRow(f),
  );
  if (categories == null ||
      goals == null ||
      periods == null ||
      allocations == null ||
      snapshots == null ||
      blocks == null ||
      settings == null ||
      focus == null) {
    return null;
  }

  final keys = <String>{};
  final entries = [
    for (final e in [...server.entries, ...local.entries])
      if (keys.add(e.idempotencyKey)) e,
  ];

  // Everything must still point at something that exists; otherwise one
  // side removed what the other built on, and the user should decide.
  final categoryIds = {for (final c in categories) c.id};
  final goalIds = {for (final g in goals) g.id};
  final periodIds = {for (final p in periods) p.id};
  final consistent =
      goals.every((g) => categoryIds.contains(g.categoryId)) &&
      periods.every((p) => goalIds.contains(p.goalId)) &&
      allocations.every((a) => periodIds.contains(a.goalPeriodId)) &&
      entries.every((e) => periodIds.contains(e.goalPeriodId)) &&
      blocks.every(
        (b) => b.goalPeriodId == null || periodIds.contains(b.goalPeriodId),
      ) &&
      (focus.value == null || periodIds.contains(focus.value!.goalPeriodId));
  if (!consistent) return null;

  return PlannerData(
    categories: categories,
    goals: goals,
    periods: periods,
    allocations: allocations,
    entries: entries,
    snapshots: snapshots,
    reviewedPeriodIds: {
      ...local.reviewedPeriodIds,
      ...server.reviewedPeriodIds,
    },
    settings: settings.value,
    activeFocus: focus.value,
    blocks: blocks,
  );
}

/// Null: conflict. Order: the server's records, then ones only added here.
List<T>? _mergeRecords<T>(
  List<T> base,
  List<T> local,
  List<T> server, {
  required String Function(T) id,
  required Map<String, Object?> Function(T) row,
  T? Function(T local, T server)? bothChanged,
}) {
  String key(T x) => jsonEncode(row(x));
  final b = {for (final x in base) id(x): x};
  final l = {for (final x in local) id(x): x};
  final s = {for (final x in server) id(x): x};
  final result = <T>[];
  for (final recordId in {...s.keys, ...l.keys, ...b.keys}) {
    final inBase = b[recordId];
    final inLocal = l[recordId];
    final inServer = s[recordId];
    final baseKey = inBase == null ? null : key(inBase);
    final localKey = inLocal == null ? null : key(inLocal);
    final serverKey = inServer == null ? null : key(inServer);

    final T? chosen;
    if (localKey == serverKey) {
      chosen = inServer;
    } else if (localKey == baseKey) {
      chosen = inServer; // only the server changed (or removed) it
    } else if (serverKey == baseKey) {
      chosen = inLocal; // only this device changed (or removed) it
    } else if (inLocal != null && inServer != null && bothChanged != null) {
      final picked = bothChanged(inLocal, inServer);
      if (picked == null) return null;
      chosen = picked;
    } else {
      return null;
    }
    if (chosen != null) result.add(chosen);
  }
  return result;
}

/// Wraps the result so that "no active focus" (null) differs from
/// "conflict" (null wrapper).
({T value})? _mergeValue<T>(
  T base,
  T local,
  T server,
  Map<String, Object?>? Function(T) row,
) {
  final b = jsonEncode(row(base));
  final l = jsonEncode(row(local));
  final s = jsonEncode(row(server));
  if (l == s || l == b) return (value: server);
  if (s == b) return (value: local);
  return null;
}

bool isPlannerDataEmpty(PlannerData d) =>
    d.categories.isEmpty && d.goals.isEmpty && d.entries.isEmpty;
