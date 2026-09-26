import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/planning/data/planner_storage.dart';

import '../helpers/builders.dart';
import '../helpers/fixed_clock.dart';

class _FailingWrites extends InMemoryPlannerStorage {
  @override
  Future<void> write(String data) async => throw StateError('disk full');
}

void main() {
  testWidgets('unreadable saved data shows a recoverable error', (
    tester,
  ) async {
    await pumpRota(
      tester,
      today: monday,
      storage: InMemoryPlannerStorage('{broken'),
    );

    expect(find.text('Kayıtlı verilerin okunamadı'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.text('Henüz hedefin yok'), findsNothing);
  });

  testWidgets('a failed save shows a banner with retry', (tester) async {
    await pumpRota(tester, today: saturday, storage: _FailingWrites());

    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();

    expect(
      find.text('Son değişiklik bu cihaza kaydedilemedi.'),
      findsOneWidget,
    );
  });

  testWidgets('saved goals appear after an app restart', (tester) async {
    final storage = InMemoryPlannerStorage();
    final first = await pumpRota(tester, today: saturday, storage: storage);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();
    await first.flush();

    await pumpRota(tester, today: saturday, storage: storage);

    expect(find.text('Rota MVP geliştirme'), findsOneWidget);
    expect(find.text('PTE hazırlık'), findsOneWidget);
  });
}
