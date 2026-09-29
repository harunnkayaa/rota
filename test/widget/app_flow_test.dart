import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/goals/presentation/create_goal_screen.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';

import '../helpers/builders.dart';
import '../helpers/fixed_clock.dart';

/// Enters an exact duration through a stepper's "tap the number" sheet.
Future<void> enterDuration(
  WidgetTester tester,
  Finder valueText, {
  required int hours,
  int minutes = 0,
}) async {
  await scrollAndTap(tester, valueText);
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(fields.evaluate().length - 2), '$hours');
  await tester.enterText(fields.last, '$minutes');
  await tester.tap(find.text('Kaydet').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty state offers goal creation and sample data', (
    tester,
  ) async {
    await pumpRota(tester, today: monday);

    expect(find.text('Henüz hedefin yok'), findsOneWidget);
    expect(find.text('Hedef oluştur'), findsOneWidget);
    expect(find.text('Örnek haftayı yükle'), findsOneWidget);
  });

  testWidgets('create a goal with a different amount per day', (tester) async {
    await pumpRota(tester, today: monday);
    await tester.tap(find.text('Hedef oluştur'));
    await tester.pumpAndSettle();

    // Categories are one horizontally scrolling row.
    // Categories are one horizontally scrolling row.
    await tapVisible(tester, find.text('Proje geliştirme'));
    await tester.enterText(
      find.byKey(CreateGoalScreen.titleFieldKey),
      'Rota MVP',
    );
    await tester.pumpAndSettle();

    // Weekly target: 6 hours, typed exactly.
    await enterDuration(tester, find.text('0 dk').first, hours: 6);
    expect(find.text('6 sa'), findsOneWidget);

    // Monday 4 hours, Tuesday 2 hours — not an even split.
    final mondayValue = semanticsLabel(RegExp('^Pzt 28 Eyl: '));
    await enterDuration(tester, mondayValue, hours: 4);
    final tuesdayPlus = find.byTooltip('30 dk artır').at(1);
    for (var i = 0; i < 4; i++) {
      await scrollAndTap(tester, tuesdayPlus);
    }
    await scrollTo(tester, find.text('Planlanan 6 sa / 6 sa'));
    expect(find.text('Plan haftalık hedefi karşılıyor.'), findsOneWidget);

    await tester.tap(find.text('Hedefi oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Rota MVP'), findsOneWidget);
    expect(find.text('0 dk / 4 sa'), findsOneWidget);
    expect(find.text('0 dk / 6 sa'), findsOneWidget);
    expect(find.text('Kalan 4 sa'), findsOneWidget);

    await tapVisible(tester, find.text('İlerleme ekle'));
    await tester.enterText(find.byType(TextField), '90');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('1 sa 30 dk / 4 sa'), findsOneWidget);
    expect(find.text('1 sa 30 dk / 6 sa'), findsOneWidget);
    expect(find.text('Kalan 2 sa 30 dk'), findsOneWidget);
  });

  testWidgets('"even split" is only a helper, not forced', (tester) async {
    await pumpRota(tester, today: friday);
    await tester.tap(find.text('Hedef oluştur'));
    await tester.pumpAndSettle();

    await enterDuration(tester, find.text('0 dk').first, hours: 6);
    await scrollAndTap(tester, find.text('Eşit dağıt'));

    // Friday..Sunday remain this week: 2 hours each.
    expect(find.text('Planlanan 6 sa / 6 sa'), findsOneWidget);
    expect(find.text('2 sa'), findsNWidgets(3));
  });

  testWidgets('form explains what is missing instead of failing silently', (
    tester,
  ) async {
    await pumpRota(tester, today: monday);
    await tester.tap(find.text('Hedef oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hedefi oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Bir kategori seç.'), findsOneWidget);
    await scrollTo(tester, find.text('Hedef adı gerekli.'));
    expect(find.text('Hedef adı gerekli.'), findsOneWidget);
  });

  testWidgets("the user's scenario: short Monday, bigger Tuesday, no debt", (
    tester,
  ) async {
    // Monday plan 4 h, only 3 h done. Tuesday plan 2 h. Weekly target 10 h.
    final clock = FixedClock(monday);
    final controller = PlannerController(clock: clock);
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

    await pumpRota(tester, controller: controller);
    expect(
      find.text('Bu haftanın planında 1 sa açıkta kaldı.'),
      findsOneWidget,
    );

    // Raise today's plan from 2 h to 3 h on the Today screen.
    await tapVisible(tester, find.byTooltip('Bugünün planı'));
    expect(
      find.text('Plan, kalan hedefin 1 sa kısmını karşılamıyor.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('30 dk artır'));
    await tester.pump();
    await tester.tap(find.byTooltip('30 dk artır'));
    await tester.pumpAndSettle();
    expect(find.text('Plan, haftanın kalanını karşılıyor.'), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Plan güncellendi'), findsOneWidget);
    expect(find.text('0 dk / 3 sa'), findsOneWidget);
    expect(find.textContaining('açıkta kaldı'), findsNothing);
  });

  testWidgets('sample week on Saturday: debt → proposal → apply', (
    tester,
  ) async {
    await pumpRota(tester, today: saturday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();

    const debt = 'Bu haftanın planında 2 sa 15 dk açıkta kaldı.';
    expect(find.text(debt), findsOneWidget);

    await tapVisible(tester, find.text('Yeniden dağıt').first);
    expect(find.text('Yeniden dağıtma önerisi'), findsOneWidget);
    expect(find.text('+2 sa 15 dk'), findsOneWidget);

    await tester.tap(find.text('Planı uygula'));
    await tester.pumpAndSettle();

    expect(find.text('Plan güncellendi'), findsOneWidget);
    expect(find.text(debt), findsNothing);
  });

  testWidgets('week screen: capacity bars, day cells, and editing a day', (
    tester,
  ) async {
    await pumpRota(tester, today: saturday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hafta'));
    await tester.pumpAndSettle();

    expect(find.text('Günlük yük'), findsOneWidget);
    // Wednesday on the project goal: 45 of 120 done.
    expect(
      semanticsLabel(RegExp(r'^Çar 30 Eyl: 45 dk / 2 sa, 1 sa 15 dk eksik$')),
      findsOneWidget,
    );

    // Tapping Sunday on the project goal opens that day's plan.
    await tapVisible(
      tester,
      semanticsLabel(RegExp(r'^Paz 4 Eki: 0 dk / 0 dk')).first,
    );
    expect(find.text('Paz 4 Eki planı'), findsOneWidget);
  });

  testWidgets('past days cannot be edited in the week plan', (tester) async {
    await pumpRota(tester, today: saturday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hafta'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byTooltip('Planı düzenle').first);

    expect(find.text('Haftanın planı'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(5));
  });

  testWidgets('wide screens use a navigation rail', (tester) async {
    await pumpRota(tester, today: monday, size: const Size(1280, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
