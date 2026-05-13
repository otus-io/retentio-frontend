// auth_service.dart
import 'package:retentio/models/api_response.dart';
import 'package:retentio/core/di/app_service_locator.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart'
    as feature_auth;
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';
import 'package:retentio/services/index.dart';
import 'api_service.dart';

class AuthService {
  static Future<feature_auth.AuthBloc?> _getAuthBlocFromDi() async {
    await registerCoreDependencies();
    if (!sl.isRegistered<feature_auth.AuthBloc>()) {
      return null;
    }
    return sl<feature_auth.AuthBloc>();
  }

  static Future<void> _dispatchAuthEventAndAwait(AuthEvent event) async {
    final authBloc = await _getAuthBlocFromDi();
    if (authBloc == null) {
      return;
    }

    var observedLoading = false;
    final waitState = authBloc.stream.firstWhere((state) {
      if (state.status == AuthStatus.loading) {
        observedLoading = true;
        return false;
      }
      return observedLoading && state.status != AuthStatus.loading;
    });

    authBloc.add(event);
    await waitState.timeout(const Duration(seconds: 8), onTimeout: () {
      return authBloc.state;
    });
  }

  static Future<ApiResponse?> register({
    required String email,
    required String username,
    required String password,
  }) async {
    return ApiService.post(
      Api.register,
      body: {'email': email, 'username': username, 'password': password},
    );
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await ApiService.post(
      Api.login,
      body: {'username': username, 'password': password},
    );

    final token = res?.data is Map ? (res!.data as Map)['token'] : null;
    if (token is String && token.isNotEmpty) {
      await ApiService.setToken(token);
    }

    final dataMap = res?.data is Map
        ? Map<String, dynamic>.from(res!.data as Map)
        : <String, dynamic>{};
    if (dataMap['token'] == null &&
        res != null &&
        res.msg.isNotEmpty &&
        res.msg != 'Unknown error') {
      dataMap['message'] = res.msg;
    }
    return dataMap;
  }

  /// Login via AuthBloc (DI), keeping API response shape compatible.
  static Future<Map<String, dynamic>> loginByAuthBloc({
    required String username,
    required String password,
  }) async {
    final authBloc = await _getAuthBlocFromDi();
    if (authBloc == null) {
      return login(username: username, password: password);
    }

    var observedLoading = false;
    final waitState = authBloc.stream.firstWhere((state) {
      if (state.status == AuthStatus.loading) {
        observedLoading = true;
        return false;
      }
      return observedLoading && state.status != AuthStatus.loading;
    });

    authBloc.add(AuthLoginRequested(username: username, password: password));
    final state = await waitState.timeout(const Duration(seconds: 8), onTimeout: () {
      return authBloc.state;
    });

    if (state.status == AuthStatus.authenticated) {
      final token = ApiService.authorization;
      return token.isEmpty ? <String, dynamic>{} : <String, dynamic>{'token': token};
    }

    final message =
        state.errorMessage?.trim().isNotEmpty == true ? state.errorMessage! : 'Login failed';
    return <String, dynamic>{'message': message};
  }

  /// Logout: invalidates token on server and clears local state.
  static Future<ApiResponse?> logout() async {
    final res = await ApiService.post(Api.logout);
    await ApiService.clearToken();
    return res;
  }

  /// Logout via AuthBloc (DI). AuthRepository handles server/local cleanup.
  static Future<void> logoutByAuthBloc() async {
    await _dispatchAuthEventAndAwait(const AuthLogoutRequested());
  }

  /// Request password reset; server returns reset_token (e.g. for email flow).
  static Future<ApiResponse?> forgotPassword({required String email}) async {
    return ApiService.post(Api.forgotPassword, body: {'email': email});
  }

  /// Reset password using token from forgot-password.
  static Future<ApiResponse?> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return ApiService.post(
      Api.resetPassword,
      body: {'token': token, 'new_password': newPassword},
    );
  }
}
