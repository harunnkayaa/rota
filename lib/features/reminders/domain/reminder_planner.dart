import '../../../core/time/local_date.dart';

/// The user's reminder preferences (CLAUDE.md §11). All times are minutes
/// since local midnight.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.dailyTimeMinutes = 20 * Duration.minutesPerHour,
    this.quietStartMinutes = 23 * Duration.minutesPerHour,
    this.quietEndMinutes = 8 * Duration.minutesPerHour,
    this.dailyBudget = 3,
    this.showSensitiveDetails = false,
  });

  /// Off until the user turns reminders on (and grants permission) —
  /// never a blind permission prompt at launch (CLAUDE.md §13.1).
  final bool enabled;

  /// When the "still left today" reminder fires.
  final int dailyTimeMinutes;

  /// Quiet window; may wrap midnight (23:00 → 08:00).
  final int quietStartMinutes;
  final int quietEndMinutes;

  /// At most this many reminders per day.
  final int dailyBudget;

  /// Health/worship goals show their name on the lock screen only if true.
  final bool showSensitiveDetails;

  bool isQuiet(int minuteOfDay) => quietStartMinutes <= quietEndMinutes
      ? minuteOfDay >= quietStartMinutes && minuteOfDay < quietEndMinutes
      : minuteOfDay >= quietStartMinutes || minuteOfDay < quietEndMinutes;

  ReminderSettings copyWith({
    bool? enabled,
    int? dailyTimeMinutes,
    int? quietStartMinutes,
    int? quietEndMinutes,
    int? dailyBudget,
    bool? showSensitiveDetails,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    dailyTimeMinutes: dailyTimeMinutes ?? this.dailyTimeMinutes,
    quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
    quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
    dailyBudget: dailyBudget ?? this.dailyBudget,
    showSensitiveDetails: showSensitiveDetails ?? this.showSensitiveDetails,
  );
}

enum ReminderKind {
  /// "Rota MVP: bugün 1 sa 30 dk kaldı."
  todayRemaining,

  /// "PTE sınavı: tempo için bu hafta 2 sa daha gerekiyor."
  paceBehind,
}

/// Something worth reminding about on [date]. [minutes] is always time not
/// yet worked (docs/product/notification-rules.md).
class ReminderCandidate {
  const ReminderCandidate({
    required this.kind,
    required this.periodId,
    required this.date,
    required this.goalTitle,
    required this.minutes,
    this.isSensitive = false,
  });

  final ReminderKind kind;
  final String periodId;
  final LocalDate date;
  final String goalTitle;
  final int minutes;
  final bool isSensitive;

  /// Same situation → same key → never two notifications for it.
  String get dedupeKey => '${kind.name}:$periodId:$date';
}

class PlannedReminder {
  const PlannedReminder({
    required this.candidate,
    required this.date,
    required this.minuteOfDay,
    required this.hideDetails,
  });

  final ReminderCandidate candidate;
  final LocalDate date;
  final int minuteOfDay;

  /// Show the neutral "Planlanmış kişisel hatırlatıcın var." text.
  final bool hideDetails;

  /// Stable platform id derived from the dedupe key, so rescheduling the
  /// same reminder replaces it instead of adding a second one.
  int get id => stableId(candidate.dedupeKey);
}

/// Chooses which reminders to schedule.
///
/// - Nothing when reminders are off, or nothing is left to do.
/// - Nothing in quiet hours, and nothing already in the past.
/// - Per day at most [ReminderSettings.dailyBudget], largest amount first
///   (ties by title, so the result is deterministic).
List<PlannedReminder> planReminders({
  required ReminderSettings settings,
  required List<ReminderCandidate> candidates,
  required LocalDate today,
  required int nowMinuteOfDay,
}) {
  if (!settings.enabled || settings.dailyBudget <= 0) return const [];
  final time = settings.dailyTimeMinutes;
  if (settings.isQuiet(time)) return const [];

  final byDate = <LocalDate, List<ReminderCandidate>>{};
  final seen = <String>{};
  for (final c in candidates) {
    if (c.minutes <= 0 || !seen.add(c.dedupeKey)) continue;
    if (c.date.isBefore(today)) continue;
    if (c.date == today && time <= nowMinuteOfDay) continue;
    (byDate[c.date] ??= []).add(c);
  }

  final planned = <PlannedReminder>[];
  final dates = byDate.keys.toList()..sort();
  for (final date in dates) {
    final ranked = byDate[date]!
      ..sort((a, b) {
        final byAmount = b.minutes.compareTo(a.minutes);
        return byAmount != 0 ? byAmount : a.goalTitle.compareTo(b.goalTitle);
      });
    for (final c in ranked.take(settings.dailyBudget)) {
      planned.add(
        PlannedReminder(
          candidate: c,
          date: date,
          minuteOfDay: time,
          hideDetails: c.isSensitive && !settings.showSensitiveDetails,
        ),
      );
    }
  }
  return planned;
}

/// 31-bit FNV-1a hash: the same text always gives the same positive id,
/// on every platform and every run.
int stableId(String text) {
  const prime = 16777619;
  var hash = 2166136261;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * prime) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}
