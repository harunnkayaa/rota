import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/builders.dart';
import '../helpers/fixed_clock.dart';

/// The form's own list; text fields contain scrollables of their own.
final _formList = find.byType(Scrollable).first;

void main() {
  testWidgets('empty state offers goal creation and sample data', (
    tester,
  ) async {
    await pumpRota(tester, today: monday);

    expect(find.text('Henüz hedefin yok'), findsOneWidget);
    expect(find.text('Hedef oluştur'), findsOneWidget);
    expect(find.text('Örnek haftayı yükle'), findsOneWidget);
  });

  testWidgets('create a weekly goal, then add progress from Today', (
    tester,
  ) async {
    await pumpRota(tester, today: monday);

    await tester.tap(find.text('Hedef oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proje geliştirme'));
    await tester.enterText(find.byType(TextField).at(0), 'Rota MVP');
    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.pumpAndSettle();

    // Deselect the weekend: 600 min over Mon–Fri = 2 sa per day.
    for (final weekendDay in ['Cmt 3 Eki', 'Paz 4 Eki']) {
      final chip = find.widgetWithText(
        FilterChip,
        weekendDay,
        skipOffstage: false,
      );
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(chip).selected, isFalse);
    }

    await tester.scrollUntilVisible(
      find.text('Hedefi oluştur'),
      100,
      scrollable: _formList,
    );
    await tester.tap(find.text('Hedefi oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Rota MVP'), findsOneWidget);
    expect(find.text('0 dk / 2 sa'), findsOneWidget);
    expect(find.text('0 dk / 10 sa'), findsOneWidget);

    await tester.tap(find.text('İlerleme ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '90');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('1 sa 30 dk / 2 sa'), findsOneWidget);
    expect(find.text('1 sa 30 dk / 10 sa'), findsOneWidget);
  });

  testWidgets('form explains what is missing instead of failing silently', (
    tester,
  ) async {
    await pumpRota(tester, today: monday);
    await tester.tap(find.text('Hedef oluştur'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Hedefi oluştur'),
      100,
      scrollable: _formList,
    );
    await tester.tap(find.text('Hedefi oluştur'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Bir kategori seç.'),
      -100,
      scrollable: _formList,
    );

    expect(find.text('Bir kategori seç.'), findsOneWidget);
    expect(find.text('Hedef adı gerekli.'), findsOneWidget);
  });

  testWidgets('sample week on Saturday: debt → proposal → apply', (
    tester,
  ) async {
    await pumpRota(tester, today: saturday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();

    expect(
      find.text('Bu haftanın planında 2 sa 15 dk açıkta kaldı.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Yeniden dağıt').first);
    await tester.pumpAndSettle();

    expect(find.text('Yeniden dağıtma önerisi'), findsOneWidget);
    expect(find.text('+2 sa 15 dk'), findsOneWidget);

    await tester.tap(find.text('Planı uygula'));
    await tester.pumpAndSettle();

    expect(find.text('Plan güncellendi'), findsOneWidget);
    expect(
      find.text('Bu haftanın planında 2 sa 15 dk açıkta kaldı.'),
      findsNothing,
    );
  });

  testWidgets('week screen lists daily capacity and per-day status', (
    tester,
  ) async {
    await pumpRota(tester, today: saturday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hafta'));
    await tester.pumpAndSettle();

    expect(find.text('Günlük kapasite'), findsOneWidget);
    // Wednesday: 45 of 120 done on the project goal.
    expect(find.text('45 dk / 2 sa'), findsOneWidget);
    expect(find.text('1 sa 15 dk eksik'), findsOneWidget);
  });

  testWidgets('wide screens use a navigation rail', (tester) async {
    await pumpRota(tester, today: monday, size: const Size(1280, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
