import 'package:shared_preferences/shared_preferences.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/models/api_response.dart';
import 'package:retentio/core/di/app_service_locator.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart'
    as feature_auth;
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';

class ApiService {
  static String? _token;
  static SharedPreferences? _prefs;
  static Future<void>? _handlingUnauthorized;

  static Future<SharedPreferences> _preferences() async {
    final cached = _prefs;
    if (cached != null) {
      return cached;
    }
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  static String get authorization => _token ?? '';

  /// 初始化时加载 token
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _token = prefs.getString('token');
  }

  /// 设置 token（登录成功后调用）
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await _preferences();
    await prefs.setString('token', token);
  }

  /// 清除 token（登出时调用）
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await _preferences();
    await prefs.remove('token');
  }

  /// 通用 POST 请求
  static Future<ApiResponse?> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? pathParams,
  }) async {
    final response = await networkDioClient.post(
      endpoint,
      params: body,
      pathParams: pathParams == null
          ? null
          : Map<String, dynamic>.from(pathParams),
    );

    return response;
  }

  /// 通用 Delete请求
  static Future<ApiResponse?> delete(
    String endpoint, {
    Map<String, String>? pathParams,
  }) {
    return networkDioClient.delete(endpoint, pathParams: pathParams);
  }

  /// 通用 GET 请求
  static Future<ApiResponse?> get(
    String endpoint, {
    Map<String, String>? pathParams,
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await networkDioClient.get(
      endpoint,
      pathParams: pathParams,
      params: queryParams,
    );
    return response;
  }

  /// 通用 PUT 请求（无 body，用于幂等关联操作）
  static Future<ApiResponse?> put(
    String endpoint, {
    Map<String, String>? pathParams,
  }) {
    return networkDioClient.put(
      endpoint,
      pathParams: pathParams?.map((k, v) => MapEntry(k, v as dynamic)),
    );
  }

  /// 通用 Patch 请求
  static Future<ApiResponse?> patch(
    String endpoint, {
    Map<String, String>? pathParams,
    dynamic params,
  }) {
    return networkDioClient.patch(
      endpoint,
      pathParams: pathParams,
      params: params,
    );
  }

  /// 构建 headers（自动附加 Authorization）
  static Map<String, dynamic> buildHeaders(Map<String, dynamic>? headers) {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    return {...defaultHeaders, ...?headers};
  }

  /// 处理 401 未授权，清理本地登录态。
  ///
  /// 兼容旧调用方式：保留 `void` 签名，内部异步串行执行副作用。
  static void handle401Unauthorized() {
    _handlingUnauthorized ??= _handle401UnauthorizedInternal().whenComplete(() {
      _handlingUnauthorized = null;
    });
  }

  static Future<void> _handle401UnauthorizedInternal() async {
    await clearToken();

    try {
      await _notifyUnauthorizedToAuthBloc();
    } catch (_) {
      // 保持兼容：401 清理流程不向上抛出异常。
    }
  }

  static Future<feature_auth.AuthBloc?> _getAuthBlocFromDi() async {
    await registerCoreDependencies();
    if (!sl.isRegistered<feature_auth.AuthBloc>()) {
      return null;
    }
    return sl<feature_auth.AuthBloc>();
  }

  static Future<void> _notifyUnauthorizedToAuthBloc() async {
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

    authBloc.add(const AuthRestoreSessionRequested());
    await waitState.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        return authBloc.state;
      },
    );
  }

  static Future<String?> downloadFile(String audioUrl, String path) async {
    return networkDioClient.downloadFile(audioUrl, path, (value) {}, () {});
  }
}
