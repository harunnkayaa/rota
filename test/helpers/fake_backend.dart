import 'dart:async';

import 'package:rota/features/planning/data/planner_data.dart';
import 'package:rota/features/planning/data/planner_json.dart';
import 'package:rota/features/sync/data/auth_gateway.dart';
import 'package:rota/features/sync/data/remote_planner_store.dart';

/// One account on a pretend server, shared by several pretend devices.
class FakeServer {
  PlannerData? data;
  int _version = 0;
  bool offline = false;
  final passwords = <String, String>{};

  String? get marker => data == null ? null : 'v$_version';

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
  Future<void> signUp({required String email, required String password}) async {
    server._check();
    if (server.passwords.containsKey(email)) {
      throw const SignInException(AuthFailure.emailTaken);
    }
    server.passwords[email] = password;
    await signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    _email = null;
    _changes.add(null);
  }
}

class FakeRemote implements RemotePlannerStore {
  FakeRemote(this.server);

  final FakeServer server;

  @override
  Future<RemoteState> fetch() async {
    server._check();
    return RemoteState(
      data: server.data == null
          ? PlannerData()
          // Round-trip through JSON, like a real server would.
          : decodePlannerData(encodePlannerData(server.data!)),
      marker: server.marker,
    );
  }

  @override
  Future<String> push(PlannerData data) async {
    server._check();
    final existing = server.data;
    // Progress is append-only on the real server too: keep anything the
    // server already had.
    final keys = {for (final e in data.entries) e.idempotencyKey};
    server.data = decodePlannerData(
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
    );
    server._version++;
    return server.marker!;
  }

  @override
  Future<void> deleteAccount() async {
    server._check();
    server.data = null;
    server.passwords.clear();
  }
}
