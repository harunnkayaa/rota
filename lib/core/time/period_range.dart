import 'local_date.dart';

/// A half-open range of calendar days: [start, endExclusive).
///
/// "Monday to next Monday" contains Monday..Sunday; the next Monday belongs to
/// the next period. Half-open ranges never overlap and never leave gaps when
/// placed back to back, so no day can be counted twice.
class PeriodRange {
  /// Throws [ArgumentError] unless [start] is strictly before [endExclusive].
  factory PeriodRange(LocalDate start, LocalDate endExclusive) {
    // TODO(harun): validate and return PeriodRange._(start, endExclusive).
    throw UnimplementedError();
  }

  /// The calendar week that contains [date].
  ///
  /// [weekStartDay] is an ISO weekday (1 = Monday ... 7 = Sunday).
  /// Throws [ArgumentError] if it is outside 1..7.
  factory PeriodRange.calendarWeekContaining(
    LocalDate date, {
    required int weekStartDay,
  }) {
    // TODO(harun): implement. Key question: how many days back from [date]
    // is the most recent [weekStartDay]? (Hint: modulo 7.)
    throw UnimplementedError();
  }

  /// Seven days starting on [start], whatever weekday that is.
  factory PeriodRange.rolling7Days(LocalDate start) {
    // TODO(harun): implement.
    throw UnimplementedError();
  }

  const PeriodRange._(this.start, this.endExclusive);

  static const int daysPerWeek = 7;

  final LocalDate start;
  final LocalDate endExclusive;

  /// Last day that belongs to the range; for user-facing display only.
  LocalDate get endInclusive => endExclusive.addDays(-1);

  int get lengthInDays {
    // TODO(harun): implement.
    throw UnimplementedError();
  }

  bool contains(LocalDate date) {
    // TODO(harun): implement. start is included, endExclusive is not.
    throw UnimplementedError();
  }

  /// Every day in the range, in order.
  Iterable<LocalDate> get days {
    // TODO(harun): implement.
    throw UnimplementedError();
  }

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
