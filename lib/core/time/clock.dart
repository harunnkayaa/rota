import 'local_date.dart';

/// The only place the app asks "what time is it?".
///
/// Domain code never calls [DateTime.now] directly; it receives a [Clock], so
/// tests can pin "today" to any date (e.g. a Saturday with missed Mondays).
abstract interface class Clock {
  DateTime nowUtc();

  /// The user's current calendar day.
  LocalDate today();

  /// Minutes since the user's local midnight (0..1439).
  int minuteOfDay();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  // Phase 1 uses the device timezone. The profile timezone (IANA name,
  // default Europe/Istanbul) replaces this when profiles arrive in Phase 2.
  @override
  LocalDate today() => LocalDate.fromDateTime(DateTime.now());

  @override
  int minuteOfDay() {
    final now = DateTime.now();
    return now.hour * Duration.minutesPerHour + now.minute;
  }
}
