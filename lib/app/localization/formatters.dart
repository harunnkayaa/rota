import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../core/time/local_date.dart';
import '../../features/categories/domain/category.dart';
import 'app_localizations.dart';

extension AppFormatters on AppLocalizations {
  /// 90 -> "1 sa 30 dk", 120 -> "2 sa", 45 -> "45 dk".
  /// Durations are stored as whole minutes; this is display only.
  String minutes(int total) {
    final hours = total ~/ Duration.minutesPerHour;
    final rest = total % Duration.minutesPerHour;
    if (hours == 0) return durationMinutes('$rest');
    if (rest == 0) return durationHours('$hours');
    return durationHoursMinutes('$hours', '$rest');
  }

  String presetName(PresetCategory preset) => switch (preset) {
    PresetCategory.work => categoryWork,
    PresetCategory.jobApplication => categoryJobApplication,
    PresetCategory.interview => categoryInterview,
    PresetCategory.projectDevelopment => categoryProjectDevelopment,
    PresetCategory.graduateStudy => categoryGraduateStudy,
    PresetCategory.language => categoryLanguage,
    PresetCategory.reading => categoryReading,
    PresetCategory.sport => categorySport,
    PresetCategory.healthMedication => categoryHealthMedication,
    PresetCategory.brainTraining => categoryBrainTraining,
    PresetCategory.worship => categoryWorship,
    PresetCategory.personal => categoryPersonal,
  };
}

/// Short form for tight spaces (week grid): 45 -> "45 dk", 90 -> "1,5 sa".
/// Rounded to one decimal; full precision is shown everywhere else.
String formatCompactMinutes(BuildContext context, int minutes) {
  final l = AppLocalizations.of(context);
  if (minutes < Duration.minutesPerHour) return l.durationMinutes('$minutes');
  final hours = NumberFormat('#0.#', _locale(context));
  return l.hoursCompact(hours.format(minutes / Duration.minutesPerHour));
}

/// Stopwatch style: "25:09", or "1:05:09" after an hour.
String formatTimer(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes % Duration.minutesPerHour;
  final seconds = duration.inSeconds % Duration.secondsPerMinute;
  return hours > 0
      ? '$hours:${two(minutes)}:${two(seconds)}'
      : '${two(minutes)}:${two(seconds)}';
}

/// "Pazartesi" for an ISO weekday (1 = Monday).
String formatWeekdayName(BuildContext context, int weekday) {
  // 5 Jan 2026 is a Monday; any week works.
  final date = DateTime(2026, 1, 4 + weekday);
  return DateFormat('EEEE', _locale(context)).format(date);
}

/// "Pzt"
String formatWeekdayShort(BuildContext context, LocalDate date) =>
    DateFormat('EEE', _locale(context)).format(_asDateTime(date));

/// "Pzt 28 Eyl"
String formatDayShort(BuildContext context, LocalDate date) =>
    DateFormat('EEE d MMM', _locale(context)).format(_asDateTime(date));

/// "28 Eylül Pazartesi"
String formatDayLong(BuildContext context, LocalDate date) =>
    DateFormat('d MMMM EEEE', _locale(context)).format(_asDateTime(date));

/// "28 Eyl"
String formatDayMonth(BuildContext context, LocalDate date) =>
    DateFormat('d MMM', _locale(context)).format(_asDateTime(date));

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

// Formatting only needs the calendar fields; no timezone math happens here.
DateTime _asDateTime(LocalDate date) =>
    DateTime(date.year, date.month, date.day);
