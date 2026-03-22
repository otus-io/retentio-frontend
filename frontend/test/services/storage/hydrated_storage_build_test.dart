import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/services/storage/hydrated_storage.dart';

void main() {
  group('HiveHydratedStorage.build', () {
    test('throws ArgumentError when encrypted is true but encryptionKey is null',
        () async {
      await expectLater(
        HiveHydratedStorage.build(
          storageDirectory: '/tmp/hydrated_test_build',
          encrypted: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
