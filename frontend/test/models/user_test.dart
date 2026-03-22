import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/user.dart';

void main() {
  group('User', () {
    test('empty factory has blank email and username', () {
      final u = User.empty();
      expect(u.email, '');
      expect(u.username, '');
    });

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
      });
    });

    group('toJson', () {
      test('serializes to correct format', () {
        final user = User(email: 'e@test.com', username: 'u');
        final json = user.toJson();
        expect(json['email'], 'e@test.com');
        expect(json['username'], 'u');
      });
    });
  });
}
