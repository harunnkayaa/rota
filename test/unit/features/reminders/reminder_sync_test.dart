import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota/app/localization/app_localizations.dart';
import 'package:rota/features/categories/domain/category.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';
import 'package:rota/features/reminders/presentation/reminder_sync.dart';

import '../../../helpers/builders.dart';
import '../../../helpers/fake_scheduler.dart';
import '../../../helpers/fixed_clock.dart';

void main() {
  late FixedClock clock;
  late PlannerController controller;
  late FakeReminderScheduler scheduler;
  late ReminderSync sync;

  setUp(() {
    clock = FixedClock(monday); // 12:00
    controller = PlannerController(clock: clock);
    scheduler = FakeReminderScheduler();
    sync = ReminderSync(
      controller: controller,
      scheduler: scheduler,
      texts: lookupAppLocalizations(const Locale('tr')),
    );
    controller.updateSettings(
      controller.settings.copyWith(
        reminders: controller.settings.reminders.copyWith(enabled: true),
      ),
    );
  });

  String createProject({required String title}) {
    final category = controller.addCategory(title);
    final periodId = controller
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: title,
          targetMinutes: 600,
          dailyPlan: {monday: 120},
        )
        .id;
    return periodId;
  }

  test('reminds about what is still left today, in plain Turkish', () async {
    createProject(title: 'Rota MVP');
    await sync.sync();

    final n = scheduler.pending.single;
    expect(n.title, 'Rota');
    expect(n.body, 'Rota MVP: bugün 2 sa kaldı.');
    final local = n.atUtc.toLocal();
    expect([local.hour, local.minute], [20, 0]);
  });

  test('logging progress updates the text to the new remaining time', () async {
    final periodId = createProject(title: 'Rota MVP');
    await sync.sync();
    controller.addProgress(periodId, 90);
    await sync.sync();

    expect(scheduler.pending.single.body, 'Rota MVP: bugün 30 dk kaldı.');
  });

  test('a finished plan cancels the reminder', () async {
    final periodId = createProject(title: 'Rota MVP');
    await sync.sync();
    controller.addProgress(periodId, 120);
    await sync.sync();

    expect(scheduler.pending, isEmpty);
  });

  test('nothing changes → nothing is rescheduled', () async {
    createProject(title: 'Rota MVP');
    await sync.sync();
    await sync.sync();
    expect(scheduler.replaceCalls, 1);
  });

  test('turning reminders off clears pending notifications', () async {
    createProject(title: 'Rota MVP');
    await sync.sync();
    controller.updateSettings(
      controller.settings.copyWith(
        reminders: controller.settings.reminders.copyWith(enabled: false),
      ),
    );
    await sync.sync();
    expect(scheduler.pending, isEmpty);
  });

  test('health goals use the private text on the lock screen', () async {
    final category = controller.addCategory(
      'Sağlık',
      preset: PresetCategory.healthMedication,
    );
    controller.createWeeklyDurationGoal(
      categoryId: category.id,
      title: 'Fizyoterapi egzersizi',
      targetMinutes: 60,
      dailyPlan: {monday: 30},
    );
    await sync.sync();

    expect(
      scheduler.pending.single.body,
      'Planlanmış kişisel hatırlatıcın var.',
    );
  });
}
