import 'package:equatable/equatable.dart';
import 'package:retentio/features/auth/domain/entities/auth_session.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthSession session;
  final String? errorMessage;

  const AuthState({
    required this.status,
    required this.session,
    this.errorMessage,
  });

  const AuthState.initial()
    : status = AuthStatus.initial,
      session = const AuthSession.unauthenticated(),
      errorMessage = null;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage];
}
