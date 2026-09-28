import '../../reminders/domain/reminder_planner.dart';

/// The user's planning preferences (CLAUDE.md §13.7).
class PlannerSettings {
  PlannerSettings({
    this.dailyCapacityMinutes = defaultDailyCapacityMinutes,
    Map<int, int> weekdayCapacityMinutes = const {},
    this.weekStartDay = DateTime.monday,
    this.reminders = const ReminderSettings(),
  }) : weekdayCapacityMinutes = Map.unmodifiable(weekdayCapacityMinutes) {
    for (final minutes in [
      dailyCapacityMinutes,
      ...weekdayCapacityMinutes.values,
    ]) {
      if (minutes < 0 || minutes > Duration.minutesPerDay) {
        throw ArgumentError.value(minutes, 'minutes', 'Must be 0..1440');
      }
    }
    for (final day in [weekStartDay, ...weekdayCapacityMinutes.keys]) {
      if (day < DateTime.monday || day > DateTime.sunday) {
        throw ArgumentError.value(day, 'weekday', 'Must be 1..7');
      }
    }
    for (final minute in [
      reminders.dailyTimeMinutes,
      reminders.quietStartMinutes,
      reminders.quietEndMinutes,
    ]) {
      if (minute < 0 || minute >= Duration.minutesPerDay) {
        throw ArgumentError.value(minute, 'minuteOfDay', 'Must be 0..1439');
      }
    }
    if (reminders.dailyBudget < 0) {
      throw ArgumentError.value(reminders.dailyBudget, 'dailyBudget');
    }
  }

  /// Four hours of plannable time per day until the user says otherwise.
  static const int defaultDailyCapacityMinutes = 240;

  final int dailyCapacityMinutes;

  /// Exceptions per ISO weekday, e.g. Saturday 360, Tuesday (class day) 60.
  final Map<int, int> weekdayCapacityMinutes;

  /// ISO weekday the calendar week starts on.
  final int weekStartDay;

  final ReminderSettings reminders;

  int capacityForWeekday(int weekday) =>
      weekdayCapacityMinutes[weekday] ?? dailyCapacityMinutes;

  PlannerSettings copyWith({
    int? dailyCapacityMinutes,
    Map<int, int>? weekdayCapacityMinutes,
    int? weekStartDay,
    ReminderSettings? reminders,
  }) => PlannerSettings(
    dailyCapacityMinutes: dailyCapacityMinutes ?? this.dailyCapacityMinutes,
    weekdayCapacityMinutes:
        weekdayCapacityMinutes ?? this.weekdayCapacityMinutes,
    weekStartDay: weekStartDay ?? this.weekStartDay,
    reminders: reminders ?? this.reminders,
  );
}
