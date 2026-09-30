import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/planning/data/planner_json.dart';
import 'package:rota/features/planning/data/planner_storage.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';
import 'package:rota/features/reminders/domain/reminder_planner.dart';
import 'package:rota/features/schedule/domain/time_block.dart';

import '../../../helpers/builders.dart';
import '../../../helpers/fixed_clock.dart';

const _h = Duration.minutesPerHour;

void main() {
  late FixedClock clock;
  late PlannerController controller;
  late String periodId;
  var ids = 0;

  TimeBlock goalBlock(int start, int end, {String? id, bool remind = false}) =>
      TimeBlock(
        id: id ?? 'block-${ids++}',
        date: clock.day,
        startMinute: start,
        endMinute: end,
        kind: TimeBlockKind.goal,
        goalPeriodId: periodId,
        remind: remind,
      );

  TimeBlock rest(int start, int end) => TimeBlock(
    id: 'block-${ids++}',
    date: clock.day,
    startMinute: start,
    endMinute: end,
    kind: TimeBlockKind.rest,
  );

  setUp(() async {
    clock = FixedClock(monday);
    controller = PlannerController(
      clock: clock,
      storage: InMemoryPlannerStorage(),
    );
    await controller.load();
    final category = controller.addCategory('Proje');
    periodId = controller
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Rota MVP',
          targetMinutes: 600,
          dailyPlan: {monday: 120},
        )
        .id;
  });

  test('a planned morning: work, break, work', () {
    controller
      ..saveBlock(goalBlock(9 * _h, 11 * _h))
      ..saveBlock(rest(11 * _h, 11 * _h + 15))
      ..saveBlock(goalBlock(11 * _h + 15, 12 * _h));

    expect(controller.blocksOn(monday).map((b) => b.kind), [
      TimeBlockKind.goal,
      TimeBlockKind.rest,
      TimeBlockKind.goal,
    ]);
    expect(controller.scheduledFor(periodId, monday), 165);
    // Blocks place the plan on the clock; they don't change it or count as
    // progress.
    expect(controller.allocatedOn(periodId, monday), 120);
    expect(controller.activeGoals().single.todayDone, 0);
  });

  test('clashing, past-day and out-of-week blocks are refused', () {
    controller.saveBlock(goalBlock(9 * _h, 11 * _h));
    expect(
      () => controller.saveBlock(rest(10 * _h, 10 * _h + 30)),
      throwsA(
        isA<BlockRejectedException>().having(
          (e) => e.reason,
          'reason',
          BlockRejection.overlaps,
        ),
      ),
    );
    clock.day = tuesday;
    expect(
      () => controller.saveBlock(rest(9 * _h, 10 * _h).copyWith(date: monday)),
      throwsA(isA<BlockRejectedException>()),
      reason: 'yesterday is history',
    );
    expect(
      () => controller.saveBlock(
        goalBlock(9 * _h, 10 * _h).copyWith(date: monday.addDays(7)),
      ),
      throwsA(
        isA<BlockRejectedException>().having(
          (e) => e.reason,
          'reason',
          BlockRejection.outsidePeriod,
        ),
      ),
    );
  });

  test('moving a block keeps one copy; deleting removes it', () {
    final block = goalBlock(9 * _h, 11 * _h);
    controller
      ..saveBlock(block)
      ..saveBlock(block.copyWith(startMinute: 10 * _h, endMinute: 12 * _h));
    expect(controller.blocksOn(monday).single.startMinute, 10 * _h);
    controller.deleteBlock(block.id);
    expect(controller.blocksOn(monday), isEmpty);
  });

  test(
    'copying yesterday fills today and never duplicates on a second tap',
    () {
      controller
        ..saveBlock(goalBlock(9 * _h, 11 * _h))
        ..saveBlock(rest(11 * _h, 11 * _h + 15));
      clock.day = tuesday;

      final first = controller.copyBlocks(from: monday, to: tuesday);
      expect(first.added, hasLength(2));
      expect(controller.scheduledFor(periodId, tuesday), 120);

      final second = controller.copyBlocks(from: monday, to: tuesday);
      expect(second.added, isEmpty);
      expect(second.skipped, 2);
      expect(controller.blocksOn(tuesday), hasLength(2));
    },
  );

  test('blocks survive a restart and old save files still open', () async {
    final storage = InMemoryPlannerStorage();
    final c = PlannerController(clock: clock, storage: storage);
    await c.load();
    final category = c.addCategory('Proje');
    final id = c
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Rota MVP',
          targetMinutes: 600,
          dailyPlan: {monday: 120},
        )
        .id;
    c.saveBlock(
      TimeBlock(
        id: 'b1',
        date: monday,
        startMinute: 9 * _h,
        endMinute: 11 * _h,
        kind: TimeBlockKind.goal,
        goalPeriodId: id,
        remind: true,
      ),
    );
    await c.flush();

    final reopened = PlannerController(clock: clock, storage: storage);
    await reopened.load();
    final block = reopened.blocksOn(monday).single;
    expect(block.goalPeriodId, id);
    expect(block.remind, isTrue);

    // A v2 file (before blocks existed) opens with an empty schedule.
    final v2 = storage.data!.replaceFirst(
      '"schema_version":$plannerSchemaVersion',
      '"schema_version":2',
    );
    expect(decodePlannerData(v2).blocks, isEmpty);
  });

  test('a block asked to remind becomes a reminder at its start', () {
    controller
      ..saveBlock(goalBlock(14 * _h, 15 * _h, remind: true))
      ..saveBlock(rest(15 * _h, 15 * _h + 15));
    final blockReminders = controller.reminderCandidates().where(
      (c) => c.kind == ReminderKind.blockStart,
    );
    expect(blockReminders.single.atMinute, 14 * _h);
    expect(blockReminders.single.goalTitle, 'Rota MVP');
  });

  test('delete all data clears the schedule too', () {
    controller
      ..saveBlock(goalBlock(9 * _h, 11 * _h))
      ..deleteAllData();
    expect(controller.blocksOn(monday), isEmpty);
  });
}
