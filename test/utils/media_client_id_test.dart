import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/utils/media_client_id.dart';

void main() {
  group('newMediaClientId', () {
    test('length matches mediaClientIdLength', () {
      for (var i = 0; i < 50; i++) {
        final id = newMediaClientId();
        expect(id.length, mediaClientIdLength);
      }
    });

    test('uses only backend nanoid alphabet (lowercase a-z and 0-9)', () {
      const allowed = 'abcdefghijklmnopqrstuvwxyz0123456789';
      for (var i = 0; i < 100; i++) {
        final id = newMediaClientId();
        for (final unit in id.codeUnits) {
          expect(allowed.contains(String.fromCharCode(unit)), isTrue);
        }
      }
    });

    test('matches compact pattern', () {
      final re = RegExp(r'^[a-z0-9]{10}$');
      for (var i = 0; i < 30; i++) {
        expect(newMediaClientId(), matches(re));
      }
    });

    test('many generated ids are pairwise distinct', () {
      const n = 256;
      final seen = <String>{};
      for (var i = 0; i < n; i++) {
        seen.add(newMediaClientId());
      }
      expect(seen.length, n);
    });
  });
}
