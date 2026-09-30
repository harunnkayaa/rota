import 'package:flutter_test/flutter_test.dart';

import '../helpers/builders.dart';
import '../helpers/fixed_clock.dart';

void main() {
  testWidgets('delete all data asks first and can be cancelled', (
    tester,
  ) async {
    await pumpRota(tester, today: saturday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Tüm verileri sil'));
    expect(find.text('Tüm veriler silinsin mi?'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bugün'));
    await tester.pumpAndSettle();
    expect(find.text('Rota MVP geliştirme'), findsOneWidget);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Tüm verileri sil'));
    await tester.tap(find.text('Kalıcı olarak sil'));
    await tester.pumpAndSettle();
    expect(find.text('Tüm veriler silindi'), findsOneWidget);

    await tester.tap(find.text('Bugün'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz hedefin yok'), findsOneWidget);
  });

  testWidgets('export shows the data and offers to copy it', (tester) async {
    await pumpRota(tester, today: saturday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('Verilerini dışa aktar'));
    expect(find.text('Dışa aktarılan veri'), findsOneWidget);
    expect(find.textContaining('"schema_version": 3'), findsOneWidget);
    expect(find.text('Panoya kopyala'), findsOneWidget);
  });
}
