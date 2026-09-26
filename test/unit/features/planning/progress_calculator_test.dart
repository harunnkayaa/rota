import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/goals/domain/progress_entry.dart';
import 'package:rota/features/planning/domain/progress_calculator.dart';

import '../../../helpers/builders.dart';

void main() {
  group('the core example (CLAUDE.md §1)', () {
    test('90 min on Monday is 90/120 daily and 90/600 weekly', () {
      final period = weekPeriod();
      final entries = [entry(monday, 90)];

      expect(dailyProgress(period, monday, entries), 90);
      expect(periodProgress(period, entries), 90);
      expect(remainingTarget(period, entries), 510);
    });

    test('weekly total equals the sum of the daily totals', () {
      final period = weekPeriod();
      final entries = [
        entry(monday, 60),
        entry(monday, 30),
        entry(tuesday, 45),
      ];
      final dailySum =
          dailyProgress(period, monday, entries) +
          dailyProgress(period, tuesday, entries);

      expect(periodProgress(period, entries), dailySum);
      expect(dailySum, 135);
    });
  });

  group('no double counting', () {
    test('the same entry delivered twice counts once (offline retry)', () {
      final period = weekPeriod();
      final e = entry(monday, 90, id: 'same-id');

      expect(periodProgress(period, [e, e]), 90);
      expect(dailyProgress(period, monday, [e, e]), 90);
    });

    test('entries of another period are ignored', () {
      final period = weekPeriod();
      final entries = [entry(monday, 90), entry(monday, 50, periodId: 'x')];

      expect(periodProgress(period, entries), 90);
    });
  });

  group('allocations', () {
    test('unallocated shows what is not yet spread over days', () {
      final period = weekPeriod();
      final allocations = [allocation(monday, 120), allocation(tuesday, 120)];

      expect(allocatedTotal(period, allocations), 240);
      expect(unallocatedAmount(period, allocations), 360);
    });
  });

  group('validateNewEntry', () {
    test('rejects a date outside the period', () {
      expect(
        () => validateNewEntry(
          weekPeriod(),
          entry(sunday.addDays(1), 30),
          const [],
        ),
        throwsA(
          isA<ProgressRejectedException>().having(
            (e) => e.reason,
            'reason',
            ProgressRejection.dateOutsidePeriod,
          ),
        ),
      );
    });

    test('rejects a closed period', () {
      final closed = weekPeriod().close(DateTime.utc(2026, 10, 5));
      expect(
        () => validateNewEntry(closed, entry(monday, 30), const []),
        throwsA(isA<ProgressRejectedException>()),
      );
    });

    test('an adjustment cannot push the total below zero', () {
      final period = weekPeriod();
      final existing = [entry(monday, 30)];
      final correction = entry(monday, -40, source: ProgressSource.adjustment);
      expect(
        () => validateNewEntry(period, correction, existing),
        throwsA(
          isA<ProgressRejectedException>().having(
            (e) => e.reason,
            'reason',
            ProgressRejection.totalWouldBeNegative,
          ),
        ),
      );
    });

    test('a valid adjustment corrects the total without deleting', () {
      final period = weekPeriod();
      final existing = [entry(monday, 90)];
      final correction = entry(monday, -30, source: ProgressSource.adjustment);
      validateNewEntry(period, correction, existing);

      expect(periodProgress(period, [...existing, correction]), 60);
    });
  });

  group('target change', () {
    test('lowering the target keeps progress and updates remaining', () {
      final period = weekPeriod();
      final entries = [entry(monday, 90)];
      final lowered = period.withTarget(480);

      expect(periodProgress(lowered, entries), 90);
      expect(remainingTarget(lowered, entries), 390);
    });

    test('a closed period target cannot change', () {
      final closed = weekPeriod().close(DateTime.utc(2026, 10, 5));
      expect(() => closed.withTarget(300), throwsStateError);
    });
  });
}
