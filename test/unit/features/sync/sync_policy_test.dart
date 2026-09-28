import 'package:flutter_test/flutter_test.dart';
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
}
