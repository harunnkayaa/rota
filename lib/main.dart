import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/time/clock.dart';
import 'features/planning/data/planner_storage.dart';
import 'features/planning/presentation/planner_controller.dart';

void main() {
  // Plugins (device storage) need the Flutter engine before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PlannerController(
    clock: const SystemClock(),
    storage: SharedPreferencesPlannerStorage(),
  );
  // The app shows a loading screen until this finishes.
  unawaited(controller.load());
  runApp(RotaApp(controller: controller));
}
