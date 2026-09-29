import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/planning/domain/distribution.dart';

import '../../../helpers/builders.dart';

void main() {
  group('splitProportionally', () {
    test('divides evenly when possible', () {
      expect(splitProportionally(300, [1, 1, 1]), [100, 100, 100]);
    });

    test('never loses a minute to rounding, and is deterministic', () {
      expect(splitProportionally(100, [1, 1, 1]), [34, 33, 33]);
      expect(splitProportionally(600, List.filled(7, 1)), [
        86,
        86,
        86,
        86,
        86,
        85,
        85,
      ]);
    });

    test('weights by free capacity', () {
      expect(splitProportionally(300, [60, 120, 180]), [50, 100, 150]);
    });

    test('zero weights get nothing', () {
      expect(splitProportionally(90, [0, 1, 2]), [0, 30, 60]);
      expect(splitProportionally(90, [0, 0]), [0, 0]);
    });
  });

  group('splitWithCaps', () {
    test('a full day passes its overflow to the others', () {
      expect(splitWithCaps(300, [1, 1, 1], [50, 200, 200]), [50, 125, 125]);
    });

    test('returns less than total when caps are too small', () {
      final result = splitWithCaps(360, [1, 1, 1], [100, 100, 100]);
      expect(result, [100, 100, 100]);
      expect(result.fold(0, (a, b) => a + b), 300);
    });

    test('null cap means unlimited', () {
      expect(splitWithCaps(100, [1, 1], [null, 20]), [80, 20]);
    });
  });

  group('splitWithCaps in 5-minute blocks', () {
    test('30 minutes over four days: readable steps, not 8/8/7/7', () {
      expect(splitWithCaps(30, [1, 1, 1, 1], List.filled(4, null), block: 5), [
        10,
        10,
        5,
        5,
      ]);
    });

    test('a remainder under one block goes to a single day', () {
      expect(splitWithCaps(32, [1, 1, 1, 1], List.filled(4, null), block: 5), [
        12,
        10,
        5,
        5,
      ]);
    });

    test('blocks never make a plan less feasible', () {
      // 7 free minutes on each of two days: no 15-minute block fits, but
      // all 14 minutes still find a place.
      expect(splitWithCaps(14, [1, 1], [7, 7], block: 15), [7, 7]);
    });

    test('capacity weighting and caps still apply', () {
      expect(splitWithCaps(90, [30, 60], [30, 60], block: 5), [30, 60]);
    });
  });

  group('distributeEvenly', () {
    test('maps each chosen day to its share', () {
      expect(
        distributeEvenly(600, [monday, tuesday, wednesday, thursday, friday]),
        {monday: 120, tuesday: 120, wednesday: 120, thursday: 120, friday: 120},
      );
    });

    test('a week split in blocks keeps the total and 5-minute steps', () {
      final days = [for (var i = 0; i < 7; i++) monday.addDays(i)];
      final plan = distributeEvenly(600, days, block: 5);
      expect(plan.values.fold(0, (a, b) => a + b), 600);
      expect(plan.values.every((v) => v % 5 == 0), isTrue);
      expect(plan.values.toList(), [90, 85, 85, 85, 85, 85, 85]);
    });
  });
}
