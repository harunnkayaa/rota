import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota/app/app.dart';
import 'package:rota/core/time/clock.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';

/// A clock frozen on [day] at noon UTC.
class FixedClock implements Clock {
  FixedClock(this.day);

  LocalDate day;

  @override
  DateTime nowUtc() => DateTime.utc(day.year, day.month, day.day, 12);

  @override
  LocalDate today() => day;
}

/// Pumps the whole app on a phone-sized screen.
Future<PlannerController> pumpRota(
  WidgetTester tester, {
  required LocalDate today,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = PlannerController(clock: FixedClock(today));
  await tester.pumpWidget(RotaApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}
