import '../../goals/domain/progress_entry.dart';
import '../../planning/data/planner_data.dart';

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
    ),
    unmatchedEntries: unmatched,
  );
}

bool isPlannerDataEmpty(PlannerData d) =>
    d.categories.isEmpty && d.goals.isEmpty && d.entries.isEmpty;
