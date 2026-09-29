import 'dart:async';

import 'package:rota/features/planning/data/planner_data.dart';
import 'package:rota/features/planning/data/planner_json.dart';
import 'package:rota/features/sync/data/auth_gateway.dart';
import 'package:rota/features/sync/data/remote_planner_store.dart';

/// A pretend server, shared by several pretend devices. Each account has
/// its own data, like rows filtered by RLS on the real one.
class FakeServer {
  /// The account most tests use; [data] is its data.
  static const primaryUser = 'user-harun@example.test';

  final accounts = <String, PlannerData>{};
  final _versions = <String, int>{};
  bool offline = false;
  bool requireEmailConfirmation = false;
  final passwords = <String, String>{};

  PlannerData? get data => accounts[primaryUser];
  set data(PlannerData? value) => _put(primaryUser, value);

  String? markerOf(String user) =>
      accounts[user] == null ? null : 'v${_versions[user] ?? 0}';
  String? get marker => markerOf(primaryUser);

  void _put(String user, PlannerData? value) {
    if (value == null) {
      accounts.remove(user);
    } else {
      accounts[user] = value;
    }
  }

  void _check() {
    if (offline) throw StateError('no connection');
  }
}

/// Each device has its own auth session against the shared [FakeServer].
class FakeAuth implements AuthGateway {
  FakeAuth(this.server);

  final FakeServer server;
  final _changes = StreamController<String?>.broadcast();
  String? _email;

  @override
  String? get userId => _email == null ? null : 'user-$_email';

  @override
  String? get email => _email;

  @override
  Stream<String?> get userChanges => _changes.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    server._check();
    if (server.passwords[email] != password) {
      throw const SignInException(AuthFailure.invalidCredentials);
    }
    _email = email;
    _changes.add(userId);
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    server._check();
    if (server.passwords.containsKey(email)) {
      throw const SignInException(AuthFailure.emailTaken);
    }
    server.passwords[email] = password;
    if (server.requireEmailConfirmation) return false;
    await signIn(email: email, password: password);
    return true;
  }

  @override
  Future<void> signOut() async {
    _email = null;
    _changes.add(null);
  }

  final resetRequests = <String>[];
  final _recoveries = StreamController<void>.broadcast();

  @override
  Future<void> sendPasswordReset(String email) async {
    server._check();
    resetRequests.add(email);
  }

  /// What opening the emailed link does: signed in, asked for a password.
  Future<void> openResetLink(String email) async {
    _email = email;
    _changes.add(userId);
    _recoveries.add(null);
  }

  @override
  Stream<void> get passwordRecoveries => _recoveries.stream;

  @override
  bool openedFromResetLink = false;

  @override
  Future<void> updatePassword(String newPassword) async {
    server._check();
    if (server.passwords[_email!] == newPassword) {
      throw const SignInException(AuthFailure.samePassword);
    }
    server.passwords[_email!] = newPassword;
  }
}

class FakeRemote implements RemotePlannerStore {
  /// Without [auth], acts for [FakeServer.primaryUser].
  FakeRemote(this.server, [this.auth]);

  final FakeServer server;
  final FakeAuth? auth;

  String get _user => auth?.userId ?? FakeServer.primaryUser;

  @override
  Future<String?> fetchMarker() async {
    server._check();
    return server.markerOf(_user);
  }

  @override
  Future<RemoteState> fetch() async {
    server._check();
    final data = server.accounts[_user];
    return RemoteState(
      data: data == null
          ? PlannerData()
          // Round-trip through JSON, like a real server would.
          : decodePlannerData(encodePlannerData(data)),
      marker: server.markerOf(_user),
    );
  }

  @override
  Future<String> push(PlannerData data) async {
    server._check();
    final existing = server.accounts[_user];
    // Progress is append-only on the real server too: keep anything the
    // server already had.
    final keys = {for (final e in data.entries) e.idempotencyKey};
    server._put(
      _user,
      decodePlannerData(
        encodePlannerData(
          PlannerData(
            categories: data.categories,
            goals: data.goals,
            periods: data.periods,
            allocations: data.allocations,
            entries: [
              ...data.entries,
              if (existing != null)
                for (final e in existing.entries)
                  if (!keys.contains(e.idempotencyKey)) e,
            ],
            snapshots: data.snapshots,
            reviewedPeriodIds: data.reviewedPeriodIds,
            settings: data.settings,
            activeFocus: data.activeFocus,
          ),
        ),
      ),
    );
    server._versions[_user] = (server._versions[_user] ?? 0) + 1;
    return server.markerOf(_user)!;
  }

  @override
  Future<void> deleteAccount() async {
    server._check();
    server._put(_user, null);
    server.passwords.remove(auth?.email ?? 'harun@example.test');
  }
}
