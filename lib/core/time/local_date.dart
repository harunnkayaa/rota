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
    // DateTime.utc normalizes overflow (Feb 30 -> Mar 2). If the normalized
    // parts differ from the input, the input was not a real calendar day.
    final utc = DateTime.utc(year, month, day);
    if (utc.year != year || utc.month != month || utc.day != day) {
      throw ArgumentError('Invalid calendar date: $year-$month-$day');
    }
    return LocalDate._(year, month, day);
  }

  /// Takes the calendar fields of [dateTime] as they are.
  ///
  /// The caller decides which timezone [dateTime] is expressed in; this
  /// constructor never converts.
  LocalDate.fromDateTime(DateTime dateTime)
    : this._(dateTime.year, dateTime.month, dateTime.day);

  /// Parses the ISO-8601 form written by [toString] ("2026-09-28").
  /// Throws [FormatException] for anything else, including impossible dates.
  factory LocalDate.parse(String value) {
    final match = _isoPattern.firstMatch(value);
    if (match == null) throw FormatException('Not a yyyy-MM-dd date', value);
    try {
      return LocalDate(
        int.parse(match[1]!),
        int.parse(match[2]!),
        int.parse(match[3]!),
      );
    } on ArgumentError {
      throw FormatException('Not a real calendar date', value);
    }
  }

  const LocalDate._(this.year, this.month, this.day);

  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// ISO weekday: 1 = Monday ... 7 = Sunday (same as [DateTime.monday] etc.).
  int get weekday => _toUtc().weekday;

  /// Returns the date [days] calendar days later (negative goes back).
  LocalDate addDays(int days) {
    // UTC has no DST, so every day is exactly 24 hours here.
    final result = _toUtc().add(Duration(days: days));
    return LocalDate._(result.year, result.month, result.day);
  }

  /// Number of calendar days from this date to [other].
  /// Negative when [other] is earlier.
  int daysUntil(LocalDate other) => other._toUtc().difference(_toUtc()).inDays;

  DateTime _toUtc() => DateTime.utc(year, month, day);

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
