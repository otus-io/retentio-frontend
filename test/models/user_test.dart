import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/user.dart';

void main() {
  group('User', () {
    test('empty factory has blank email and username', () {
      final u = User.empty();
      expect(u.email, '');
      expect(u.username, '');
      expect(u.emailVerified, isFalse);
    });

    group('fromJson', () {
      test('parses user with all fields', () {
        final json = {
          'email': 'user@example.com',
          'username': 'testuser',
          'email_verified': true,
          'created_at': '2024-01-15T10:30:00.000Z',
        };
        final user = User.fromJson(json);
        expect(user.email, 'user@example.com');
        expect(user.username, 'testuser');
        expect(user.emailVerified, isTrue);
      });

      test('defaults email_verified to false when missing', () {
        final user = User.fromJson({
          'email': 'user@example.com',
          'username': 'testuser',
        });
        expect(user.emailVerified, isFalse);
      });
    });

    group('toJson', () {
      test('serializes to correct format', () {
        final user = User(
          email: 'e@test.com',
          username: 'u',
          emailVerified: true,
        );
        final json = user.toJson();
        expect(json['email'], 'e@test.com');
        expect(json['username'], 'u');
        expect(json['email_verified'], isTrue);
      });
    });
  });
}
