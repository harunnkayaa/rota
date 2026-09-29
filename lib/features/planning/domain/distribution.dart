import '../../../core/time/local_date.dart';

/// Splits [total] into whole units proportional to [weights].
///
/// Uses the largest-remainder method: everyone gets the rounded-down share,
/// and the few leftover units go to the largest fractional parts. Ties go to
/// the earlier slot, so the same input always gives the same output.
/// Example: 100 over three equal weights -> [34, 33, 33].
List<int> splitProportionally(int total, List<int> weights) {
  if (total < 0) throw ArgumentError.value(total, 'total', 'Must be >= 0');
  if (weights.any((w) => w < 0)) {
    throw ArgumentError.value(weights, 'weights', 'Must be >= 0');
  }
  final weightSum = weights.fold(0, (a, b) => a + b);
  if (weightSum == 0) return List.filled(weights.length, 0);

  final shares = [for (final w in weights) total * w ~/ weightSum];
  var leftover = total - shares.fold(0, (a, b) => a + b);
  final order = List.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final byRemainder = (total * weights[b] % weightSum).compareTo(
        total * weights[a] % weightSum,
      );
      return byRemainder != 0 ? byRemainder : a.compareTo(b);
    });
  for (final i in order) {
    if (leftover == 0) break;
    shares[i]++;
    leftover--;
  }
  return shares;
}

/// Like [splitProportionally], but slot `i` never receives more than
/// `caps[i]` (null = no limit). Whatever a full slot cannot take is shared
/// again among the others ("water filling").
///
/// The result may sum to less than [total] when the caps are too small; the
/// caller reports that difference as a shortfall instead of hiding it.
///
/// With [block] > 1 the shares are whole multiples of [block] (e.g. 5
/// minutes: "+10 dk" instead of "+8 dk"). What does not fit in whole blocks
/// goes to one slot with room, or minute by minute as a last resort, so
/// blocks never make a plan less feasible.
List<int> splitWithCaps(
  int total,
  List<int> weights,
  List<int?> caps, {
  int block = 1,
}) {
  if (caps.length != weights.length) {
    throw ArgumentError('weights and caps must have the same length.');
  }
  if (block < 1) throw ArgumentError.value(block, 'block', 'Must be >= 1');
  if (block == 1) return _splitWithCaps(total, weights, caps);

  final result = [
    for (final share in _splitWithCaps(total ~/ block, weights, [
      for (final c in caps) c == null ? null : c ~/ block,
    ]))
      share * block,
  ];
  final leftover = total - result.fold<int>(0, (a, b) => a + b);
  if (leftover == 0) return result;

  final rooms = <int?>[
    for (var i = 0; i < caps.length; i++)
      if (weights[i] <= 0)
        0
      else if (caps[i] case final cap?)
        cap - result[i]
      else
        null,
  ];
  // One slot takes the rest: the heaviest with room, earliest on ties.
  int? best;
  for (var i = 0; i < rooms.length; i++) {
    final room = rooms[i];
    if (weights[i] <= 0 || (room != null && room < leftover)) continue;
    if (best == null || weights[i] > weights[best]) best = i;
  }
  if (best != null) {
    result[best] += leftover;
    return result;
  }
  final extra = _splitWithCaps(leftover, weights, rooms);
  return [for (var i = 0; i < result.length; i++) result[i] + extra[i]];
}

List<int> _splitWithCaps(int total, List<int> weights, List<int?> caps) {
  final result = List.filled(weights.length, 0);
  var active = [
    for (var i = 0; i < weights.length; i++)
      if (weights[i] > 0 && (caps[i] ?? 1) > 0) i,
  ];
  var remaining = total;

  while (remaining > 0 && active.isNotEmpty) {
    final shares = splitProportionally(remaining, [
      for (final i in active) weights[i],
    ]);
    var overflow = 0;
    final stillOpen = <int>[];
    for (var k = 0; k < active.length; k++) {
      final i = active[k];
      final cap = caps[i];
      final room = cap == null ? shares[k] : cap - result[i];
      final given = shares[k] < room ? shares[k] : room;
      result[i] += given;
      overflow += shares[k] - given;
      if (cap == null || result[i] < cap) stillOpen.add(i);
    }
    remaining = overflow;
    active = stillOpen;
  }
  return result;
}

/// Spreads [total] as evenly as possible over [days] in whole [block]s;
/// used when the user first distributes a weekly target.
Map<LocalDate, int> distributeEvenly(
  int total,
  List<LocalDate> days, {
  int block = 1,
}) {
  final shares = splitWithCaps(
    total,
    List.filled(days.length, 1),
    List.filled(days.length, null),
    block: block,
  );
  return {for (var i = 0; i < days.length; i++) days[i]: shares[i]};
}

/// Plans in minutes move in 5-minute steps: easy to read, easy to follow.
const minutePlanBlock = 5;
