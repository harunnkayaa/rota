/// A calendar day with no time-of-day and no timezone (e.g. "2026-09-28").
///
/// Why not [DateTime]? A local `DateTime(2026, 3, 29)` is bound to the device
/// timezone; across a DST switch two consecutive midnights can be 23 hours
/// apart and `difference().inDays` returns the wrong answer. A [LocalDate]
/// only means "this day on the user's calendar". Converting a UTC instant into
/// a [LocalDate] is the job of the time service, not this class.
class LocalDate implements Comparable<LocalDate> {
  /// Creates a validated date.
  ///
  /// Throws [ArgumentError] for impossible dates such as 2026-02-30 or
  /// month 13.
  factory LocalDate(int year, int month, int day) {
    // TODO(harun): validate and return LocalDate._(year, month, day).
    // Hint: DateTime.utc normalizes overflow (Feb 30 -> Mar 2). If the
    // normalized parts differ from the input, the input was invalid.
    throw UnimplementedError();
  }

  const LocalDate._(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  /// ISO weekday: 1 = Monday ... 7 = Sunday (same as [DateTime.monday] etc.).
  int get weekday {
    // TODO(harun): implement.
    throw UnimplementedError();
  }

  /// Returns the date [days] calendar days later (negative goes back).
  LocalDate addDays(int days) {
    // TODO(harun): implement. Do the arithmetic in UTC so DST can't interfere.
    throw UnimplementedError();
  }

  /// Number of calendar days from this date to [other].
  /// Negative when [other] is earlier.
  int daysUntil(LocalDate other) {
    // TODO(harun): implement.
    throw UnimplementedError();
  }

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// ISO-8601 format: yyyy-MM-dd.
  @override
  String toString() {
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '${year.toString().padLeft(4, '0')}-$mm-$dd';
  }
}
