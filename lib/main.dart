import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/localization/app_localizations.dart';
import 'core/time/clock.dart';
import 'features/planning/data/planner_storage.dart';
import 'features/planning/presentation/planner_controller.dart';
import 'features/reminders/data/reminder_scheduler.dart';
import 'features/reminders/presentation/reminder_sync.dart';

void main() {
  // Plugins (device storage) need the Flutter engine before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PlannerController(
    clock: const SystemClock(),
    storage: SharedPreferencesPlannerStorage(),
  );
  // Scheduled reminders are an iPhone feature; the web build skips them.
  final ReminderScheduler scheduler = kIsWeb
      ? const NoopReminderScheduler()
      : LocalReminderScheduler();
  ReminderSync(
    controller: controller,
    scheduler: scheduler,
    texts: lookupAppLocalizations(const Locale('tr')),
  ).start();
  // The app shows a loading screen until this finishes.
  unawaited(controller.load());
  runApp(RotaApp(controller: controller, reminderScheduler: scheduler));
}
