import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/planning/data/planner_storage.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';
import 'package:rota/features/sync/presentation/sync_service.dart';

import '../../../helpers/builders.dart';
import '../../../helpers/fake_backend.dart';
import '../../../helpers/fixed_clock.dart';

const _email = 'harun@example.test';
const _password = 'correct-horse';

/// A phone or a browser: its own local data, its own session.
class _Device {
  _Device(FakeServer server, {this.stateStorage})
    : controller = PlannerController(clock: FixedClock(monday)),
      auth = FakeAuth(server) {
    sync = SyncService(
      controller: controller,
      auth: auth,
      remote: FakeRemote(server),
      stateStorage: stateStorage ?? InMemoryPlannerStorage(),
      debounce: const Duration(hours: 1), // tests call sync() themselves
    );
  }

  final PlannerController controller;
  final FakeAuth auth;
  final InMemoryPlannerStorage? stateStorage;
  late final SyncService sync;

  Future<void> start() async {
    await controller.load();
    await sync.start();
  }

  Future<void> signIn() async {
    await auth.signIn(email: _email, password: _password);
    await sync.sync();
  }

  String addGoal(String title) {
    final category = controller.addCategory('Proje');
    return controller
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: title,
          targetMinutes: 600,
          dailyPlan: {monday: 120},
        )
        .id;
  }

  List<String> get titles => [
    for (final v in controller.activeGoals()) v.goal.title,
  ];
}

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer()..passwords[_email] = _password;
  });

  test('first sign-in uploads what this device already has', () async {
    final phone = _Device(server);
    await phone.start();
    phone.controller.addProgress(phone.addGoal('Rota MVP'), 90);
    expect(phone.sync.status, SyncStatus.signedOut);

    await phone.signIn();

    expect(phone.sync.status, SyncStatus.synced);
    expect(server.data!.goals.single.title, 'Rota MVP');
    expect(server.data!.entries.single.valueDelta, 90);
  });

  test('a second device downloads the account', () async {
    final phone = _Device(server);
    await phone.start();
    phone.controller.addProgress(phone.addGoal('Rota MVP'), 90);
    await phone.signIn();

    final web = _Device(server);
    await web.start();
    await web.signIn();

    expect(web.titles, ['Rota MVP']);
    expect(web.controller.activeGoals().single.todayDone, 90);
  });

  test('a change on one device reaches the other', () async {
    final phone = _Device(server);
    await phone.start();
    final periodId = phone.addGoal('Rota MVP');
    await phone.signIn();
    final web = _Device(server);
    await web.start();
    await web.signIn();

    phone.controller.addProgress(periodId, 45);
    await phone.sync.sync();
    await web.sync.sync();

    expect(web.controller.activeGoals().single.todayDone, 45);
  });

  test('both changed: the user chooses, and no work is lost', () async {
    final phone = _Device(server);
    await phone.start();
    final periodId = phone.addGoal('Rota MVP');
    await phone.signIn();
    final web = _Device(server);
    await web.start();
    await web.signIn();

    phone.controller.addProgress(periodId, 30);
    await phone.sync.sync();
    web.controller.addProgress(periodId, 60);
    web.controller.updateTarget(periodId, 480);
    await web.sync.sync();

    expect(web.sync.status, SyncStatus.conflict);

    // Keep the phone's plan (600), but the web's 60 min must survive.
    final unmatched = await web.sync.chooseSide(keepThisDevice: false);
    final view = web.controller.activeGoals().single;
    expect(unmatched, 0);
    expect(view.period.targetValue, 600);
    expect(view.todayDone, 90);

    await phone.sync.sync();
    expect(phone.controller.activeGoals().single.todayDone, 90);
  });

  test('offline: changes wait on the device and go out later', () async {
    final phone = _Device(server);
    await phone.start();
    final periodId = phone.addGoal('Rota MVP');
    await phone.signIn();

    server.offline = true;
    phone.controller.addProgress(periodId, 25);
    await phone.sync.sync();
    expect(phone.sync.status, SyncStatus.offline);
    expect(phone.sync.hasUnsentChanges, isTrue);

    server.offline = false;
    await phone.sync.sync();
    expect(phone.sync.status, SyncStatus.synced);
    expect(server.data!.entries.single.valueDelta, 25);
  });

  test('unsent changes survive an app restart', () async {
    final stateStorage = InMemoryPlannerStorage();
    final phone = _Device(server, stateStorage: stateStorage);
    await phone.start();
    phone.addGoal('Rota MVP');
    await phone.signIn();

    server.offline = true;
    phone.addGoal('PTE');
    await phone.sync.sync();

    final reopened = _Device(server, stateStorage: stateStorage);
    await reopened.start();
    expect(reopened.sync.hasUnsentChanges, isTrue);
  });

  test('deleting the account removes it everywhere', () async {
    final phone = _Device(server);
    await phone.start();
    phone.addGoal('Rota MVP');
    await phone.signIn();

    await phone.sync.deleteAccount();

    expect(server.data, isNull);
    expect(phone.titles, isEmpty);
    expect(phone.sync.status, SyncStatus.signedOut);
  });

  test('a build without a server stays local only', () async {
    final controller = PlannerController(clock: FixedClock(monday));
    final sync = SyncService.disabled(controller: controller);
    await sync.start();
    await sync.sync();
    expect(sync.status, SyncStatus.disabled);
  });
}
