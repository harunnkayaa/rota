import 'dart:math';

import '../../../core/time/local_date.dart';
import '../../goals/domain/daily_allocation.dart';

/// How many minutes the user can realistically plan per day.
class CapacityModel {
  CapacityModel({
    required this.defaultDailyMinutes,
    Map<LocalDate, int> overrides = const {},
  }) : overrides = Map.unmodifiable(overrides) {
    for (final minutes in [defaultDailyMinutes, ...overrides.values]) {
      if (minutes < 0 || minutes > Duration.minutesPerDay) {
        throw ArgumentError.value(minutes, 'minutes', 'Must be 0..1440');
      }
    }
  }

  final int defaultDailyMinutes;

  /// Per-date exceptions: a class day, travel, an appointment.
  final Map<LocalDate, int> overrides;

  int capacityOn(LocalDate date) => overrides[date] ?? defaultDailyMinutes;
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
