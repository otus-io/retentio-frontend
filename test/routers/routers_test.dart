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

    test('discovery has correct path', () {
      expect(AppRoutes.discovery.path, '/discovery');
    });

    test('discovery detail has correct path', () {
      expect(AppRoutes.discoveryDetail.path, '/discovery/:id');
    });

    test('auth-exempt includes login, reset, and verify but not main', () {
      expect(AppRoutes.isAuthExemptPath('/login'), isTrue);
      expect(AppRoutes.isAuthExemptPath('/'), isFalse);
      expect(AppRoutes.isAuthExemptPath('/discovery'), isTrue);
      expect(AppRoutes.isAuthExemptPath('/discovery/'), isTrue);
      expect(AppRoutes.isAuthExemptPath('/discovery/deck-123'), isTrue);
      expect(AppRoutes.isAuthExemptPath('/reset-password'), isTrue);
      expect(AppRoutes.isAuthExemptPath('/verify-email'), isTrue);
    });

    test('login return path only allows discovery deck pages', () {
      expect(AppRoutes.loginReturnPath(null), isNull);
      expect(AppRoutes.loginReturnPath('/discovery/src-1'), '/discovery/src-1');
      expect(
        AppRoutes.loginReturnPath('/discovery/src-1/'),
        '/discovery/src-1',
      );
      expect(AppRoutes.loginReturnPath('/discovery'), isNull);
      expect(AppRoutes.loginReturnPath('/login'), isNull);
      expect(AppRoutes.loginReturnPath('/study'), isNull);
      expect(AppRoutes.loginReturnPath('https://evil.test/x'), isNull);
    });

    test('login return path resolves dot segments before allowlisting', () {
      expect(
        AppRoutes.loginReturnPath('/discovery/abc/../other'),
        '/discovery/other',
      );
      expect(
        AppRoutes.loginReturnPath('/discovery/./src-1'),
        '/discovery/src-1',
      );
      expect(AppRoutes.loginReturnPath('/discovery/../study'), isNull);
      expect(AppRoutes.loginReturnPath('/discovery/..'), isNull);
    });

    test('discovery deck paths must have exactly one non-empty id segment', () {
      expect(AppRoutes.loginReturnPath('/discovery/a/b'), isNull);
      expect(AppRoutes.loginReturnPath('/discovery//a'), isNull);
      expect(AppRoutes.loginReturnPath('/discovery//'), isNull);
      expect(AppRoutes.isAuthExemptPath('/discovery/a/b'), isFalse);
      expect(AppRoutes.isAuthExemptPath('/discovery//a'), isFalse);
    });

    test('all enum values are defined', () {
      expect(AppRoutes.values.length, 8);
      expect(AppRoutes.values, contains(AppRoutes.login));
      expect(AppRoutes.values, contains(AppRoutes.main));
      expect(AppRoutes.values, contains(AppRoutes.register));
      expect(AppRoutes.values, contains(AppRoutes.resetPassword));
      expect(AppRoutes.values, contains(AppRoutes.verifyEmail));
      expect(AppRoutes.values, contains(AppRoutes.study));
      expect(AppRoutes.values, contains(AppRoutes.discovery));
      expect(AppRoutes.values, contains(AppRoutes.discoveryDetail));
    });
  });
}
