import 'local_date.dart';

/// A half-open range of calendar days: [start, endExclusive).
///
/// "Monday to next Monday" contains Monday..Sunday; the next Monday belongs to
/// the next period. Half-open ranges never overlap and never leave gaps when
/// placed back to back, so no day can be counted twice.
class PeriodRange {
  /// Throws [ArgumentError] unless [start] is strictly before [endExclusive].
  factory PeriodRange(LocalDate start, LocalDate endExclusive) {
    if (!start.isBefore(endExclusive)) {
      throw ArgumentError(
        'Period start ($start) must be before end '
        '($endExclusive).',
      );
    }
    return PeriodRange._(start, endExclusive);
  }

  /// The calendar week that contains [date].
  ///
  /// [weekStartDay] is an ISO weekday (1 = Monday ... 7 = Sunday).
  /// Throws [ArgumentError] if it is outside 1..7.
  factory PeriodRange.calendarWeekContaining(
    LocalDate date, {
    required int weekStartDay,
  }) {
    if (weekStartDay < DateTime.monday || weekStartDay > DateTime.sunday) {
      throw ArgumentError.value(weekStartDay, 'weekStartDay', 'Must be 1..7');
    }
    // Days since the most recent week start. Adding 7 before modulo keeps
    // the value non-negative (e.g. Wed=3, start Sun=7 -> (3-7+7)%7 = 3).
    final daysBack = (date.weekday - weekStartDay + daysPerWeek) % daysPerWeek;
    final start = date.addDays(-daysBack);
    return PeriodRange(start, start.addDays(daysPerWeek));
  }

  /// Seven days starting on [start], whatever weekday that is.
  factory PeriodRange.rolling7Days(LocalDate start) {
    return PeriodRange(start, start.addDays(daysPerWeek));
  }

  const PeriodRange._(this.start, this.endExclusive);

  static const int daysPerWeek = 7;

  final LocalDate start;
  final LocalDate endExclusive;

  /// Last day that belongs to the range; for user-facing display only.
  LocalDate get endInclusive => endExclusive.addDays(-1);

  int get lengthInDays => start.daysUntil(endExclusive);

  /// [start] is included, [endExclusive] is not.
  bool contains(LocalDate date) =>
      !date.isBefore(start) && date.isBefore(endExclusive);

  /// Every day in the range, in order.
  Iterable<LocalDate> get days =>
      Iterable.generate(lengthInDays, start.addDays);

  @override
  bool operator ==(Object other) =>
      other is PeriodRange &&
      other.start == start &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(start, endExclusive);

  @override
  String toString() => '[$start, $endExclusive)';
}
