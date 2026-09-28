import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/localization/app_localizations.dart';
import 'core/config/backend_config.dart';
import 'core/time/clock.dart';
import 'features/planning/data/planner_storage.dart';
import 'features/planning/presentation/planner_controller.dart';
import 'features/reminders/data/reminder_scheduler.dart';
import 'features/reminders/presentation/reminder_sync.dart';
import 'features/sync/data/auth_gateway.dart';
import 'features/sync/data/remote_planner_store.dart';
import 'features/sync/presentation/sync_service.dart';

Future<void> main() async {
  // Plugins (device storage) need the Flutter engine before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PlannerController(
    clock: const SystemClock(),
    storage: SharedPreferencesPlannerStorage(),
  );

  // Account and sync only when this build knows where the server is.
  final SyncService sync;
  if (BackendConfig.isConfigured) {
    await Supabase.initialize(
      url: BackendConfig.url,
      publishableKey: BackendConfig.publishableKey,
    );
    final client = Supabase.instance.client;
    sync = SyncService(
      controller: controller,
      auth: SupabaseAuthGateway(client.auth),
      remote: SupabaseRemotePlannerStore(client),
      stateStorage: SharedPreferencesPlannerStorage(
        key: SharedPreferencesPlannerStorage.syncStateKey,
      ),
    );
  } else {
    sync = SyncService.disabled(controller: controller);
  }

  // Scheduled reminders are an iPhone feature; the web build skips them.
  final ReminderScheduler scheduler = kIsWeb
      ? const NoopReminderScheduler()
      : LocalReminderScheduler();
  ReminderSync(
    controller: controller,
    scheduler: scheduler,
    texts: lookupAppLocalizations(const Locale('tr')),
  ).start();

  // The app shows a loading screen until the local data is read; sync
  // starts after that, so it always compares against the real local copy.
  unawaited(controller.load().then((_) => sync.start()));
  runApp(
    RotaApp(
      controller: controller,
      reminderScheduler: scheduler,
      syncService: sync,
    ),
  );
}
