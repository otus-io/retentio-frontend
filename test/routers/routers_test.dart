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

    test('reset password has correct path', () {
      expect(AppRoutes.resetPassword.path, '/reset-password');
    });

    test('verify email has correct path', () {
      expect(AppRoutes.verifyEmail.path, '/verify-email');
    });

    test('study has correct path', () {
      expect(AppRoutes.study.path, '/study');
    });

    test('discovery detail has correct path', () {
      expect(AppRoutes.discoveryDetail.path, '/discovery/:id');
    });

    test('auth-exempt includes login, reset, and verify but not main', () {
      expect(AppRoutes.isAuthExemptPath('/login'), isTrue);
      expect(AppRoutes.isAuthExemptPath('/'), isFalse);
      expect(AppRoutes.isAuthExemptPath('/discovery/deck-123'), isTrue);
      expect(AppRoutes.isAuthExemptPath('/reset-password'), isTrue);
      expect(AppRoutes.isAuthExemptPath('/verify-email'), isTrue);
    });

    test('all enum values are defined', () {
      expect(AppRoutes.values.length, 7);
      expect(AppRoutes.values, contains(AppRoutes.login));
      expect(AppRoutes.values, contains(AppRoutes.main));
      expect(AppRoutes.values, contains(AppRoutes.register));
      expect(AppRoutes.values, contains(AppRoutes.resetPassword));
      expect(AppRoutes.values, contains(AppRoutes.verifyEmail));
      expect(AppRoutes.values, contains(AppRoutes.study));
      expect(AppRoutes.values, contains(AppRoutes.discoveryDetail));
    });
  });
}
