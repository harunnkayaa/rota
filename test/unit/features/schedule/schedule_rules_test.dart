import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/schedule/domain/schedule_rules.dart';
import 'package:rota/features/schedule/domain/time_block.dart';

import '../../../helpers/builders.dart';

const _h = Duration.minutesPerHour;

TimeBlock _goal(String id, int start, int end, {String period = 'period-1'}) =>
    TimeBlock(
      id: id,
      date: monday,
      startMinute: start,
      endMinute: end,
      kind: TimeBlockKind.goal,
      goalPeriodId: period,
    );

TimeBlock _rest(String id, int start, int end) => TimeBlock(
  id: id,
  date: monday,
  startMinute: start,
  endMinute: end,
  kind: TimeBlockKind.rest,
);

void main() {
  group('TimeBlock', () {
    test('09:00–11:00 is two hours', () {
      expect(_goal('a', 9 * _h, 11 * _h).minutes, 120);
    });

    test('never runs backwards or into the next day', () {
      expect(() => _goal('a', 11 * _h, 9 * _h), throwsArgumentError);
      expect(() => _goal('a', 10 * _h, 10 * _h), throwsArgumentError);
      expect(() => _goal('a', 23 * _h, 25 * _h), throwsArgumentError);
      // Ending exactly at midnight is fine.
      expect(_goal('a', 23 * _h, 24 * _h).minutes, 60);
    });

    test('goal blocks point to a goal; others need no goal', () {
      expect(
        () => TimeBlock(
          id: 'a',
          date: monday,
          startMinute: 0,
          endMinute: 30,
          kind: TimeBlockKind.goal,
        ),
        throwsArgumentError,
      );
      expect(
        () => TimeBlock(
          id: 'a',
          date: monday,
          startMinute: 0,
          endMinute: 30,
          kind: TimeBlockKind.other,
          title: '  ',
        ),
        throwsArgumentError,
        reason: '"other" needs a real title',
      );
      expect(_rest('a', 0, 15).title, isNull, reason: 'a break needs none');
    });

    test('touching blocks do not overlap; shared minutes do', () {
      final work = _goal('a', 9 * _h, 11 * _h);
      expect(work.overlaps(_rest('b', 11 * _h, 11 * _h + 15)), isFalse);
      expect(work.overlaps(_rest('b', 10 * _h + 59, 11 * _h + 15)), isTrue);
      expect(
        work.overlaps(_rest('b', 9 * _h, 10 * _h).copyWith(date: tuesday)),
        isFalse,
        reason: 'another day',
      );
    });
  });

  test('a day is listed by start time', () {
    final day = blocksOnDay([
      _rest('b', 11 * _h, 11 * _h + 15),
      _goal('a', 9 * _h, 11 * _h),
      _goal('c', 9 * _h, 10 * _h).copyWith(date: tuesday),
    ], monday);
    expect(day.map((b) => b.id), ['a', 'b']);
  });

  test('an edited block does not clash with its old self', () {
    final work = _goal('a', 9 * _h, 11 * _h);
    expect(firstOverlap([work], work.copyWith(endMinute: 12 * _h)), isNull);
    expect(firstOverlap([work], _rest('b', 10 * _h, 10 * _h + 15))?.id, 'a');
  });

  test('scheduled minutes count one goal on one day', () {
    final blocks = [
      _goal('a', 9 * _h, 11 * _h),
      _goal('b', 14 * _h, 14 * _h + 30),
      _goal('c', 16 * _h, 17 * _h, period: 'period-2'),
      _goal('d', 9 * _h, 10 * _h).copyWith(date: tuesday),
    ];
    expect(scheduledMinutes(blocks, periodId: 'period-1', date: monday), 150);
  });

  group('suggestedStart', () {
    test('right after the last block', () {
      expect(suggestedStart([_goal('a', 9 * _h, 11 * _h)]), 11 * _h);
    });

    test('empty today: the next half hour; another day: 09:00', () {
      expect(suggestedStart(const [], nowMinute: 14 * _h + 10), 14 * _h + 30);
      expect(suggestedStart(const [], nowMinute: 14 * _h), 14 * _h);
      expect(suggestedStart(const []), 9 * _h);
    });

    test('never past the last half hour of the day', () {
      expect(suggestedStart(const [], nowMinute: 23 * _h + 50), 23 * _h + 30);
    });
  });

  group('copyDay', () {
    var n = 0;
    String newId() => 'copy-${n++}';

    test('copies breaks as they are and goals onto their new week', () {
      final result = copyDay(
        blocks: [
          _goal('a', 9 * _h, 11 * _h),
          _rest('b', 11 * _h, 11 * _h + 15),
        ],
        from: monday,
        to: tuesday,
        newId: newId,
        periodOnTarget: (id) => '$id-next',
      );
      expect(result.skipped, 0);
      expect(result.added.map((b) => b.date).toSet(), {tuesday});
      expect(result.added.first.goalPeriodId, 'period-1-next');
      expect(result.added.last.kind, TimeBlockKind.rest);
    });

    test(
      'the target day keeps its own blocks; clashing copies are skipped',
      () {
        final existing = _rest(
          'x',
          10 * _h,
          10 * _h + 30,
        ).copyWith(date: tuesday);
        final result = copyDay(
          blocks: [
            _goal('a', 9 * _h, 11 * _h),
            _rest('b', 11 * _h, 11 * _h + 15),
            existing,
          ],
          from: monday,
          to: tuesday,
          newId: newId,
          periodOnTarget: (id) => id,
        );
        expect(result.added.single.kind, TimeBlockKind.rest);
        expect(result.skipped, 1);
      },
    );

    test('a goal without a week on the target day is skipped', () {
      final result = copyDay(
        blocks: [_goal('a', 9 * _h, 11 * _h)],
        from: monday,
        to: tuesday,
        newId: newId,
        periodOnTarget: (_) => null,
      );
      expect(result.added, isEmpty);
      expect(result.skipped, 1);
    });
  });
}
