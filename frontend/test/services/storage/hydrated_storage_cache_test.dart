import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/services/storage/hydrated_storage.dart';

void main() {
  group('hydrated in-memory cache', () {
    tearDown(() {
      HydratedStorage.instance = null;
    });

    test('writeToCache and readFromCache round-trip', () {
      writeToCache('k1', {'a': 1});
      expect(readFromCache('k1'), {'a': 1});
    });

    test('removeFromCache deletes key', () {
      writeToCache('k2', {'x': true});
      removeFromCache('k2');
      expect(readFromCache('k2'), isNull);
    });

    test('clearCache clears current token scope', () {
      writeToCache('k3', {'n': 2});
      clearCache();
      expect(readFromCache('k3'), isNull);
    });

    test('setting HydratedStorage.instance clears all cache', () {
      writeToCache('scoped', {'v': 1});
      HydratedStorage.instance = null;
      expect(readFromCache('scoped'), isNull);
    });
  });
}
