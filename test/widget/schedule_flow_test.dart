import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/schedule/presentation/day_schedule_card.dart';

import '../helpers/builders.dart';
import '../helpers/fixed_clock.dart';

Future<void> _addBlock(
  WidgetTester tester, {
  String? kind,
  String? duration,
}) async {
  await tapVisible(tester, find.text('Blok ekle'));
  if (kind != null) {
    await tester.tap(find.text(kind).last);
    await tester.pumpAndSettle();
  }
  if (duration != null) {
    await tester.tap(find.widgetWithText(ChoiceChip, duration));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Kaydet'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('plan the day on the clock: work, break, more work', (
    tester,
  ) async {
    // FixedClock: Wednesday 12:00. Sample week: Rota MVP 2 sa today.
    final controller = await pumpRota(tester, today: wednesday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();
    final projectId = controller.activeGoals().first.period.id;
    expect(find.text('Günün akışı'), findsOneWidget);

    // A goal block starts at the next half hour and is the first goal.
    await _addBlock(tester, duration: '2 sa');
    expect(controller.blocksOn(wednesday).single.startMinute, 12 * 60);
    expect(find.text('Saatte: 12:00–14:00'), findsOneWidget);

    // The next block starts where the last one ended.
    await _addBlock(tester, kind: 'Mola', duration: '15 dk');
    final rest = controller.blocksOn(wednesday).last;
    expect((rest.startMinute, rest.endMinute), (14 * 60, 14 * 60 + 15));

    // More project time than planned: offered, not forced.
    await _addBlock(tester, duration: '1 sa');
    expect(controller.allocatedOn(projectId, wednesday), 120);
    expect(find.textContaining('Planı 3 sa yapayım mı?'), findsOneWidget);
    await tester.tap(find.text('Planı güncelle'));
    await tester.pumpAndSettle();
    expect(controller.allocatedOn(projectId, wednesday), 180);
  });

  testWidgets('tomorrow copies today; a block is edited and deleted', (
    tester,
  ) async {
    final controller = await pumpRota(tester, today: wednesday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();
    await _addBlock(tester, duration: '1 sa');
    await _addBlock(tester, kind: 'Mola', duration: '15 dk');

    await tapVisible(tester, find.byKey(DayScheduleCard.nextDayKey));
    expect(find.text('Yarın'), findsOneWidget);
    await tester.tap(find.byTooltip('Günün akışı işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Önceki günü kopyala'));
    await tester.pumpAndSettle();
    expect(find.text('2 blok kopyalandı.'), findsOneWidget);
    expect(controller.blocksOn(thursday), hasLength(2));

    // Copying again adds nothing and says why.
    await tester.tap(find.byTooltip('Günün akışı işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Önceki günü kopyala'));
    await tester.pumpAndSettle();
    expect(controller.blocksOn(thursday), hasLength(2));

    await tapVisible(tester, find.text('Mola').first);
    expect(find.text('Bloğu düzenle'), findsOneWidget);
    await tester.tap(find.text('Bloğu sil'));
    await tester.pumpAndSettle();
    expect(find.text('Blok silindi'), findsOneWidget);
    expect(controller.blocksOn(thursday), hasLength(1));
  });

  testWidgets('a named block needs a name', (tester) async {
    await pumpRota(tester, today: wednesday);
    await tester.tap(find.text('Örnek haftayı yükle'));
    await tester.pumpAndSettle();
    await _addBlock(tester, kind: 'Diğer');
    expect(find.text('Bloğa bir ad ver.'), findsOneWidget);
  });
}
