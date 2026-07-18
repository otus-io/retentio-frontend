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

    test('study has correct path', () {
      expect(AppRoutes.study.path, '/study');
    });

    test('discovery detail has correct path', () {
      expect(AppRoutes.discoveryDetail.path, '/discovery/:id');
    });

    test('main and discovery detail are auth-exempt', () {
      expect(AppRoutes.isAuthExemptPath('/'), isTrue);
      expect(AppRoutes.isAuthExemptPath('/discovery/deck-123'), isTrue);
    });

    test('all enum values are defined', () {
      expect(AppRoutes.values.length, 5);
      expect(AppRoutes.values, contains(AppRoutes.login));
      expect(AppRoutes.values, contains(AppRoutes.main));
      expect(AppRoutes.values, contains(AppRoutes.register));
      expect(AppRoutes.values, contains(AppRoutes.study));
      expect(AppRoutes.values, contains(AppRoutes.discoveryDetail));
    });
  });
}
