// End-to-end sync against the real local Supabase (docker).
//
// Needs `supabase start` and env/local.json; skipped otherwise, so the
// normal test run never depends on a server.
//
//   supabase start
//   flutter test test/integration

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/planning/data/planner_storage.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';
import 'package:rota/features/sync/data/auth_gateway.dart';
import 'package:rota/features/sync/data/remote_planner_store.dart';
import 'package:rota/features/sync/presentation/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/builders.dart';
import '../helpers/fixed_clock.dart';

Map<String, String>? _config() {
  final file = File('env/local.json');
  if (!file.existsSync()) return null;
  return (jsonDecode(file.readAsStringSync()) as Map<String, Object?>).map(
    (k, v) => MapEntry(k, v! as String),
  );
}

Future<bool> _serverUp(String url) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    final request = await client.getUrl(Uri.parse('$url/auth/v1/health'));
    final response = await request.close();
    client.close();
    return response.statusCode < 500;
  } on Object {
    return false;
  }
}

class _Device {
  _Device(Map<String, String> config)
    : client = SupabaseClient(
        config['SUPABASE_URL']!,
        config['SUPABASE_PUBLISHABLE_KEY']!,
        // The app (supabase_flutter) keeps sessions in device storage; this
        // bare test client has none, so it uses the storage-free flow.
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      ),
      controller = PlannerController(clock: FixedClock(monday)) {
    sync = SyncService(
      controller: controller,
      auth: SupabaseAuthGateway(client.auth),
      remote: SupabaseRemotePlannerStore(client),
      stateStorage: InMemoryPlannerStorage(),
      debounce: const Duration(hours: 1),
    );
  }

  final SupabaseClient client;
  final PlannerController controller;
  late final SyncService sync;

  Future<void> start() async {
    await controller.load();
    await sync.start();
  }

  Future<void> dispose() async {
    sync.dispose();
    await client.dispose();
  }
}

void main() {
  final config = _config();

  group('local Supabase', () {
    late bool up;

    setUpAll(() async {
      up = config != null && await _serverUp(config['SUPABASE_URL']!);
    });

    test('two devices share one account; others see nothing', () async {
      if (!up) {
        markTestSkipped('local Supabase is not running');
        return;
      }
      final email = 'rota-${Random().nextInt(1 << 32)}@example.test';
      const password = 'integration-test-1';

      // Phone: creates a goal, logs work, signs up → uploads.
      final phone = _Device(config!);
      await phone.start();
      final category = phone.controller.addCategory('Proje');
      final periodId = phone.controller
          .createWeeklyDurationGoal(
            categoryId: category.id,
            title: 'Rota MVP',
            targetMinutes: 600,
            dailyPlan: {monday: 120, wednesday: 90},
          )
          .id;
      phone.controller.addProgress(periodId, 45);
      await phone.sync.signUp(email: email, password: password);
      await phone.sync.sync();
      expect(phone.sync.status, SyncStatus.synced);

      // Browser: signs in → downloads.
      final web = _Device(config);
      await web.start();
      await web.sync.signIn(email: email, password: password);
      await web.sync.sync();
      final view = web.controller.activeGoals().single;
      expect(view.goal.title, 'Rota MVP');
      expect(view.todayDone, 45);
      expect(view.todayAllocated, 120);

      // Phone logs more, removes Wednesday's plan; the browser follows.
      phone.controller
        ..addProgress(periodId, 30)
        ..updatePlan(periodId, {wednesday: 0});
      await phone.sync.sync();
      await web.sync.sync();
      final after = web.controller.activeGoals().single;
      expect(after.todayDone, 75);
      expect(after.days.firstWhere((d) => d.date == wednesday).allocated, 0);

      // Someone else: RLS shows them nothing.
      final stranger = _Device(config);
      await stranger.sync.signUp(
        email: 'other-${Random().nextInt(1 << 32)}@example.test',
        password: password,
      );
      final seen = await SupabaseRemotePlannerStore(stranger.client).fetch();
      expect(seen.data.goals, isEmpty);
      expect(seen.data.entries, isEmpty);

      // Deleting the account removes it from the server.
      await phone.sync.deleteAccount();
      expect(
        () => web.sync.signIn(email: email, password: password),
        throwsA(isA<SignInException>()),
      );

      await phone.dispose();
      await web.dispose();
      await stranger.dispose();
    });

    test('"delete all data" while signed in empties the account too', () async {
      if (!up) {
        markTestSkipped('local Supabase is not running');
        return;
      }
      final email = 'rota-${Random().nextInt(1 << 32)}@example.test';
      const password = 'integration-test-1';
      final phone = _Device(config!);
      await phone.start();
      final category = phone.controller.addCategory('Proje');
      final periodId = phone.controller
          .createWeeklyDurationGoal(
            categoryId: category.id,
            title: 'Rota MVP',
            targetMinutes: 600,
            dailyPlan: {monday: 120},
          )
          .id;
      phone.controller.addProgress(periodId, 45);
      await phone.sync.signUp(email: email, password: password);
      await phone.sync.sync();

      phone.controller.deleteAllData();
      await phone.sync.sync();
      expect(phone.sync.status, SyncStatus.synced);

      final server = await SupabaseRemotePlannerStore(phone.client).fetch();
      expect(server.data.goals, isEmpty);
      expect(server.data.periods, isEmpty);
      expect(server.data.entries, isEmpty);

      await phone.sync.deleteAccount();
      await phone.dispose();
    });
  });
}
