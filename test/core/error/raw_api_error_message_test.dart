import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('rawApiErrorMessage', () {
    test('strips Exception prefix', () {
      expect(rawApiErrorMessage(Exception('Deck not found')), 'Deck not found');
    });

    test('returns AuthRepositoryException message as-is', () {
      expect(
        rawApiErrorMessage(AuthRepositoryException('Invalid credentials')),
        'Invalid credentials',
      );
    });

    test('returns plain string errors unchanged', () {
      expect(rawApiErrorMessage('Connect timeout'), 'Connect timeout');
    });
  });
}
