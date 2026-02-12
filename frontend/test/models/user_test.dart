import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/models/user.dart';

void main() {
  group('User', () {
    group('fromJson', () {
      test('parses user with all fields', () {
        final json = {
          'email': 'user@example.com',
          'username': 'testuser',
          'created_at': '2024-01-15T10:30:00.000Z',
        };
        final user = User.fromJson(json);
        expect(user.email, 'user@example.com');
        expect(user.username, 'testuser');
        expect(user.createdAt, isA<DateTime>());
        expect(user.createdAt.toIso8601String(), contains('2024-01-15'));
      });
    });

    group('toJson', () {
      test('serializes to correct format', () {
        final user = User(
          email: 'e@test.com',
          username: 'u',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30, 0),
        );
        final json = user.toJson();
        expect(json['email'], 'e@test.com');
        expect(json['username'], 'u');
        expect(json['created_at'], isA<String>());
        expect(json['created_at'], contains('2024-01-15'));
      });
    });
  });
}
