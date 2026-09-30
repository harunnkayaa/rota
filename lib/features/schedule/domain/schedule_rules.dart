import '../../../core/time/local_date.dart';
import 'time_block.dart';

/// Blocks of [date], earliest first.
List<TimeBlock> blocksOnDay(Iterable<TimeBlock> blocks, LocalDate date) =>
    [
      for (final b in blocks)
        if (b.date == date) b,
    ]..sort((a, b) {
      final byStart = a.startMinute.compareTo(b.startMinute);
      return byStart != 0 ? byStart : a.id.compareTo(b.id);
    });

/// The first block that would share time with [candidate] (the block itself
/// is ignored, so an edited block never clashes with its old version).
TimeBlock? firstOverlap(Iterable<TimeBlock> blocks, TimeBlock candidate) {
  for (final b in blocksOnDay(blocks, candidate.date)) {
    if (b.id != candidate.id && b.overlaps(candidate)) return b;
  }
  return null;
}

/// Minutes of a goal period placed on the clock on [date].
int scheduledMinutes(
  Iterable<TimeBlock> blocks, {
  required String periodId,
  required LocalDate date,
}) {
  var total = 0;
  for (final b in blocks) {
    if (b.date == date && b.goalPeriodId == periodId) total += b.minutes;
  }
  return total;
}

const _defaultDayStart = 9 * Duration.minutesPerHour;
const _roundTo = 30;

/// Where a new block most likely starts: right after the day's last block;
/// on an empty day the next half hour from [nowMinute] (today), or 09:00.
int suggestedStart(List<TimeBlock> dayBlocks, {int? nowMinute}) {
  final last = Duration.minutesPerDay - _roundTo;
  if (dayBlocks.isNotEmpty) {
    final end = dayBlocks
        .map((b) => b.endMinute)
        .reduce((a, b) => a > b ? a : b);
    return end > last ? last : end;
  }
  if (nowMinute == null) return _defaultDayStart;
  final rounded = (nowMinute + _roundTo - 1) ~/ _roundTo * _roundTo;
  return rounded > last ? last : rounded;
}

/// Result of copying one day's blocks to another.
class DayCopy {
  const DayCopy({required this.added, required this.skipped});

  final List<TimeBlock> added;

  /// Blocks left out: they would overlap the target day's blocks, or their
  /// goal has no open week on that day. Reported, never silently merged.
  final int skipped;
}

/// Copies [from]'s blocks to [to] ("same as yesterday"). A goal block is
/// moved to the goal's period on [to] via [periodOnTarget]; the target
/// day's existing blocks always win over copied ones.
DayCopy copyDay({
  required Iterable<TimeBlock> blocks,
  required LocalDate from,
  required LocalDate to,
  required String Function() newId,
  required String? Function(String periodId) periodOnTarget,
}) {
  final taken = blocksOnDay(blocks, to);
  final added = <TimeBlock>[];
  var skipped = 0;
  for (final source in blocksOnDay(blocks, from)) {
    String? periodId;
    if (source.goalPeriodId case final id?) {
      periodId = periodOnTarget(id);
      if (periodId == null) {
        skipped++;
        continue;
      }
    }
    final copy = source.copyWith(id: newId(), date: to, goalPeriodId: periodId);
    if ([...taken, ...added].any(copy.overlaps)) {
      skipped++;
      continue;
    }
    added.add(copy);
  }
  return DayCopy(added: added, skipped: skipped);
}
