import '../../../core/time/local_date.dart';

/// The part of a period's target planned for one day: "Pazartesi 120 dk".
///
/// A period has at most one allocation per date. Progress for that day is
/// derived from entries with the same local date, not stored here.
class DailyAllocation {
  DailyAllocation({
    required this.id,
    required this.goalPeriodId,
    required this.date,
    required this.allocatedValue,
  }) {
    if (allocatedValue < 0) {
      throw ArgumentError.value(
        allocatedValue,
        'allocatedValue',
        'Must be >= 0',
      );
    }
  }

  final String id;
  final String goalPeriodId;
  final LocalDate date;
  final int allocatedValue;

  DailyAllocation withValue(int value) => DailyAllocation(
    id: id,
    goalPeriodId: goalPeriodId,
    date: date,
    allocatedValue: value,
  );
}
