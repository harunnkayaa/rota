import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/planning/data/planner_storage.dart';
import 'package:rota/features/planning/domain/progress_calculator.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';
import 'package:rota/features/settings/domain/planner_settings.dart';

import '../../../helpers/builders.dart';
import '../../../helpers/fixed_clock.dart';

void main() {
  late FixedClock clock;
  late PlannerController controller;

  setUp(() {
    clock = FixedClock(monday);
    controller = PlannerController(clock: clock);
  });

  String createProject() {
    final category = controller.addCategory('Proje');
    return controller
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Proje',
          targetMinutes: 600,
          dailyPlan: {monday: 240, wednesday: 120},
        )
        .id;
  }

  group('new week', () {
    test('the goal continues next week with its plan pattern', () {
      final periodId = createProject();
      controller.addProgress(periodId, 180);

      clock.day = monday.addDays(7);
      controller.refreshDay();

      final view = controller.activeGoals().single;
      expect(view.period.id, isNot(periodId));
      expect(view.period.targetValue, 600);
      expect(view.todayAllocated, 240);
      expect(view.periodDone, 0);
    });

    test("last week's result waits for review, once", () {
      final periodId = createProject();
      controller.addProgress(periodId, 180);
      clock.day = monday.addDays(7);
      controller.refreshDay();

      final review = controller.pendingReviews.single;
      expect(review.achieved, 180);
      expect(review.shortfall, 420);

      controller.markReviewed();
      expect(controller.pendingReviews, isEmpty);
    });

    test('carry-over is explicit and adds to this week only', () {
      createProject();
      clock.day = monday.addDays(7);
      controller.refreshDay();
      final review = controller.pendingReviews.single;

      expect(controller.activeGoals().single.period.targetValue, 600);
      expect(controller.canCarryOver(review), isTrue);

      controller.carryOver(review);
      expect(controller.activeGoals().single.period.targetValue, 1200);
      expect(controller.canCarryOver(review), isFalse);

      // The week after starts from the default again.
      clock.day = monday.addDays(14);
      controller.refreshDay();
      expect(controller.activeGoals().single.period.targetValue, 600);
    });

    test('an archived goal disappears and does not come back', () {
      createProject();
      final goalId = controller.activeGoals().single.goal.id;
      controller.archiveGoal(goalId);
      expect(controller.activeGoals(), isEmpty);

      clock.day = monday.addDays(7);
      controller.refreshDay();
      expect(controller.activeGoals(), isEmpty);
    });

    test('changing the weekly target also changes the following weeks', () {
      final periodId = createProject();
      controller.updateTarget(periodId, 480);
      clock.day = monday.addDays(7);
      controller.refreshDay();
      expect(controller.activeGoals().single.period.targetValue, 480);
    });

    test('rollover happens on load after days away', () async {
      final storage = InMemoryPlannerStorage();
      final first = PlannerController(clock: clock, storage: storage);
      await first.load();
      final category = first.addCategory('Proje');
      first.createWeeklyDurationGoal(
        categoryId: category.id,
        title: 'Proje',
        targetMinutes: 600,
        dailyPlan: {monday: 240},
      );
      await first.flush();

      clock.day = monday.addDays(10);
      final later = PlannerController(clock: clock, storage: storage);
      await later.load();
      expect(later.activeGoals().single.period.range.start, monday.addDays(7));
      expect(later.pendingReviews, hasLength(1));
    });
  });

  group('settings', () {
    test('weekday capacity overrides the daily default', () {
      controller.updateSettings(
        PlannerSettings(
          dailyCapacityMinutes: 180,
          weekdayCapacityMinutes: {DateTime.saturday: 360},
        ),
      );
      expect(controller.capacityOn(monday).capacity, 180);
      expect(controller.capacityOn(saturday).capacity, 360);
    });

    test('a Sunday week start shifts the current week', () {
      controller.updateSettings(PlannerSettings(weekStartDay: DateTime.sunday));
      expect(controller.currentWeek.start, monday.addDays(-1));
    });
  });

  group('focus timer', () {
    test('records worked minutes minus pauses as one progress entry', () {
      final periodId = createProject();
      controller.startFocus(periodId);
      clock.advance(const Duration(minutes: 30));
      controller.pauseFocus();
      clock.advance(const Duration(minutes: 10));
      controller.resumeFocus();
      clock.advance(const Duration(minutes: 20, seconds: 40));

      expect(controller.finishFocus(), 50);
      expect(controller.activeFocus, isNull);
      expect(controller.activeGoals().single.todayDone, 50);
    });

    test('only one timer at a time', () {
      final periodId = createProject();
      controller.startFocus(periodId);
      expect(() => controller.startFocus(periodId), throwsStateError);
    });

    test('less than a minute records nothing', () {
      final periodId = createProject();
      controller.startFocus(periodId);
      clock.advance(const Duration(seconds: 40));
      expect(controller.finishFocus(), 0);
      expect(controller.activeGoals().single.todayDone, 0);
    });

    test('a running timer survives an app restart', () async {
      final storage = InMemoryPlannerStorage();
      final first = PlannerController(clock: clock, storage: storage);
      await first.load();
      final category = first.addCategory('Proje');
      final periodId = first
          .createWeeklyDurationGoal(
            categoryId: category.id,
            title: 'Proje',
            targetMinutes: 600,
            dailyPlan: {monday: 240},
          )
          .id;
      first.startFocus(periodId);
      await first.flush();

      clock.advance(const Duration(minutes: 45));
      final reopened = PlannerController(clock: clock, storage: storage);
      await reopened.load();
      expect(reopened.activeFocus, isNotNull);
      expect(reopened.finishFocus(), 45);
    });

    test('if the week ended meanwhile, the timer is kept, not lost', () {
      final periodId = createProject();
      controller.startFocus(periodId);
      clock.day = monday.addDays(7);
      controller.refreshDay();

      expect(controller.finishFocus, throwsA(isA<ProgressRejectedException>()));
      expect(controller.activeFocus, isNotNull);
    });
  });
}
