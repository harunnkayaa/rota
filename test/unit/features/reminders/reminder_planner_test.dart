import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/features/reminders/domain/reminder_planner.dart';

import '../../../helpers/builders.dart';

const _on = ReminderSettings(enabled: true);
const _noon = 12 * 60;

ReminderCandidate _left(
  String title,
  int minutes, {
  LocalDate? date,
  bool sensitive = false,
  ReminderKind kind = ReminderKind.todayRemaining,
}) => ReminderCandidate(
  kind: kind,
  periodId: 'p-$title',
  date: date ?? monday,
  goalTitle: title,
  minutes: minutes,
  isSensitive: sensitive,
);

List<PlannedReminder> _plan(
  List<ReminderCandidate> candidates, {
  ReminderSettings settings = _on,
  int now = _noon,
}) => planReminders(
  settings: settings,
  candidates: candidates,
  today: monday,
  nowMinuteOfDay: now,
);

void main() {
  test('off by default: no reminders without the user turning them on', () {
    expect(
      _plan([_left('Proje', 90)], settings: const ReminderSettings()),
      isEmpty,
    );
  });

  test('reminds about time not yet worked, at the chosen time', () {
    final r = _plan([_left('Proje', 90)]).single;
    expect(r.candidate.minutes, 90);
    expect(r.minuteOfDay, 20 * 60);
    expect(r.date, monday);
  });

  test('nothing left → no reminder', () {
    expect(_plan([_left('Proje', 0)]), isEmpty);
  });

  test("today's reminder is dropped once its time has passed", () {
    expect(_plan([_left('Proje', 90)], now: 21 * 60), isEmpty);
    // Tomorrow's is still planned.
    expect(
      _plan([_left('Proje', 90, date: tuesday)], now: 21 * 60),
      hasLength(1),
    );
  });

  group('quiet hours', () {
    test('a reminder time inside quiet hours is not used', () {
      final late = _on.copyWith(dailyTimeMinutes: 23 * 60 + 30);
      expect(_plan([_left('Proje', 90)], settings: late), isEmpty);
    });

    test('quiet window can wrap midnight', () {
      const s = ReminderSettings(); // 23:00 → 08:00
      expect(s.isQuiet(23 * 60 + 30), isTrue);
      expect(s.isQuiet(3 * 60), isTrue);
      expect(s.isQuiet(8 * 60), isFalse);
      expect(s.isQuiet(20 * 60), isFalse);
    });

    test('a same-day window works too', () {
      final s = _on.copyWith(
        quietStartMinutes: 13 * 60,
        quietEndMinutes: 14 * 60,
      );
      expect(s.isQuiet(13 * 60 + 30), isTrue);
      expect(s.isQuiet(14 * 60), isFalse);
    });
  });

  test('daily budget keeps the goals with the most time left', () {
    final planned = _plan([
      _left('A', 30),
      _left('B', 120),
      _left('C', 60),
      _left('D', 90),
    ]);
    expect(planned.map((r) => r.candidate.goalTitle), ['B', 'D', 'C']);
  });

  test('budget counts per day', () {
    final planned = _plan([
      for (final t in ['A', 'B', 'C', 'D']) _left(t, 60),
      for (final t in ['A', 'B']) _left(t, 60, date: tuesday),
    ]);
    expect(planned.where((r) => r.date == monday), hasLength(3));
    expect(planned.where((r) => r.date == tuesday), hasLength(2));
  });

  test('the same situation twice gives one reminder', () {
    expect(_plan([_left('Proje', 90), _left('Proje', 90)]), hasLength(1));
  });

  test('sensitive goals hide their name unless the user allows it', () {
    expect(
      _plan([_left('İlaç', 10, sensitive: true)]).single.hideDetails,
      isTrue,
    );
    expect(
      _plan([
        _left('İlaç', 10, sensitive: true),
      ], settings: _on.copyWith(showSensitiveDetails: true)).single.hideDetails,
      isFalse,
    );
    expect(_plan([_left('Proje', 10)]).single.hideDetails, isFalse);
  });

  test('ids are stable and differ per situation', () {
    final a = _plan([_left('Proje', 90)]).single.id;
    final again = _plan([_left('Proje', 45)]).single.id;
    final tomorrow = _plan([_left('Proje', 90, date: tuesday)]).single.id;
    expect(a, again, reason: 'same goal & day → replaced, not duplicated');
    expect(a, isNot(tomorrow));
    expect(a, greaterThan(0));
  });

  group('block starts', () {
    ReminderCandidate block(String title, int at, {LocalDate? date}) =>
        ReminderCandidate(
          kind: ReminderKind.blockStart,
          periodId: 'block-$title',
          date: date ?? monday,
          goalTitle: title,
          minutes: 60,
          atMinute: at,
        );

    test('fire at their own time, not at the daily time', () {
      final planned = _plan([block('Proje', 14 * 60)]);
      expect(planned.single.minuteOfDay, 14 * 60);
    });

    test('quiet hours and the past still apply, one by one', () {
      expect(_plan([block('Gece', 23 * 60 + 30)]), isEmpty);
      expect(_plan([block('Sabah', 9 * 60)]), isEmpty, reason: 'already past');
      expect(_plan([block('Yarın', 9 * 60, date: tuesday)]), hasLength(1));
    });

    test('share the daily budget, and come before the daily summary', () {
      final planned = _plan([
        _left('Proje', 90),
        block('B', 16 * 60),
        block('A', 14 * 60),
      ], settings: const ReminderSettings(enabled: true, dailyBudget: 2));
      expect(planned.map((p) => p.candidate.goalTitle), ['A', 'B']);
    });

    test('moving a block gives a new reminder id', () {
      expect(
        block('Proje', 14 * 60).dedupeKey,
        isNot(block('Proje', 15 * 60).dedupeKey),
      );
    });
  });
}
