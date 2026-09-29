import 'dart:math';

final _random = Random.secure();

/// Random (version 4) UUID, generated on the client.
///
/// Records get their id before they ever reach the server, so a retried sync
/// can be recognised as the same record instead of creating a duplicate.
String generateUuidV4() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// A UUID derived from [name]: the same name gives the same id on every
/// device, without talking to the server.
///
/// Used for records that each device may create on its own, such as the
/// new week opened on Monday: phone and browser then create the very same
/// rows instead of two competing copies. Built from four 32-bit FNV-1a
/// hashes with web-safe arithmetic (JavaScript numbers are not 64-bit).
String uuidFromName(String name) {
  final hex = StringBuffer();
  for (var part = 0; part < 4; part++) {
    hex.write(_fnv1a32('$part:$name').toRadixString(16).padLeft(8, '0'));
  }
  final s = hex.toString();
  // Version 8 (custom) and the RFC 4122 variant, so it is a valid UUID.
  final variant = (int.parse(s[16], radix: 16) & 0x3) | 0x8;
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-'
      '8${s.substring(13, 16)}-${variant.toRadixString(16)}${s.substring(17, 20)}-'
      '${s.substring(20)}';
}

int _fnv1a32(String input) {
  const offsetBasis = 0x811c9dc5;
  const prime = 0x01000193;
  var hash = offsetBasis;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = _mul32(hash, prime);
  }
  return hash;
}

/// (a * b) mod 2^32 without ever exceeding 2^53.
int _mul32(int a, int b) {
  final low = (a & 0xffff) * b;
  final high = ((a >>> 16) * b) & 0xffff;
  return (low + (high << 16)) & 0xffffffff;
}
