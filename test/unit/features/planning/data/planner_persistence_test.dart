import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/planning/data/planner_storage.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fixed_clock.dart';

/// Storage whose writes fail until [failWrites] is switched off.
class _FlakyStorage extends InMemoryPlannerStorage {
  bool failWrites = true;

  @override
  Future<void> write(String data) async {
    if (failWrites) throw StateError('disk full');
    await super.write(data);
  }
}

void main() {
  PlannerController controllerOn(PlannerStorage storage) =>
      PlannerController(clock: FixedClock(monday), storage: storage);

  String createGoal(PlannerController c) {
    final category = c.addCategory('Proje');
    return c
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Proje',
          targetMinutes: 600,
          dailyPlan: {monday: 120},
        )
        .id;
  }

  test('goals and progress survive a restart', () async {
    final storage = InMemoryPlannerStorage();
    final first = controllerOn(storage);
    await first.load();
    final periodId = createGoal(first);
    first.addProgress(periodId, 90);
    await first.flush();

    final second = controllerOn(storage);
    await second.load();

    expect(second.loadStatus, LoadStatus.ready);
    final view = second.activeGoals().single;
    expect(view.todayDone, 90);
    expect(view.periodDone, 90);
    expect(view.todayAllocated, 120);
  });

  test('an empty device starts with no goals', () async {
    final controller = controllerOn(InMemoryPlannerStorage());
    await controller.load();
    expect(controller.loadStatus, LoadStatus.ready);
    expect(controller.activeGoals(), isEmpty);
  });

  test('unreadable data is reported and never overwritten', () async {
    const corrupt = '{not valid json';
    final storage = InMemoryPlannerStorage(corrupt);
    final controller = controllerOn(storage);
    await controller.load();

    expect(controller.loadStatus, LoadStatus.failed);

    controller.addCategory('Deneme');
    await controller.flush();
    expect(storage.data, corrupt);
  });

  test('a failed save is visible and can be retried', () async {
    final storage = _FlakyStorage();
    final controller = controllerOn(storage);
    await controller.load();

    createGoal(controller);
    await controller.flush();
    expect(controller.saveStatus, SaveStatus.failed);
    expect(storage.data, isNull);

    storage.failWrites = false;
    controller.retrySave();
    await controller.flush();
    expect(controller.saveStatus, SaveStatus.saved);
    expect(storage.data, contains('Proje'));
  });

  test('writes happen in order: the last change wins', () async {
    final storage = InMemoryPlannerStorage();
    final controller = controllerOn(storage);
    await controller.load();
    final periodId = createGoal(controller);
    for (var i = 0; i < 5; i++) {
      controller.addProgress(periodId, 10);
    }
    await controller.flush();

    final reloaded = controllerOn(storage);
    await reloaded.load();
    expect(reloaded.activeGoals().single.periodDone, 50);
  });
}
