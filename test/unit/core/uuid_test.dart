import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/utils/uuid.dart';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-8[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  group('uuidFromName', () {
    test('same name, same id; different names, different ids', () {
      final a = uuidFromName('period:goal-1:2026-10-05');
      expect(uuidFromName('period:goal-1:2026-10-05'), a);
      expect(uuidFromName('period:goal-1:2026-10-12'), isNot(a));
      expect(a, matches(_uuid));
    });

    test('is the same on phone and browser (fixed value)', () {
      // Run with --platform chrome too: JavaScript numbers must give the
      // very same id, or two devices would open two different weeks.
      expect(
        uuidFromName('period:goal-1:2026-10-05'),
        '3bd16841-d467-8f10-935c-2c1337c3748a',
      );
    });
  });
}
