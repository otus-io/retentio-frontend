import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/services/storage/storage_exception.dart';

void main() {
  group('StorageException', () {
    test('constructor stores message', () {
      const ex = StorageException('Test message');
      expect(ex.message, 'Test message');
      expect(ex.error, isNull);
      expect(ex.stackTrace, isNull);
    });

    test('constructor stores message, error, and stackTrace', () {
      final error = Exception('Inner error');
      final stackTrace = StackTrace.current;
      final ex = StorageException('Outer message', error, stackTrace);
      expect(ex.message, 'Outer message');
      expect(ex.error, error);
      expect(ex.stackTrace, stackTrace);
    });

    test('toString includes message', () {
      const ex = StorageException('Failed to write');
      expect(ex.toString(), contains('StorageException'));
      expect(ex.toString(), contains('Failed to write'));
    });

    test('toString includes error when present', () {
      const ex = StorageException('Failed', 'disk full');
      expect(ex.toString(), contains('StorageException'));
      expect(ex.toString(), contains('Failed'));
      expect(ex.toString(), contains('Error:'));
      expect(ex.toString(), contains('disk full'));
    });
  });
}
