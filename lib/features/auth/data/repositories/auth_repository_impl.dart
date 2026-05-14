import 'package:retentio/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:retentio/features/auth/domain/entities/auth_session.dart';
import 'package:retentio/features/auth/domain/repositories/auth_repository.dart';
import 'package:retentio/services/apis/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalAuthDataSource _localAuthDataSource;

  const AuthRepositoryImpl(this._localAuthDataSource);

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final result = await AuthService.login(
      username: username,
      password: password,
    );

    final token = result['token'];
    if (token is String && token.isNotEmpty) {
      await _localAuthDataSource.saveToken(token);
      await _localAuthDataSource.saveLoginFlag(true);
      return AuthSession(token: token, isLoggedIn: true);
    }

    final message = (result['message'] ?? result['msg'] ?? 'Login failed')
        .toString();
    throw AuthRepositoryException(message);
  }

  @override
  Future<void> logout() async {
    await AuthService.logout();
    await _localAuthDataSource.clearToken();
    await _localAuthDataSource.saveLoginFlag(false);
  }

  @override
  Future<AuthSession> restoreSession() async {
    final token = await _localAuthDataSource.readToken();
    final isLogin = await _localAuthDataSource.readLoginFlag();

    final isLoggedIn = isLogin && (token?.isNotEmpty ?? false);
    if (!isLoggedIn) {
      return const AuthSession.unauthenticated();
    }

    return AuthSession(token: token!, isLoggedIn: true);
  }
}

class AuthRepositoryException implements Exception {
  final String message;

  AuthRepositoryException(this.message);

  @override
  String toString() => message;
}
