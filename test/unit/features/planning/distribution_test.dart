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

  group('distributeEvenly', () {
    test('maps each chosen day to its share', () {
      expect(
        distributeEvenly(600, [monday, tuesday, wednesday, thursday, friday]),
        {monday: 120, tuesday: 120, wednesday: 120, thursday: 120, friday: 120},
      );
    });
  });
}
