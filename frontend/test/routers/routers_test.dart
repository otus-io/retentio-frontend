import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/routers/routers.dart';

void main() {
  group('AppRoutes', () {
    test('login has correct path', () {
      expect(AppRoutes.login.path, '/login');
    });

    test('main has correct path', () {
      expect(AppRoutes.main.path, '/');
    });

    test('register has correct path', () {
      expect(AppRoutes.register.path, '/register');
    });

    test('all enum values are defined', () {
      expect(AppRoutes.values.length, 3);
      expect(AppRoutes.values, contains(AppRoutes.login));
      expect(AppRoutes.values, contains(AppRoutes.main));
      expect(AppRoutes.values, contains(AppRoutes.register));
    });
  });
}
