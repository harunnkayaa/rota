import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/local_date.dart';
import 'package:rota/core/time/period_range.dart';

void main() {
  group('PeriodRange construction', () {
    test('rejects empty and reversed ranges', () {
      final day = LocalDate(2026, 9, 28);
      expect(() => PeriodRange(day, day), throwsArgumentError);
      expect(() => PeriodRange(day, day.addDays(-1)), throwsArgumentError);
    });

    test('accepts a one-day range', () {
      final day = LocalDate(2026, 9, 28);
      expect(PeriodRange(day, day.addDays(1)).lengthInDays, 1);
    });
  });

  group('contains (half-open semantics)', () {
    late PeriodRange week;
    setUp(() {
      week = PeriodRange(LocalDate(2026, 9, 28), LocalDate(2026, 10, 5));
    });

    test('includes the start day', () {
      expect(week.contains(LocalDate(2026, 9, 28)), isTrue);
    });

    test('includes the last day (Sunday)', () {
      expect(week.contains(LocalDate(2026, 10, 4)), isTrue);
    });

    test('excludes endExclusive — it belongs to the next period', () {
      expect(week.contains(LocalDate(2026, 10, 5)), isFalse);
    });

    test('excludes the day before start', () {
      expect(week.contains(LocalDate(2026, 9, 27)), isFalse);
    });
  });

  group('calendarWeekContaining — Monday start (default)', () {
    PeriodRange mondayWeek(LocalDate d) =>
        PeriodRange.calendarWeekContaining(d, weekStartDay: DateTime.monday);

    late PeriodRange expected;
    setUp(() {
      expected = PeriodRange(LocalDate(2026, 9, 28), LocalDate(2026, 10, 5));
    });

    test('from a Wednesday', () {
      expect(mondayWeek(LocalDate(2026, 9, 30)), expected);
    });

    test('from the Monday itself', () {
      expect(mondayWeek(LocalDate(2026, 9, 28)), expected);
    });

    test('from the Sunday (last day of the week)', () {
      expect(mondayWeek(LocalDate(2026, 10, 4)), expected);
    });

    test('across a year boundary', () {
      expect(
        mondayWeek(LocalDate(2026, 12, 31)),
        PeriodRange(LocalDate(2026, 12, 28), LocalDate(2027, 1, 4)),
      );
    });
  });

  group('calendarWeekContaining — custom week start', () {
    test('Sunday-start week from a Wednesday', () {
      expect(
        PeriodRange.calendarWeekContaining(
          LocalDate(2026, 9, 30),
          weekStartDay: DateTime.sunday,
        ),
        PeriodRange(LocalDate(2026, 9, 27), LocalDate(2026, 10, 4)),
      );
    });

    test('Saturday-start week from the Saturday itself', () {
      expect(
        PeriodRange.calendarWeekContaining(
          LocalDate(2026, 9, 26),
          weekStartDay: DateTime.saturday,
        ),
        PeriodRange(LocalDate(2026, 9, 26), LocalDate(2026, 10, 3)),
      );
    });

    test('rejects week start outside 1..7', () {
      final date = LocalDate(2026, 9, 30);
      expect(
        () => PeriodRange.calendarWeekContaining(date, weekStartDay: 0),
        throwsArgumentError,
      );
      expect(
        () => PeriodRange.calendarWeekContaining(date, weekStartDay: 8),
        throwsArgumentError,
      );
    });
  });

  group('rolling7Days', () {
    // CLAUDE.md §8.2: a period started on Tuesday ends before next Tuesday.
    late PeriodRange rolling;
    setUp(() {
      rolling = PeriodRange.rolling7Days(LocalDate(2026, 9, 29));
    });

    test('starting Tuesday ends before the next Tuesday', () {
      expect(rolling.endExclusive, LocalDate(2026, 10, 6));
      expect(rolling.contains(LocalDate(2026, 10, 5)), isTrue);
      expect(rolling.contains(LocalDate(2026, 10, 6)), isFalse);
    });

    test('is always exactly 7 days', () {
      expect(rolling.lengthInDays, 7);
    });
  });

  group('days', () {
    test('lists every day in order, excluding endExclusive', () {
      final range = PeriodRange.rolling7Days(LocalDate(2026, 12, 29));
      expect(range.days.toList(), [
        LocalDate(2026, 12, 29),
        LocalDate(2026, 12, 30),
        LocalDate(2026, 12, 31),
        LocalDate(2027, 1, 1),
        LocalDate(2027, 1, 2),
        LocalDate(2027, 1, 3),
        LocalDate(2027, 1, 4),
      ]);
    });

    test('endInclusive is for display only and is the last listed day', () {
      final range = PeriodRange.rolling7Days(LocalDate(2026, 9, 29));
      expect(range.endInclusive, range.days.last);
    });
  });

  group('back-to-back periods', () {
    test('consecutive weeks neither overlap nor leave a gap', () {
      final thisWeek = PeriodRange.calendarWeekContaining(
        LocalDate(2026, 9, 30),
        weekStartDay: DateTime.monday,
      );
      final nextWeek = PeriodRange.calendarWeekContaining(
        thisWeek.endExclusive,
        weekStartDay: DateTime.monday,
      );
      expect(nextWeek.start, thisWeek.endExclusive);
      final boundary = thisWeek.endExclusive;
      expect(
        thisWeek.contains(boundary) && nextWeek.contains(boundary),
        isFalse,
      );
    });
  });
}
