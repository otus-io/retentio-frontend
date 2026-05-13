import 'package:retentio/features/auth/domain/repositories/auth_repository.dart';

class Logout {
  final AuthRepository _authRepository;

  const Logout(this._authRepository);

  Future<void> call() {
    return _authRepository.logout();
  }
}
