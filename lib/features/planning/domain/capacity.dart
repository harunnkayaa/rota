import 'dart:math';

import '../../../core/time/local_date.dart';
import '../../goals/domain/daily_allocation.dart';

/// How many minutes the user can realistically plan per day.
class CapacityModel {
  CapacityModel({
    required this.defaultDailyMinutes,
    Map<int, int> weekdayMinutes = const {},
    Map<LocalDate, int> overrides = const {},
  }) : weekdayMinutes = Map.unmodifiable(weekdayMinutes),
       overrides = Map.unmodifiable(overrides) {
    for (final minutes in [
      defaultDailyMinutes,
      ...weekdayMinutes.values,
      ...overrides.values,
    ]) {
      if (minutes < 0 || minutes > Duration.minutesPerDay) {
        throw ArgumentError.value(minutes, 'minutes', 'Must be 0..1440');
      }
    }
  }

  final int defaultDailyMinutes;

  /// Regular weekly rhythm by ISO weekday: "Saturdays I have 6 hours".
  final Map<int, int> weekdayMinutes;

  /// Per-date exceptions: a class day, travel, an appointment.
  final Map<LocalDate, int> overrides;

  /// Most specific rule wins: date, then weekday, then the default.
  int capacityOn(LocalDate date) =>
      overrides[date] ?? weekdayMinutes[date.weekday] ?? defaultDailyMinutes;
}

/// Planned minutes vs. capacity for one day.
class CapacityCheck {
  const CapacityCheck({
    required this.date,
    required this.capacity,
    required this.planned,
  });

  final LocalDate date;
  final int capacity;
  final int planned;

  int get free => max(0, capacity - planned);
  int get overBy => max(0, planned - capacity);
  bool get isOver => overBy > 0;
}

/// [durationAllocations] must contain only allocations of time-based goals;
/// pages or counts do not consume minutes.
CapacityCheck checkCapacity(
  LocalDate date,
  CapacityModel model,
  Iterable<DailyAllocation> durationAllocations,
) {
  final planned = durationAllocations
      .where((a) => a.date == date)
      .fold(0, (sum, a) => sum + a.allocatedValue);
  return CapacityCheck(
    date: date,
    capacity: model.capacityOn(date),
    planned: planned,
  );
}
