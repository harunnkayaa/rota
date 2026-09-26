import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/time/clock.dart';
import 'features/planning/presentation/planner_controller.dart';

void main() {
  runApp(RotaApp(controller: PlannerController(clock: const SystemClock())));
}
