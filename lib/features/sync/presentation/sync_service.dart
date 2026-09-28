import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../planning/data/planner_data.dart';
import '../../planning/data/planner_storage.dart';
import '../../planning/presentation/planner_controller.dart';
import '../data/auth_gateway.dart';
import '../data/remote_planner_store.dart';
import '../domain/sync_policy.dart';

enum SyncStatus {
  /// This build has no server configured: local only.
  disabled,
  signedOut,
  syncing,

  /// Everything is on the server.
  synced,

  /// No connection; changes wait on the device and go out later.
  offline,

  /// Both sides changed; waiting for the user's choice.
  conflict,

  /// The server refused something; changes stay on the device.
  error,
}

/// What this device remembers about syncing (per account).
class _SyncState {
  _SyncState({
    this.userId,
    this.lastMarker,
    this.dirty = false,
    this.lastSyncedAt,
  });

  factory _SyncState.fromJson(Map<String, Object?> json) => _SyncState(
    userId: json['user_id'] as String?,
    lastMarker: json['last_marker'] as String?,
    dirty: json['dirty'] as bool? ?? false,
    lastSyncedAt: switch (json['last_synced_at']) {
      final String s => DateTime.parse(s),
      _ => null,
    },
  );

  String? userId;
  String? lastMarker;
  bool dirty;
  DateTime? lastSyncedAt;

  Map<String, Object?> toJson() => {
    'user_id': userId,
    'last_marker': lastMarker,
    'dirty': dirty,
    'last_synced_at': lastSyncedAt?.toIso8601String(),
  };
}

/// Keeps this device and the account in step (CLAUDE.md §16, local-first):
/// the app always works on the local copy; when signed in, changes are sent
/// in the background and other devices' changes are pulled in.
class SyncService extends ChangeNotifier {
  SyncService({
    required this.controller,
    required AuthGateway this.auth,
    required RemotePlannerStore this.remote,
    required this.stateStorage,
    this.debounce = const Duration(seconds: 2),
  }) : _status = SyncStatus.signedOut;

  /// A build without a server: sync is off, the app is local only.
  SyncService.disabled({required this.controller})
    : auth = null,
      remote = null,
      stateStorage = InMemoryPlannerStorage(),
      debounce = Duration.zero,
      _status = SyncStatus.disabled;

  final PlannerController controller;
  final AuthGateway? auth;
  final RemotePlannerStore? remote;
  final PlannerStorage stateStorage;
  final Duration debounce;

  SyncStatus _status;
  SyncStatus get status => _status;

  _SyncState _state = _SyncState();
  DateTime? get lastSyncedAt => _state.lastSyncedAt;
  bool get hasUnsentChanges => _state.dirty;
  String? get email => auth?.email;
  bool get isSignedIn => auth?.userId != null;

  int _seenRevision = 0;

  /// Counts user changes, to notice ones made during a sync round.
  int _localChanges = 0;
  bool _applyingRemote = false;
  bool _again = false;
  Timer? _timer;
  StreamSubscription<String?>? _userSub;
  RemoteState? _pendingConflict;

  Future<void> start() async {
    if (_status == SyncStatus.disabled) return;
    try {
      final raw = await stateStorage.read();
      if (raw != null) {
        _state = _SyncState.fromJson(jsonDecode(raw) as Map<String, Object?>);
      }
    } on Object catch (e) {
      debugPrint('Sync state unreadable: ${e.runtimeType}');
    }
    _seenRevision = controller.revision;
    controller.addListener(_onPlannerChanged);
    _userSub = auth!.userChanges.listen((_) => unawaited(sync()));
    if (isSignedIn) {
      unawaited(sync());
    } else {
      _setStatus(SyncStatus.signedOut);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_userSub?.cancel());
    controller.removeListener(_onPlannerChanged);
    super.dispose();
  }

