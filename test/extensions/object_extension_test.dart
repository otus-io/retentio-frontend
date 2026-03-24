import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/extensions/object_extension.dart';

void main() {
  group('ObjectExtension asT', () {
    test('returns value when this is of type T', () {
      const int value = 42;
      expect(value.asT<int>(0), 42);
    });

    test('returns default when this is null', () {
      const int? nullInt = null;
      expect(nullInt.asT<int>(10), 10);
    });

    test('throws when cast fails (wrong type)', () {
      const value = 'not an int';
      expect(() => value.asT<int>(99), throwsA(anything));
    });

    test('works with String type', () {
      const String s = 'hello';
      expect(s.asT<String>('default'), 'hello');
      expect(null.asT<String>('default'), 'default');
    });

    test('works with Map type', () {
      final map = <String, int>{'a': 1};
      expect(map.asT<Map<String, int>>({}), {'a': 1});
    });
  });

  group('ObjectExtension asMap', () {
    test('returns map when this is a Map', () {
      final map = <String, dynamic>{'key': 'value'};
      expect(map.asMap(), {'key': 'value'});
    });

    test('returns empty map when this is null', () {
      Object? nil;
      expect(nil.asMap(), {});
    });

    test('returns empty map when this is not a Map', () {
      expect(42.asMap(), {});
      expect('string'.asMap(), {});
    });
  });
}
