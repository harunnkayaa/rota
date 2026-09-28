import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/features/goals/presentation/create_goal_screen.dart';
import 'package:rota/features/planning/presentation/planner_controller.dart';

import '../helpers/builders.dart';
import '../helpers/fixed_clock.dart';

void main() {
  testWidgets('create a deadline goal: date, total, live pace, even split', (
    tester,
  ) async {
    await pumpRota(tester, today: monday);
    await tester.tap(find.text('Hedef oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tarihli'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Mülakat'));
    await tester.enterText(
      find.byKey(CreateGoalScreen.titleFieldKey),
      'Teknik mülakat',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Günlük planı görmek için önce tarihi ve toplam hedefi seç.'),
      findsOneWidget,
    );

    // Due Wednesday 30 Sep: Monday and Tuesday are left to prepare.
    await tapVisible(tester, find.byKey(CreateGoalScreen.dueDateKey));
    await tester.tap(find.text('30'));
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('30 Eylül Çarşamba · 2 gün kaldı'), findsOneWidget);

    // Total: 4 hours, via the "+1 sa" button.
    for (var i = 0; i < 4; i++) {
      await scrollAndTap(tester, find.byTooltip('1 sa artır'));
    }
    await scrollTo(tester, find.text('Haftada ~4 sa gerekiyor'));
    expect(
      find.text('Mevcut kapasitenle bu tarihe yetişebilirsin.'),
      findsOneWidget,
    );

    await scrollAndTap(tester, find.text('Eşit dağıt'));
    await scrollTo(tester, find.text('Bu hafta planlanan 4 sa / tempo 4 sa'));
    expect(find.text('Plan bu haftanın temposunu karşılıyor.'), findsOneWidget);

    await tester.tap(find.text('Hedefi oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Teknik mülakat'), findsOneWidget);
    await scrollTo(tester, find.text('Yolunda'));
    expect(find.text('Bu haftanın temposu'), findsOneWidget);
  });

  testWidgets('behind on pace → take time from another goal → on track', (
    tester,
  ) async {
    final controller = PlannerController(clock: FixedClock(monday));
    final project = controller.addCategory('Proje');
    controller.createWeeklyDurationGoal(
      categoryId: project.id,
      title: 'Proje',
      targetMinutes: 1680,
      // Every day of the week is already full (capacity 240).
      dailyPlan: {for (final d in controller.currentWeek.days) d: 240},
    );
    final exam = controller.addCategory('PTE');
    controller.createDeadlineGoal(
      categoryId: exam.id,
      title: 'PTE sınavı',
      totalMinutes: 2400,
      dueDate: LocalDate(2026, 11, 15),
      dailyPlan: const {},
    );

    await pumpRota(tester, controller: controller);
    await scrollTo(tester, find.text('Bu hafta 5 sa 50 dk açık'));

    await scrollAndTap(tester, find.text('Seçenekler'));
    expect(find.text('Tempoyu yakala'), findsOneWidget);
    expect(
      find.text('Tempoya yetişmek için bu hafta 5 sa 50 dk daha gerekiyor.'),
      findsOneWidget,
    );

    // Nothing is taken from "Proje" until the user switches it on.
    final apply = find.widgetWithText(FilledButton, 'Planı uygula');
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Yolunda'));
    expect(find.text('Yolunda'), findsOneWidget);
    expect(controller.capacityOn(monday).isOver, isFalse);
  });
}
