import '../../../core/time/local_date.dart';

/// What a block of the day is for.
enum TimeBlockKind {
  /// Work on a goal: "09:00–11:00 Rota MVP". Counts towards nothing by
  /// itself — progress is still only what the user logs (or times).
  goal,

  /// A break: "11:00–11:15 Mola".
  rest,

  /// Anything else that takes time: "14:00–16:00 Ders".
  other,
}

/// One slot of a planned day: *when* something happens. How much of a goal
/// is planned for the day stays in the daily allocation; blocks only place
/// it on the clock (the user chose "plan and blocks separate, in step").
class TimeBlock {
  TimeBlock({
    required this.id,
    required this.date,
    required this.startMinute,
    required this.endMinute,
    required this.kind,
    this.goalPeriodId,
    String? title,
    this.remind = false,
  }) : title = _normalizeTitle(title) {
    if (startMinute < 0 || startMinute >= Duration.minutesPerDay) {
      throw ArgumentError.value(startMinute, 'startMinute');
    }
    if (endMinute <= startMinute || endMinute > Duration.minutesPerDay) {
      throw ArgumentError.value(endMinute, 'endMinute', 'Must be after start');
    }
    if ((kind == TimeBlockKind.goal) != (goalPeriodId != null)) {
      throw ArgumentError('Only goal blocks point to a goal period.');
    }
    if (kind == TimeBlockKind.other && this.title == null) {
      throw ArgumentError('An "other" block needs a title.');
    }
  }

  final String id;

  /// The user's local calendar day; minutes are local time on that day.
  final LocalDate date;

  /// Minutes since local midnight, start inclusive and end exclusive: a
  /// block may end at 24:00 but never runs into the next day.
  final int startMinute;
  final int endMinute;
  final TimeBlockKind kind;
  final String? goalPeriodId;
  final String? title;

  /// Remind when the block starts (subject to quiet hours and the budget).
  final bool remind;

  int get minutes => endMinute - startMinute;

  bool overlaps(TimeBlock other) =>
      date == other.date &&
      startMinute < other.endMinute &&
      other.startMinute < endMinute;

  bool containsMinute(int minuteOfDay) =>
      minuteOfDay >= startMinute && minuteOfDay < endMinute;

  TimeBlock copyWith({
    String? id,
    LocalDate? date,
    int? startMinute,
    int? endMinute,
    String? goalPeriodId,
    bool? remind,
  }) => TimeBlock(
    id: id ?? this.id,
    date: date ?? this.date,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    kind: kind,
    goalPeriodId: goalPeriodId ?? this.goalPeriodId,
    title: title,
    remind: remind ?? this.remind,
  );

  static String? _normalizeTitle(String? title) {
    final trimmed = title?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
