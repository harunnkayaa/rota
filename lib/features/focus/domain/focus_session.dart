import 'dart:math';

/// A running or paused focus timer (CLAUDE.md §9.7, §13.5).
///
/// Time lives in timestamps, not in a ticking counter: after the app is
/// closed, killed or reopened on another day, the elapsed time is simply
/// recomputed from [startedAt]. Nothing is lost.
class FocusSession {
  FocusSession({
    required this.id,
    required this.goalPeriodId,
    required this.startedAt,
    this.pausedAt,
    this.pausedSeconds = 0,
  }) {
    if (!startedAt.isUtc || (pausedAt != null && !pausedAt!.isUtc)) {
      throw ArgumentError('Focus timestamps must be UTC.');
    }
    if (pausedSeconds < 0) {
      throw ArgumentError.value(pausedSeconds, 'pausedSeconds', 'Must be >= 0');
    }
  }

  final String id;
  final String goalPeriodId;
  final DateTime startedAt;

  /// Set while paused.
  final DateTime? pausedAt;

  /// Total paused time of earlier pauses.
  final int pausedSeconds;

  bool get isPaused => pausedAt != null;

  /// The progress entry created on finish uses this key, so finishing the
  /// same session twice (double tap, retry) records the work once.
  String get idempotencyKey => 'focus:$id';

  Duration elapsed(DateTime nowUtc) {
    final end = pausedAt ?? nowUtc;
    final seconds = end.difference(startedAt).inSeconds - pausedSeconds;
    return Duration(seconds: max(0, seconds));
  }

  /// Whole minutes worked; partial minutes are not rounded up.
  int workedMinutes(DateTime nowUtc) => elapsed(nowUtc).inMinutes;

  FocusSession pause(DateTime nowUtc) {
    if (isPaused) return this;
    return FocusSession(
      id: id,
      goalPeriodId: goalPeriodId,
      startedAt: startedAt,
      pausedAt: nowUtc,
      pausedSeconds: pausedSeconds,
    );
  }

  FocusSession resume(DateTime nowUtc) {
    final pausedAt = this.pausedAt;
    if (pausedAt == null) return this;
    return FocusSession(
      id: id,
      goalPeriodId: goalPeriodId,
      startedAt: startedAt,
      pausedSeconds: pausedSeconds + nowUtc.difference(pausedAt).inSeconds,
    );
  }
}
