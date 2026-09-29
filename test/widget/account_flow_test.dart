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
  bool signedIn = false,
  void Function(PlannerController)? before,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final s = server ?? FakeServer();
  final controller = PlannerController(clock: FixedClock(monday));
  final auth = FakeAuth(s);
  final sync = SyncService(
    controller: controller,
    auth: auth,
    remote: FakeRemote(s),
    stateStorage: InMemoryPlannerStorage(),
    debounce: const Duration(hours: 1),
  );
  await controller.load();
  before?.call(controller);
  if (signedIn) await auth.signIn(email: _email, password: _password);
  await sync.start();
  await tester.pumpWidget(RotaApp(controller: controller, syncService: sync));
  await tester.pumpAndSettle();
  return (controller, sync, s);
}

Future<void> _fill(WidgetTester tester, {String password = _password}) async {
  await tester.enterText(find.widgetWithText(TextField, 'E-posta'), _email);
  await tester.enterText(
    find.widgetWithText(TextField, 'Şifre (en az 8 karakter)'),
    password,
  );
}

Future<void> _submit(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

final _signInScreen = find.text('Hesabın yok mu? Hesap oluştur');
final _home = find.text('Bugün');

void main() {
  testWidgets('signed out: the first screen is sign-in, not the app', (
    tester,
  ) async {
    final (_, sync, _) = await _pump(tester);
    expect(_signInScreen, findsOneWidget);
    expect(_home, findsNothing);
    sync.dispose();
  });

  testWidgets('a kept session opens the app directly', (tester) async {
    final server = FakeServer()..passwords[_email] = _password;
    final (_, sync, _) = await _pump(tester, server: server, signedIn: true);
    expect(_signInScreen, findsNothing);
    expect(_home, findsWidgets);
    sync.dispose();
  });

  testWidgets('create an account, land in the app, see it synced', (
    tester,
  ) async {
    final (_, sync, server) = await _pump(tester);

    await tester.tap(_signInScreen);
    await tester.pumpAndSettle();
    await _fill(tester);
    await _submit(tester, 'Hesap oluştur');
    await tester.runAsync(sync.sync);
    await tester.pumpAndSettle();

    expect(_home, findsWidgets);
    expect(server.passwords, contains(_email));
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('$_email olarak giriş yapıldı'), findsOneWidget);
    expect(find.textContaining('Eşitlendi'), findsOneWidget);
    sync.dispose();
  });

  testWidgets('sign-up that needs email confirmation says so', (tester) async {
    final server = FakeServer()..requireEmailConfirmation = true;
    final (_, sync, _) = await _pump(tester, server: server);

    await tester.tap(_signInScreen);
    await tester.pumpAndSettle();
    await _fill(tester);
    await _submit(tester, 'Hesap oluştur');

    expect(find.textContaining('onay bağlantısı gönderdik'), findsOneWidget);
    // Back in sign-in mode, ready for after the email is confirmed.
    expect(find.widgetWithText(FilledButton, 'Giriş yap'), findsOneWidget);
    expect(_home, findsNothing);
    sync.dispose();
  });

  testWidgets('sign-up with a taken email says so and switches to sign-in', (
    tester,
  ) async {
    final server = FakeServer()..passwords[_email] = _password;
    final (_, sync, _) = await _pump(tester, server: server);

    await tester.tap(_signInScreen);
    await tester.pumpAndSettle();
    await _fill(tester);
    await _submit(tester, 'Hesap oluştur');

    expect(
      find.text('Bu e-postayla zaten bir hesap var; giriş yapmayı dene.'),
      findsOneWidget,
    );
    expect(find.textContaining('onay bağlantısı'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Giriş yap'), findsOneWidget);
    sync.dispose();
  });

  testWidgets('forgot password: link by email, then a new password', (
    tester,
  ) async {
    final server = FakeServer()..passwords[_email] = 'old-password';
    final (_, sync, _) = await _pump(tester, server: server);
    final auth = sync.auth! as FakeAuth;

    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), _email);
    await tester.tap(find.text('Şifremi unuttum'));
    await tester.pumpAndSettle();
    // The email typed on the sign-in screen is carried over.
    await tester.tap(find.text('Bağlantı gönder'));
    await tester.pumpAndSettle();
    expect(auth.resetRequests, [_email]);
    expect(
      find.textContaining('adresine bir bağlantı gönderdik'),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();

    // The link opens the app signed in, asking for a new password first.
    await auth.openResetLink(_email);
    await tester.pumpAndSettle();
    expect(find.text('Yeni şifreni belirle'), findsOneWidget);
    expect(_home, findsNothing);

    await tester.enterText(find.byType(TextField), 'old-password');
    await tester.tap(find.text('Şifreyi kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni şifre eskisiyle aynı olamaz.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'brand-new-pass');
    await tester.tap(find.text('Şifreyi kaydet'));
    await tester.pumpAndSettle();
    await tester.runAsync(sync.sync);
    await tester.pumpAndSettle();

    expect(server.passwords[_email], 'brand-new-pass');
    expect(_home, findsWidgets);
    sync.dispose();
  });

  testWidgets('wrong password is explained, no stack trace', (tester) async {
    final server = FakeServer()..passwords[_email] = 'something-else';
    final (_, sync, _) = await _pump(tester, server: server);

    await _fill(tester);
    await _submit(tester, 'Giriş yap');

    expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);
    expect(_home, findsNothing);
    sync.dispose();
  });

  testWidgets('input is checked before anything is sent', (tester) async {
    final (_, sync, server) = await _pump(tester);

    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'harun');
    await _submit(tester, 'Giriş yap');
    expect(find.text('Geçerli bir e-posta adresi gir.'), findsOneWidget);

    await _fill(tester, password: 'short');
    await _submit(tester, 'Giriş yap');
    expect(find.text('Şifre en az 8 karakter olmalı.'), findsOneWidget);
    expect(server.passwords, isEmpty);
    sync.dispose();
  });

  testWidgets('signing out returns to sign-in; the data stays', (tester) async {
    final server = FakeServer()..passwords[_email] = _password;
    final (controller, sync, _) = await _pump(
      tester,
      server: server,
      signedIn: true,
    );
    final category = controller.addCategory('Proje');
    controller.createWeeklyDurationGoal(
      categoryId: category.id,
      title: 'Proje',
      targetMinutes: 600,
      dailyPlan: {monday: 120},
    );

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Çıkış yap'));
    await tester.pumpAndSettle();

    expect(_signInScreen, findsOneWidget);
    expect(controller.activeGoals(), hasLength(1));
    sync.dispose();
  });

  testWidgets('signing out with unsent changes asks first', (tester) async {
    final server = FakeServer()..passwords[_email] = _password;
    final (controller, sync, _) = await _pump(
      tester,
      server: server,
      signedIn: true,
    );
    server.offline = true;
    final category = controller.addCategory('Proje');
    controller.createWeeklyDurationGoal(
      categoryId: category.id,
      title: 'Proje',
      targetMinutes: 600,
      dailyPlan: {monday: 120},
    );

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Çıkış yap'));
    expect(find.text('Gönderilmemiş değişiklikler var'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(sync.isSignedIn, isTrue);
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

    final (_, sync, _) = await _pump(
      tester,
      server: server,
      before: (controller) {
        final category = controller.addCategory('Proje');
        controller.createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Proje',
          targetMinutes: 600,
          dailyPlan: {monday: 120},
        );
      },
    );

    await _fill(tester);
    await _submit(tester, 'Giriş yap');
    await tester.runAsync(sync.sync);
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
