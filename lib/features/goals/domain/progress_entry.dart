import '../../../core/time/local_date.dart';

enum ProgressSource { manual, focusTimer, imported, adjustment }

/// A single piece of real work: "Pazartesi 90 dk proje".
///
/// This is the single source of truth for progress. Daily and period totals
/// are always computed from these entries, so one entry can never be counted
/// twice or drift out of sync with a stored total. Entries are append-only:
/// a mistake is corrected with a negative [ProgressSource.adjustment] entry.
class ProgressEntry {
  ProgressEntry({
    required this.id,
    required this.goalPeriodId,
    required this.valueDelta,
    required this.source,
    required this.occurredAt,
    required this.localDate,
    String? idempotencyKey,
    this.note,
  }) : idempotencyKey = idempotencyKey ?? id {
    if (valueDelta == 0) {
      throw ArgumentError.value(valueDelta, 'valueDelta', 'Must not be 0');
    }
    if (valueDelta < 0 && source != ProgressSource.adjustment) {
      throw ArgumentError('Only adjustments may be negative.');
    }
    if (!occurredAt.isUtc) {
      throw ArgumentError.value(occurredAt, 'occurredAt', 'Must be UTC');
    }
  }

  final String id;
  final String goalPeriodId;
  final int valueDelta;
  final ProgressSource source;

  /// The exact moment, in UTC.
  final DateTime occurredAt;

  /// The user's calendar day at [occurredAt], frozen when the entry is made.
  /// A later timezone change never moves old work to another day.
  final LocalDate localDate;

  /// Same key = same real-world event. Defaults to [id]; a focus session uses
  /// `focus:<sessionId>` so finishing it twice still yields one entry.
  final String idempotencyKey;
  final String? note;
}
