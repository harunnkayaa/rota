import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota/app/app.dart';
import 'package:rota/features/planning/data/planner_storage.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';
import 'package:rota/features/sync/presentation/sync_service.dart';

import '../helpers/builders.dart';
import '../helpers/fake_backend.dart';
import '../helpers/fixed_clock.dart';

const _email = 'harun@example.test';
const _password = 'correct-horse';

Future<(PlannerController, SyncService, FakeServer)> _pump(
  WidgetTester tester, {
  FakeServer? server,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final s = server ?? FakeServer();
  final controller = PlannerController(clock: FixedClock(monday));
  final sync = SyncService(
    controller: controller,
    auth: FakeAuth(s),
    remote: FakeRemote(s),
    stateStorage: InMemoryPlannerStorage(),
    debounce: const Duration(hours: 1),
  );
  await controller.load();
  await sync.start();
  await tester.pumpWidget(RotaApp(controller: controller, syncService: sync));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ayarlar'));
  await tester.pumpAndSettle();
  return (controller, sync, s);
}

Future<void> _fillAndTap(WidgetTester tester, String button) async {
  await tester.enterText(find.widgetWithText(TextField, 'E-posta'), _email);
  await tester.enterText(
    find.widgetWithText(TextField, 'Şifre (en az 8 karakter)'),
    _password,
  );
  await tester.tap(find.text(button));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('create an account from Settings and see it synced', (
    tester,
  ) async {
    final (_, sync, server) = await _pump(tester);
    expect(find.text('Hesap ve eşitleme'), findsOneWidget);

    await _fillAndTap(tester, 'Hesap oluştur');
    await tester.runAsync(sync.sync);
    await tester.pumpAndSettle();

    expect(find.text('$_email olarak giriş yapıldı'), findsOneWidget);
    expect(find.textContaining('Eşitlendi'), findsOneWidget);
    expect(server.passwords, contains(_email));
    sync.dispose();
  });

  testWidgets('wrong password is explained, no stack trace', (tester) async {
    final server = FakeServer()..passwords[_email] = 'something-else';
    final (_, sync, _) = await _pump(tester, server: server);

    await _fillAndTap(tester, 'Giriş yap');

    expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);
    sync.dispose();
  });

  testWidgets('input is checked before anything is sent', (tester) async {
    final (_, sync, server) = await _pump(tester);

    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'harun');
    await tester.tap(find.text('Giriş yap'));
    await tester.pumpAndSettle();
    expect(find.text('Geçerli bir e-posta adresi gir.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), _email);
    await tester.enterText(
      find.widgetWithText(TextField, 'Şifre (en az 8 karakter)'),
      'short',
    );
    await tester.tap(find.text('Giriş yap'));
    await tester.pumpAndSettle();
    expect(find.text('Şifre en az 8 karakter olmalı.'), findsOneWidget);
    expect(server.passwords, isEmpty);
    sync.dispose();
  });

  testWidgets('a conflict shows on Today and is resolved by choice', (
    tester,
  ) async {
    // The account already has a different plan than this device.
    final server = FakeServer()..passwords[_email] = _password;
    final other = PlannerController(clock: FixedClock(monday));
    final otherCategory = other.addCategory('Kitap');
    other.createWeeklyDurationGoal(
      categoryId: otherCategory.id,
      title: 'Kitap',
      targetMinutes: 300,
      dailyPlan: {monday: 60},
    );
    await FakeRemote(server).push(other.snapshotData());

    final (controller, sync, _) = await _pump(tester, server: server);
    final category = controller.addCategory('Proje');
    controller.createWeeklyDurationGoal(
      categoryId: category.id,
      title: 'Proje',
      targetMinutes: 600,
      dailyPlan: {monday: 120},
    );

    await _fillAndTap(tester, 'Giriş yap');
    await tester.runAsync(sync.sync);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bugün'));
    await tester.pumpAndSettle();
    expect(
      find.text('Eşitleme çakışması: hangi sürümün kullanılacağını seç.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Seç'));
    await tester.pumpAndSettle();
    expect(find.text('Hangi sürüm kullanılsın?'), findsOneWidget);
    await tester.tap(find.text('Hesaptakini kullan'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Kitap'), findsWidgets);
    expect(find.text('Proje'), findsNothing);
    sync.dispose();
  });
}
