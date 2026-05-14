import 'package:retentio/features/auth/domain/entities/auth_session.dart';
import 'package:retentio/features/auth/domain/repositories/auth_repository.dart';

class Login {
  final AuthRepository _authRepository;

  const Login(this._authRepository);

  Future<AuthSession> call({
    required String username,
    required String password,
  }) {
    return _authRepository.login(username: username, password: password);
  }
}
