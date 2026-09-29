import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/features/categories/domain/category.dart';
import 'package:rota/features/goals/domain/progress_entry.dart';
import 'package:rota/features/planning/data/planner_data.dart';
import 'package:rota/features/sync/domain/sync_policy.dart';

import '../../../helpers/builders.dart';

SyncAction _decide({
  bool dirty = false,
  String? last = 'm1',
  String? server = 'm1',
  bool localEmpty = false,
  bool serverEmpty = false,
}) => decideSync(
  localDirty: dirty,
  lastServerMarker: last,
  serverMarker: server,
  localEmpty: localEmpty,
  serverEmpty: serverEmpty,
);

void main() {
  group('after an earlier sync', () {
    test('nothing changed → nothing to do', () {
      expect(_decide(), SyncAction.none);
    });

    test('only this device changed → push', () {
      expect(_decide(dirty: true), SyncAction.push);
    });

    test('only the other device changed → pull', () {
      expect(_decide(server: 'm2'), SyncAction.pull);
    });

    test('both changed → conflict, never a silent overwrite', () {
      expect(_decide(dirty: true, server: 'm2'), SyncAction.conflict);
    });
  });

  group('first sync with this account', () {
    test('empty account → upload this device', () {
      expect(
        _decide(last: null, server: null, serverEmpty: true),
        SyncAction.push,
      );
    });

    test('empty device → download the account', () {
      expect(_decide(last: null, localEmpty: true), SyncAction.pull);
    });

    test('both have data → ask the user', () {
      expect(_decide(last: null), SyncAction.conflict);
    });

    test('both empty → nothing', () {
      expect(
        _decide(last: null, server: null, localEmpty: true, serverEmpty: true),
        SyncAction.none,
      );
    });
  });

  group('resolveConflict', () {
    final shared = weekPeriod();
    final onlyOther = weekPeriod(id: 'other-period');

    PlannerData data(List<ProgressEntry> entries, {bool withOther = false}) =>
        PlannerData(
          goals: [projectGoal()],
          periods: [shared, if (withOther) onlyOther],
          entries: entries,
        );

    test(
      'keeps the winner and adds the other side\'s work on shared goals',
      () {
        final result = resolveConflict(
          winner: data([entry(monday, 60, id: 'w1')]),
          other: data([
            entry(monday, 60, id: 'w1'), // same event on both sides
            entry(tuesday, 45, id: 'o1'),
          ]),
        );
        expect(result.data.entries.map((e) => e.id), ['w1', 'o1']);
        expect(result.unmatchedEntries, 0);
      },
    );

    test('reports work that belongs to a goal only the other side has', () {
      final result = resolveConflict(
        winner: data(const []),
        other: data([
          entry(monday, 30, id: 'o2', periodId: 'other-period'),
        ], withOther: true),
      );
      expect(result.data.entries, isEmpty);
      expect(result.unmatchedEntries, 1);
    });
  });

  group('mergeThreeWay', () {
    final category = GoalCategory(
      id: 'cat-project',
      name: 'Proje',
      iconKey: 'code',
    );
    PlannerData data({
      List<DailyAllocationLike> allocations = const [],
      int target = 600,
      bool withGoal = true,
      List<ProgressEntry> entries = const [],
    }) => PlannerData(
      categories: [category],
      goals: [if (withGoal) projectGoal()],
      periods: [if (withGoal) weekPeriod(target: target)],
      allocations: [for (final a in allocations) allocation(a.$1, a.$2)],
      entries: entries,
    );

    test('a removal on one side and an addition on the other both apply', () {
      final base = data(allocations: [(monday, 120), (tuesday, 60)]);
      final local = data(allocations: [(monday, 120)]); // Tuesday removed
      final server = data(
        allocations: [(monday, 120), (tuesday, 60), (friday, 30)],
      );
      final merged = mergeThreeWay(base: base, local: local, server: server)!;
      expect(
        {for (final a in merged.allocations) a.date: a.allocatedValue},
        {monday: 120, friday: 30},
      );
    });

    test('entries from both sides are kept once', () {
      final shared = entry(monday, 30, id: 'shared');
      final base = data(entries: [shared]);
      final local = data(
        entries: [
          shared,
          entry(monday, 15, id: 'here'),
        ],
      );
      final server = data(
        entries: [
          shared,
          entry(monday, 45, id: 'there'),
        ],
      );
      final merged = mergeThreeWay(base: base, local: local, server: server)!;
      expect(merged.entries.map((e) => e.id).toSet(), {
        'shared',
        'here',
        'there',
      });
    });

    test('the same record changed differently → null (ask the user)', () {
      expect(
        mergeThreeWay(
          base: data(),
          local: data(target: 480),
          server: data(target: 720),
        ),
        isNull,
      );
    });

    test('work logged on a goal the other side removed → null', () {
      expect(
        mergeThreeWay(
          base: data(),
          local: data(entries: [entry(monday, 30)]),
          server: data(withGoal: false),
        ),
        isNull,
      );
    });
  });
}

typedef DailyAllocationLike = (LocalDate, int);
