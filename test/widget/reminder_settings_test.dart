import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/builders.dart';
import '../helpers/fake_scheduler.dart';
import '../helpers/fixed_clock.dart';

Future<void> _openReminders(WidgetTester tester) async {
  await tester.tap(find.text('Ayarlar'));
  await tester.pumpAndSettle();
  await scrollTo(tester, find.text('Hatırlatmaları aç'));
}

void main() {
  testWidgets('permission is asked only when turning reminders on', (
    tester,
  ) async {
    final scheduler = FakeReminderScheduler();
    final controller = await pumpRota(
      tester,
      today: monday,
      reminderScheduler: scheduler,
    );
    expect(scheduler.permissionRequests, 0, reason: 'no prompt at launch');

    await _openReminders(tester);
    await tester.tap(find.text('Hatırlatmaları aç'));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    expect(controller.settings.reminders.enabled, isTrue);
    await scrollTo(tester, find.text('Hatırlatma saati'));
    expect(find.text('20:00'), findsOneWidget);
  });

  testWidgets('a denied permission keeps reminders off and says how to fix', (
    tester,
  ) async {
    final scheduler = FakeReminderScheduler(grant: false);
    final controller = await pumpRota(
      tester,
      today: monday,
      reminderScheduler: scheduler,
    );

    await _openReminders(tester);
    await tester.tap(find.text('Hatırlatmaları aç'));
    await tester.pumpAndSettle();

    expect(controller.settings.reminders.enabled, isFalse);
    expect(find.textContaining('Bildirim izni verilmedi'), findsOneWidget);
  });

  testWidgets('web build explains that reminders run on iPhone', (
    tester,
  ) async {
    await pumpRota(tester, today: monday);
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.textContaining('web sürümü bildirim göndermez'),
    );
    expect(find.byType(Switch), findsNothing);
  });
}
