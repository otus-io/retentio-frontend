import 'package:retentio/features/auth/domain/entities/auth_session.dart';
import 'package:retentio/features/auth/domain/repositories/auth_repository.dart';

class RestoreSession {
  final AuthRepository _authRepository;

  const RestoreSession(this._authRepository);

  Future<AuthSession> call() {
    return _authRepository.restoreSession();
  }
}
