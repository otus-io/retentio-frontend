import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/features/auth/domain/entities/auth_session.dart';
import 'package:retentio/features/auth/domain/usecases/login.dart';
import 'package:retentio/features/auth/domain/usecases/logout.dart';
import 'package:retentio/features/auth/domain/usecases/restore_session.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RestoreSession _restoreSession;
  final Login _login;
  final Logout _logout;

  AuthBloc({
    required RestoreSession restoreSession,
    required Login login,
    required Logout logout,
  }) : _restoreSession = restoreSession,
       _login = login,
       _logout = logout,
       super(const AuthState.initial()) {
    on<AuthEvent>(_onEvent, transformer: _sequential());
  }

  EventTransformer<T> _sequential<T>() {
    return (events, mapper) => events.asyncExpand(mapper);
  }

  Future<void> _onEvent(AuthEvent event, Emitter<AuthState> emit) async {
    if (event is AuthRestoreSessionRequested) {
      await _onRestoreSessionRequested(emit);
      return;
    }

    if (event is AuthLoginRequested) {
      await _onLoginRequested(event, emit);
      return;
    }

    if (event is AuthLogoutRequested) {
      await _onLogoutRequested(emit);
    }
  }

  Future<void> _onRestoreSessionRequested(Emitter<AuthState> emit) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        session: const AuthSession.unauthenticated(),
        errorMessage: null,
      ),
    );

    try {
      final session = await _restoreSession();
      emit(
        state.copyWith(
          status: session.isLoggedIn
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          session: session,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          session: const AuthSession.unauthenticated(),
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        session: const AuthSession.unauthenticated(),
        errorMessage: null,
      ),
    );

    try {
      final session = await _login(
        username: event.username,
        password: event.password,
      );

      emit(
        state.copyWith(
          status: session.isLoggedIn
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          session: session,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          session: const AuthSession.unauthenticated(),
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(Emitter<AuthState> emit) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        session: state.session,
        errorMessage: null,
      ),
    );

    try {
      await _logout();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          session: const AuthSession.unauthenticated(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
