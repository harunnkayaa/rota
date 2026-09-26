import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/time/local_date.dart';

void main() {
  group('LocalDate construction', () {
    test('accepts a valid date', () {
      final date = LocalDate(2026, 9, 28);
      expect([date.year, date.month, date.day], [2026, 9, 28]);
    });

    test('rejects impossible dates instead of silently rolling over', () {
      // DateTime(2026, 2, 30) would quietly become March 2 — a planning bug.
      expect(() => LocalDate(2026, 2, 30), throwsArgumentError);
      expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
      expect(() => LocalDate(2026, 0, 10), throwsArgumentError);
      expect(() => LocalDate(2026, 4, 31), throwsArgumentError);
    });

    test('knows leap years', () {
      expect(LocalDate(2028, 2, 29).day, 29);
      expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
    });
  });

  group('weekday', () {
    test('uses ISO numbering (Monday = 1, Sunday = 7)', () {
      expect(LocalDate(2026, 9, 28).weekday, DateTime.monday);
      expect(LocalDate(2026, 9, 30).weekday, DateTime.wednesday);
      expect(LocalDate(2026, 10, 4).weekday, DateTime.sunday);
    });
  });

  group('addDays', () {
    test('crosses month and year boundaries', () {
      expect(LocalDate(2026, 9, 30).addDays(1), LocalDate(2026, 10, 1));
      expect(LocalDate(2026, 12, 28).addDays(7), LocalDate(2027, 1, 4));
    });

    test('goes backwards with negative values', () {
      expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
      expect(LocalDate(2028, 3, 1).addDays(-1), LocalDate(2028, 2, 29));
    });

    test('is unaffected by the EU daylight saving switch (2026-03-29)', () {
      expect(LocalDate(2026, 3, 28).addDays(1), LocalDate(2026, 3, 29));
      expect(LocalDate(2026, 3, 29).addDays(1), LocalDate(2026, 3, 30));
    });

    test('zero returns an equal date', () {
      expect(LocalDate(2026, 9, 28).addDays(0), LocalDate(2026, 9, 28));
    });
  });

  group('daysUntil', () {
    test('counts calendar days, including across DST', () {
      expect(LocalDate(2026, 3, 1).daysUntil(LocalDate(2026, 4, 1)), 31);
      expect(LocalDate(2026, 10, 1).daysUntil(LocalDate(2026, 11, 1)), 31);
    });

    test('is negative when the other date is earlier', () {
      expect(LocalDate(2026, 9, 28).daysUntil(LocalDate(2026, 9, 21)), -7);
    });

    test('is the inverse of addDays', () {
      final start = LocalDate(2026, 12, 20);
      expect(start.daysUntil(start.addDays(45)), 45);
    });
  });

  group('equality and ordering', () {
    test('equal values are equal and hash the same', () {
      expect(LocalDate(2026, 9, 28), LocalDate(2026, 9, 28));
      expect(LocalDate(2026, 9, 28).hashCode, LocalDate(2026, 9, 28).hashCode);
    });

    test('orders by year, then month, then day', () {
      expect(LocalDate(2026, 12, 31).isBefore(LocalDate(2027, 1, 1)), isTrue);
      expect(LocalDate(2026, 10, 1).isAfter(LocalDate(2026, 9, 30)), isTrue);
    });

    test('prints as ISO-8601', () {
      expect(LocalDate(2026, 3, 5).toString(), '2026-03-05');
    });
  });
}