  void _onPlannerChanged() {
    if (controller.revision == _seenRevision) return;
    _seenRevision = controller.revision;
    if (_applyingRemote) return;
    _localChanges++;
    if (!_state.dirty) {
      _state.dirty = true;
      unawaited(_saveState());
    }
    if (!isSignedIn) return;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(sync()));
  }

  /// One sync round. Safe to call any time; overlapping calls are merged.
  ///
  /// The returned future completes only when the round in progress — and
  /// any round requested meanwhile — has finished.
  Future<void> sync() async {
    if (_status == SyncStatus.disabled) return;
    final current = _current;
    if (current != null) {
      _again = true;
      await current;
      return;
    }
    final loop = _loop();
    _current = loop;
    try {
      await loop;
    } finally {
      _current = null;
    }
  }

  Future<void>? _current;

  Future<void> _loop() async {
    do {
      _again = false;
      await _syncOnce();
    } while (_again);
  }

  Future<void> _syncOnce() async {
    final userId = auth!.userId;
    if (userId == null) {
      _setStatus(SyncStatus.signedOut);
      return;
    }
    if (controller.loadStatus != LoadStatus.ready) return;
    _setStatus(SyncStatus.syncing);
    final changesBefore = _localChanges;
    try {
      if (_state.userId != userId) {
        // Another account on this device: treat as a first sync.
        _state
          ..userId = userId
          ..lastMarker = null
          ..lastSyncedAt = null;
      }
      final server = await remote!.fetch();
      final local = controller.snapshotData();
      final action = decideSync(
        localDirty: _state.dirty,
        lastServerMarker: _state.lastMarker,
        serverMarker: server.marker,
        localEmpty: isPlannerDataEmpty(local),
        serverEmpty: isPlannerDataEmpty(server.data),
      );
      switch (action) {
        case SyncAction.none:
          _state.lastMarker ??= server.marker;
          await _markSynced(_state.lastMarker);
        case SyncAction.push:
          await _markSynced(await remote!.push(local));
        case SyncAction.pull:
          _adopt(server.data);
          await _markSynced(server.marker);
        case SyncAction.conflict:
          _pendingConflict = server;
          await _saveState();
          _setStatus(SyncStatus.conflict);
          return;
      }
      if (_localChanges != changesBefore) {
        // The user changed something while this round was running: that
        // change is not on the server yet.
        _state.dirty = true;
        await _saveState();
        _again = true;
      }
      _setStatus(SyncStatus.synced);
    } on PostgrestException catch (e) {
      debugPrint('Sync refused by server: ${e.code}');
      _setStatus(SyncStatus.error);
    } on Object catch (e) {
      // Almost always no connection. Changes stay dirty and go out later.
      debugPrint('Sync failed: ${e.runtimeType}');
      _setStatus(SyncStatus.offline);
    }
  }

  /// The user's answer to a conflict. Returns how many progress entries of
  /// the other side belonged to goals that no longer exist, so the UI can
  /// say so. Work on shared goals is always kept from both sides.
  Future<int> chooseSide({required bool keepThisDevice}) async {
    final server = _pendingConflict;
    if (server == null) return 0;
    final local = controller.snapshotData();
    final resolution = resolveConflict(
      winner: keepThisDevice ? local : server.data,
      other: keepThisDevice ? server.data : local,
    );
    _pendingConflict = null;
    _setStatus(SyncStatus.syncing);
    try {
      _adopt(resolution.data);
      await _markSynced(await remote!.push(controller.snapshotData()));
      _setStatus(SyncStatus.synced);
    } on Object catch (e) {
      debugPrint('Conflict resolution failed: ${e.runtimeType}');
      _state.dirty = true;
      await _saveState();
      _setStatus(SyncStatus.offline);
    }
    return resolution.unmatchedEntries;
  }

  Future<void> signIn({required String email, required String password}) =>
      auth!.signIn(email: email, password: password);

  Future<void> signUp({required String email, required String password}) =>
      auth!.signUp(email: email, password: password);

  /// Signs out; the data stays on this device.
  Future<void> signOut() async {
    await auth!.signOut();
    _pendingConflict = null;
    _setStatus(SyncStatus.signedOut);
  }

  /// Deletes the account on the server and all data on this device.
  Future<void> deleteAccount() async {
    await remote!.deleteAccount();
    await auth!.signOut();
    _applyingRemote = true;
    controller.deleteAllData();
    _applyingRemote = false;
    _state = _SyncState();
    await _saveState();
    _setStatus(SyncStatus.signedOut);
  }

  void _adopt(PlannerData data) {
    _applyingRemote = true;
    try {
      controller.replaceAllData(data);
    } finally {
      _applyingRemote = false;
    }
    // A rollover right after adopting is a real local change.
    _seenRevision = controller.revision;
  }

  Future<void> _markSynced(String? marker) async {
    _state
      ..lastMarker = marker
      ..dirty = false
      ..lastSyncedAt = DateTime.now().toUtc();
    await _saveState();
  }

  Future<void> _saveState() async {
    try {
      await stateStorage.write(jsonEncode(_state.toJson()));
    } on Object catch (e) {
      debugPrint('Sync state not saved: ${e.runtimeType}');
    }
  }

  void _setStatus(SyncStatus status) {
    _status = status;
    notifyListeners();
  }
}

/// Gives screens access to the [SyncService].
class SyncScope extends InheritedNotifier<SyncService> {
  const SyncScope({
    required SyncService service,
    required super.child,
    super.key,
  }) : super(notifier: service);

  static SyncService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SyncScope>()!.notifier!;

  static SyncService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SyncScope>()?.notifier;
}
