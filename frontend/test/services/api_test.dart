import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/services/index.dart';

void main() {
  group('Api', () {
    test('login path is correct', () {
      expect(Api.login, '/auth/login');
    });

    test('register path is correct', () {
      expect(Api.register, '/auth/register');
    });

    test('decks path is correct', () {
      expect(Api.decks, '/api/decks');
    });
  });
}
