import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/features/planning/data/planner_storage.dart';
import 'package:rota/features/planning/domain/deadline_pace.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';

import '../../../helpers/builders.dart';
import '../../../helpers/fixed_clock.dart';

void main() {
  final examDay = LocalDate(2026, 11, 15);
  late FixedClock clock;
  late PlannerController controller;

  setUp(() {
    clock = FixedClock(monday);
    controller = PlannerController(clock: clock);
  });

  String createExam({int total = 2400, Map<LocalDate, int> plan = const {}}) {
    final category = controller.addCategory('PTE');
    return controller
        .createDeadlineGoal(
          categoryId: category.id,
          title: 'PTE sınavı',
          totalMinutes: total,
          dueDate: examDay,
          dailyPlan: plan,
        )
        .id;
  }

  String createProject(Map<LocalDate, int> plan) {
    final category = controller.addCategory('Proje');
    return controller
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Proje',
          targetMinutes: 600,
          dailyPlan: plan,
        )
        .id;
  }

  test('a deadline goal shows its pace and only this week on the card', () {
    createExam(plan: {monday: 120});

    final view = controller.activeGoals().single;
    expect(view.isDeadline, isTrue);
    expect(view.pace!.daysLeft, 48);
    expect(view.pace!.requiredThisWeek, 350);
    expect(view.days, hasLength(7));
    expect(view.debt, 0, reason: 'judged by pace, not by weekly debt');
  });

  test('due date must be after today', () {
    final category = controller.addCategory('PTE');
    expect(
      () => controller.createDeadlineGoal(
        categoryId: category.id,
        title: 'PTE',
        totalMinutes: 600,
        dueDate: monday,
        dailyPlan: const {},
      ),
      throwsArgumentError,
    );
  });

  test('form preview matches the created goal', () {
    final preview = controller.previewDeadline(
      totalMinutes: 2400,
      dueDate: examDay,
      dailyPlan: {monday: 200},
    );
    createExam(plan: {monday: 200});

    final created = controller.activeGoals().single.pace!;
    expect(preview.requiredThisWeek, created.requiredThisWeek);
    expect(preview.thisWeekGap, created.thisWeekGap);
  });

  test('catch-up uses free time first, then only goals the user picked', () {
    // Capacity 240/day. Project fills Mon–Wed completely.
    final projectId = createProject({
      monday: 240,
      tuesday: 240,
      wednesday: 240,
    });
    final examId = createExam();

    expect(controller.catchUpDonors(examId).single.period.id, projectId);

    final withoutPermission = controller.proposeCatchUpFor(examId);
    expect(withoutPermission.reductions, isEmpty);

    final withProject = controller.proposeCatchUpFor(
      examId,
      donorPeriodIds: {projectId},
    );
    expect(withProject.shortfall, 0);
  });

  test(
    'applying a catch-up moves minutes and keeps each day within capacity',
    () {
      final projectId = createProject({
        monday: 240,
        tuesday: 240,
        wednesday: 240,
      });
      final examId = createExam();
      clock.day = saturday;
      // Only Sat + Sun are left this week, both free: 480 min available.

      final before = controller.goalView(examId).pace!;
      final proposal = controller.proposeCatchUpFor(
        examId,
        donorPeriodIds: {projectId},
      );
      controller.applyCatchUp(examId, proposal);

      final after = controller.goalView(examId).pace!;
      expect(after.thisWeekGap, lessThan(before.thisWeekGap));
      for (final day in [saturday, sunday]) {
        expect(controller.capacityOn(day).isOver, isFalse);
      }
    },
  );

  test('lowering the total target updates the pace immediately', () {
    final examId = createExam();
    final before = controller.goalView(examId).pace!.requiredPerWeek;

    controller.updateTarget(examId, 1200);

    expect(controller.goalView(examId).pace!.requiredPerWeek, before ~/ 2);
  });

  test('a deadline goal survives a restart', () async {
    final storage = InMemoryPlannerStorage();
    final first = PlannerController(clock: clock, storage: storage);
    await first.load();
    final category = first.addCategory('PTE');
    first.createDeadlineGoal(
      categoryId: category.id,
      title: 'PTE sınavı',
      totalMinutes: 2400,
      dueDate: examDay,
      dailyPlan: {monday: 120},
    );
    await first.flush();

    final second = PlannerController(clock: clock, storage: storage);
    await second.load();
    final pace = second.activeGoals().single.pace!;
    expect(pace.dueDate, examDay);
    expect(pace.total, 2400);
    expect(pace.status, DeadlineStatus.behindThisWeek);
  });
}
