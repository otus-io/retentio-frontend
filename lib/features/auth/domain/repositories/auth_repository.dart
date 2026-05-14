import 'package:retentio/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<void> logout();

  Future<AuthSession> restoreSession();
}
