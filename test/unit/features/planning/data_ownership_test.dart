import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/planning/data/planner_json.dart';
import 'package:rota/features/planning/data/planner_storage.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';

import '../../../helpers/builders.dart';
import '../../../helpers/fixed_clock.dart';

void main() {
  late PlannerController controller;
  late InMemoryPlannerStorage storage;

  setUp(() async {
    storage = InMemoryPlannerStorage();
    controller = PlannerController(clock: FixedClock(monday), storage: storage);
    await controller.load();
    final category = controller.addCategory('Proje');
    final periodId = controller
        .createWeeklyDurationGoal(
          categoryId: category.id,
          title: 'Rota MVP',
          targetMinutes: 600,
          dailyPlan: {monday: 120},
        )
        .id;
    controller.addProgress(periodId, 90);
  });

  test('export contains everything and can be read back', () {
    final exported = controller.exportJson();

    final json = jsonDecode(exported) as Map<String, Object?>;
    expect(json['schema_version'], plannerSchemaVersion);
    expect(exported, contains('Rota MVP'));
    final restored = decodePlannerData(exported);
    expect(restored.goals.single.title, 'Rota MVP');
    expect(restored.entries.single.valueDelta, 90);
  });

  test('delete removes everything, also after a restart', () async {
    controller.deleteAllData();
    await controller.flush();
    expect(controller.activeGoals(), isEmpty);
    expect(controller.categories, isEmpty);

    final reopened = PlannerController(
      clock: FixedClock(monday),
      storage: storage,
    );
    await reopened.load();
    expect(reopened.activeGoals(), isEmpty);
    expect(storage.data, isNot(contains('Rota MVP')));
  });
}
