import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/features/goals/domain/daily_allocation.dart';
import 'package:rota/features/planning/domain/plan_editing.dart';
import 'package:rota/features/planning/domain/progress_calculator.dart';
import 'package:rota/features/planning/domain/redistribution.dart';

import '../../../helpers/builders.dart';

void main() {
  var ids = 0;
  String newId() => 'new-${ids++}';

  test("the user's scenario: raising Tuesday covers Monday's shortfall", () {
    // Weekly target 600: Mon 240, Tue 120, Wed 240. Monday only 180 done.
    final period = weekPeriod();
    final allocations = [
      allocation(monday, 240),
      allocation(tuesday, 120),
      allocation(wednesday, 240),
    ];
    final entries = [entry(monday, 180)];

    int debt(List<DailyAllocation> a) => unplannedRemaining(
      period: period,
      allocations: a,
      entries: entries,
      today: tuesday,
    );

    expect(debt(allocations), 60);

    final edited = applyPlanChanges(
      period: period,
      allocations: allocations,
      changes: {tuesday: 180},
      today: tuesday,
      newId: newId,
    );

    expect(debt(edited), 0);
    expect(allocatedTotal(period, edited), 660);
  });

  test('adds a day, changes a day, removes a day with 0', () {
    final result = applyPlanChanges(
      period: weekPeriod(),
      allocations: [allocation(tuesday, 120), allocation(wednesday, 60)],
      changes: {tuesday: 90, wednesday: 0, friday: 45},
      today: tuesday,
      newId: newId,
    );

    final byDate = {for (final a in result) a.date: a.allocatedValue};
    expect(byDate, {tuesday: 90, friday: 45});
  });

  test('an edited day keeps its id (an update, not a new record)', () {
    final original = allocation(thursday, 60);
    final result = applyPlanChanges(
      period: weekPeriod(),
      allocations: [original],
      changes: {thursday: 120},
      today: monday,
      newId: newId,
    );
    expect(result.single.id, original.id);
  });

  test('other goals are never touched', () {
    final other = allocation(tuesday, 30, periodId: 'other');
    final result = applyPlanChanges(
      period: weekPeriod(),
      allocations: [other],
      changes: {tuesday: 120},
      today: monday,
      newId: newId,
    );
    expect(result, contains(other));
    expect(result, hasLength(2));
  });

  group('refused changes leave the plan untouched', () {
    void expectRejected(PlanEditRejection reason, Map<LocalDate, int> changes) {
      expect(
        () => applyPlanChanges(
          period: weekPeriod(),
          allocations: const [],
          changes: changes,
          today: wednesday,
          newId: newId,
        ),
        throwsA(
          isA<PlanEditRejectedException>().having(
            (e) => e.reason,
            'reason',
            reason,
          ),
        ),
      );
    }

    test('past days are history', () {
      expectRejected(PlanEditRejection.dateInPast, {monday: 60});
    });

    test('days outside the week', () {
      expectRejected(PlanEditRejection.dateOutsidePeriod, {
        sunday.addDays(1): 60,
      });
    });

    test('negative or more than a day', () {
      expectRejected(PlanEditRejection.invalidAmount, {thursday: -1});
      expectRejected(PlanEditRejection.invalidAmount, {thursday: 1441});
    });

    test('closed periods', () {
      expect(
        () => applyPlanChanges(
          period: weekPeriod().close(DateTime.utc(2026, 10, 5)),
          allocations: const [],
          changes: {thursday: 60},
          today: wednesday,
          newId: newId,
        ),
        throwsA(isA<PlanEditRejectedException>()),
      );
    });
  });
}
