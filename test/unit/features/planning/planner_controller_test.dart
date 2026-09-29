import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/categories/domain/category.dart';
import 'package:rota/features/planning/domain/progress_calculator.dart';
import 'package:rota/features/planning/domain/redistribution.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';

import '../../../helpers/builders.dart';
import '../../../helpers/fixed_clock.dart';

const _sampleTexts = SampleWeekTexts(
  projectCategory: 'Proje geliştirme',
  languageCategory: 'PTE / dil',
  projectGoal: 'Rota MVP',
  languageGoal: 'PTE',
);

void main() {
  late FixedClock clock;
  late PlannerController controller;

  setUp(() {
    clock = FixedClock(monday);
    controller = PlannerController(clock: clock);
  });

  String createProjectGoal() {
    final category = controller.addCategory('Proje');
    return controller
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Proje',
          targetMinutes: 600,
          dailyPlan: {
            for (final d in [monday, tuesday, wednesday, thursday, friday])
              d: 120,
          },
        )
        .id;
  }

  test('end-to-end: 90 min on Monday → 90/120 today, 90/600 week', () {
    final periodId = createProjectGoal();
    controller.addProgress(periodId, 90);

    final view = controller.activeGoals().single;
    expect(view.todayDone, 90);
    expect(view.todayAllocated, 120);
    expect(view.periodDone, 90);
    expect(view.period.targetValue, 600);
  });

  group('taking back a mistaken entry', () {
    test('adds a negative adjustment; totals drop, history stays', () {
      final periodId = createProjectGoal();
      controller.addProgress(periodId, 30);
      final wrong = controller.addProgress(periodId, 90);

      controller.undoProgress(wrong);

      final view = controller.activeGoals().single;
      expect(view.todayDone, 30);
      expect(view.periodDone, 30);
      final data = controller.snapshotData();
      expect(data.entries, hasLength(3), reason: 'append-only');
      expect(data.entries.last.valueDelta, -90);
      expect(controller.undoableEntries(periodId).single.valueDelta, 30);
    });

    test('taking back twice counts once', () {
      final periodId = createProjectGoal();
      final id = controller.addProgress(periodId, 90);
      controller
        ..undoProgress(id)
        ..undoProgress(id);
      expect(controller.activeGoals().single.periodDone, 0);
      expect(controller.snapshotData().entries, hasLength(2));
    });

    test('only today\'s entries can be taken back from the list', () {
      final periodId = createProjectGoal();
      controller.addProgress(periodId, 60);
      clock.day = tuesday;
      expect(controller.undoableEntries(periodId), isEmpty);
    });
  });

  test('renaming a goal keeps its progress and target', () {
    final periodId = createProjectGoal();
    controller.addProgress(periodId, 45);
    final goalId = controller.activeGoals().single.goal.id;

    controller.renameGoal(goalId, '  Rota v1  ');

    final view = controller.activeGoals().single;
    expect(view.goal.title, 'Rota v1');
    expect(view.periodDone, 45);
    expect(() => controller.renameGoal(goalId, ' '), throwsArgumentError);
  });

  test('a missed Monday shows up as debt on Tuesday and can be re-planned', () {
    final periodId = createProjectGoal();
    controller.addProgress(periodId, 60);
    clock.day = tuesday;

    expect(controller.activeGoals().single.debt, 60);

    final proposal =
        controller.proposeRedistributionFor(periodId) as RedistributionProposal;
    expect(proposal.isFeasible, isTrue);

    controller.applyProposal(periodId, proposal);
    expect(controller.activeGoals().single.debt, 0);
  });

  test('nothing changes until a proposal is applied', () {
    final periodId = createProjectGoal();
    clock.day = tuesday;
    final before = controller.capacityOn(wednesday).planned;

    controller.proposeRedistributionFor(periodId);

    expect(controller.capacityOn(wednesday).planned, before);
  });

  test('picking the same preset twice reuses the category', () {
    final a = controller.addCategory('Kitap', preset: PresetCategory.reading);
    final b = controller.addCategory('Kitap', preset: PresetCategory.reading);
    expect(a.id, b.id);
    expect(controller.categories, hasLength(1));
  });

  test('sensitive presets mark their goals sensitive', () {
    final health = controller.addCategory(
      'Sağlık',
      preset: PresetCategory.healthMedication,
    );
    expect(health.isSensitive, isTrue);
  });

  test('progress after the week ended is rejected', () {
    final periodId = createProjectGoal();
    clock.day = sunday.addDays(1);
    expect(
      () => controller.addProgress(periodId, 30),
      throwsA(isA<ProgressRejectedException>()),
    );
  });

  test('sample week loaded on Saturday has debt and capacity data', () {
    clock.day = saturday;
    controller.loadSampleWeek(_sampleTexts);

    final goals = controller.activeGoals();
    expect(goals, hasLength(2));
    // Project: 600 target, 465 done Mon–Fri, nothing planned after Friday.
    expect(goals.first.periodDone, 465);
    expect(goals.first.debt, 135);
    // PTE: 360 target, 120 done, Saturday's 90 still planned.
    expect(goals.last.debt, 150);
    expect(controller.todaySummary().plannedMinutes, 90);
  });

  test('making up a short Monday is not "over target"', () {
    final category = controller.addCategory('Proje');
    final periodId = controller
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Proje',
          targetMinutes: 600,
          dailyPlan: {monday: 240, tuesday: 120, wednesday: 240},
        )
        .id;
    controller.addProgress(periodId, 180);
    clock.day = tuesday;

    controller.updatePlan(periodId, {tuesday: 180});
    var view = controller.activeGoals().single;
    expect(view.debt, 0);
    expect(view.surplus, 0);
    expect(view.todayRemaining, 180);

    controller.updatePlan(periodId, {thursday: 30});
    view = controller.activeGoals().single;
    expect(view.surplus, 30);
  });

  test('today remaining never goes below zero', () {
    final category = controller.addCategory('Proje');
    final periodId = controller
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Proje',
          targetMinutes: 600,
          dailyPlan: {monday: 60},
        )
        .id;
    controller.addProgress(periodId, 90);
    expect(controller.activeGoals().single.todayRemaining, 0);
    expect(controller.todaySummary().remainingMinutes, 0);
  });
}
