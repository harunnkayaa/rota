import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';

import '../helpers/builders.dart';
import '../helpers/fixed_clock.dart';

/// A project goal (10 h/week, Mon 4 h + Wed 2 h) with 3 h done last week,
/// seen on the Monday of the following week.
Future<(PlannerController, FixedClock)> _nextWeek(WidgetTester tester) async {
  final clock = FixedClock(monday);
  final controller = PlannerController(clock: clock);
  final category = controller.addCategory('Proje');
  final periodId = controller
      .createWeeklyDurationGoal(
        categoryId: category.id,
        title: 'Proje',
        targetMinutes: 600,
        dailyPlan: {monday: 240, wednesday: 120},
      )
      .id;
  controller.addProgress(periodId, 180);
  clock.day = monday.addDays(7);
  controller.refreshDay();
  await pumpRota(tester, controller: controller);
  return (controller, clock);
}

void main() {
  testWidgets('new week: goal continues, result shown, carry-over on request', (
    tester,
  ) async {
    await _nextWeek(tester);

    // The goal is back for the new week with its Monday plan.
    expect(find.text('0 dk / 4 sa'), findsOneWidget);
    expect(find.text('0 dk / 10 sa'), findsOneWidget);
    expect(find.text('Geçen hafta kapandı'), findsOneWidget);

    await tester.tap(find.text('Özeti gör'));
    await tester.pumpAndSettle();
    expect(find.text('3 sa / 10 sa'), findsOneWidget);
    expect(find.text('7 sa eksik kaldı'), findsOneWidget);

    await tester.tap(find.text('7 sa bu haftaya ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Bu haftaya eklendi'), findsOneWidget);

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Geçen hafta kapandı'), findsNothing);
    expect(find.text('0 dk / 17 sa'), findsOneWidget);
  });

  testWidgets('archiving asks first, then removes the goal', (tester) async {
    await _nextWeek(tester);

    await tester.tap(find.byTooltip('Diğer işlemler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hedefi arşivle'));
    await tester.pumpAndSettle();
    expect(find.text('Hedef arşivlensin mi?'), findsOneWidget);

    await tester.tap(find.text('Arşivle'));
    await tester.pumpAndSettle();
    expect(find.text('Hedef arşivlendi'), findsOneWidget);
    expect(find.text('Henüz hedefin yok'), findsOneWidget);
  });

  testWidgets('focus: start, pause, finish records the minutes', (
    tester,
  ) async {
    final (controller, clock) = await _nextWeek(tester);

    await tapVisible(tester, find.text('Odaklan'));
    expect(find.text('00:00'), findsOneWidget);

    clock.advance(const Duration(minutes: 25));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.text('Duraklat'));
    await tester.pump();
    expect(find.text('Duraklatıldı'), findsOneWidget);
    clock.advance(const Duration(minutes: 10));
    await tester.tap(find.text('Devam et'));
    await tester.pump();

    await tester.tap(find.text('Bitir ve kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('25 dk kaydedildi'), findsOneWidget);
    expect(find.text('25 dk / 4 sa'), findsOneWidget);
    expect(controller.activeFocus, isNull);
  });

  testWidgets('a running focus session shows on Today', (tester) async {
    final (controller, _) = await _nextWeek(tester);
    controller.startFocus(controller.activeGoals().single.period.id);
    await tester.pump();

    expect(find.text('Odak sürüyor · Proje'), findsOneWidget);
    // The banner ticks every second; stop it before the test ends.
    controller.cancelFocus();
    await tester.pump();
  });

  testWidgets('settings: capacity per weekday changes the Week screen', (
    tester,
  ) async {
    final (controller, _) = await _nextWeek(tester);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('Günlük kapasite'), findsOneWidget);

    await tester.tap(find.byTooltip('30 dk artır').first);
    await tester.pumpAndSettle();
    expect(controller.settings.dailyCapacityMinutes, 270);
    expect(controller.capacityOn(monday.addDays(7)).capacity, 270);
  });

  testWidgets('reports: this week, categories and the closed week', (
    tester,
  ) async {
    await _nextWeek(tester);

    await tester.tap(find.text('Rapor'));
    await tester.pumpAndSettle();

    expect(find.text('Bu hafta'), findsOneWidget);
    expect(find.text('Kategoriye göre'), findsOneWidget);
    await scrollTo(tester, find.text('Geçmiş haftalar'));
    await scrollTo(tester, find.text('%30'));
    expect(find.text('3 sa / 10 sa'), findsNWidgets(2)); // week total + goal
  });
}
