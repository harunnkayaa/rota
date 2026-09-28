import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota/app/app.dart';
import 'package:rota/core/time/clock.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/features/planning/data/planner_storage.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';
import 'package:rota/features/reminders/data/reminder_scheduler.dart';

/// A clock that only moves when a test moves it. Starts on [day] at noon
/// UTC; setting [day] jumps to noon of that day, [advance] moves forward.
class FixedClock implements Clock {
  FixedClock(LocalDate day) : _now = _noon(day);

  DateTime _now;

  LocalDate get day => LocalDate.fromDateTime(_now);
  set day(LocalDate value) => _now = _noon(value);

  void advance(Duration duration) => _now = _now.add(duration);

  @override
  DateTime nowUtc() => _now;

  @override
  LocalDate today() => day;

  /// Tests treat the fixed UTC time as the local time of day.
  @override
  int minuteOfDay() => _now.hour * Duration.minutesPerHour + _now.minute;

  static DateTime _noon(LocalDate d) =>
      DateTime.utc(d.year, d.month, d.day, 12);
}

/// Pumps the whole app on a phone-sized screen.
///
/// Pass [controller] to prepare data (and move its clock) before the app
/// is shown; otherwise a fresh one for [today] is created and loaded.
Future<PlannerController> pumpRota(
  WidgetTester tester, {
  LocalDate? today,
  PlannerController? controller,
  Size size = const Size(390, 844),
  PlannerStorage? storage,
  ReminderScheduler reminderScheduler = const NoopReminderScheduler(),
}) async {
  assert(
    (today == null) != (controller == null),
    'Pass either today or controller',
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final c =
      controller ??
      PlannerController(clock: FixedClock(today!), storage: storage);
  if (controller == null) await c.load();
  await tester.pumpWidget(
    RotaApp(controller: c, reminderScheduler: reminderScheduler),
  );
  await tester.pumpAndSettle();
  return c;
}

/// Taps [finder] after scrolling it into view.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls the page's main list until [finder] is built and visible, then
/// taps it. Long forms build lazily, so plain finders miss what is below.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Finds a [Semantics] widget by its label, whether or not it is currently
/// on screen (screen-reader nodes only exist for visible widgets).
Finder semanticsLabel(RegExp pattern) => find.byWidgetPredicate(
  (w) => w is Semantics && pattern.hasMatch(w.properties.label ?? ''),
  description: 'Semantics label $pattern',
);
