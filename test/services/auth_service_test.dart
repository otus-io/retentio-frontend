import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:retentio/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:retentio/models/api_response.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastDelete;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/profile' && options.method == 'DELETE') {
      lastDelete = options;
      final ok = (options.data as Map)['password'] == 'valid-password';
      return ResponseBody.fromString(
        jsonEncode(
          ok
              ? {
                  'data': {'msg': 'Account deleted successfully'},
                }
              : {'msg': 'Invalid credentials'},
        ),
        ok ? 200 : 401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == '/auth/login' && options.method == 'POST') {
      final body = options.data is Map<String, dynamic>
          ? options.data as Map<String, dynamic>
          : <String, dynamic>{};
      final username = body['username']?.toString();
      final password = body['password']?.toString();

      if (username == 'valid-user' && password == 'valid-password') {
        return ResponseBody.fromString(
          jsonEncode({
            'code': 0,
            'msg': 'ok',
            'data': {'token': 'server-token-123'},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      return ResponseBody.fromString(
        jsonEncode({
          'code': -1,
          'msg': 'Invalid username or password',
          'data': null,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == '/auth/logout' && options.method == 'POST') {
      return ResponseBody.fromString(
        jsonEncode({
          'code': 0,
          'msg': 'logout ok',
          'data': {'ok': true},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'code': -1, 'msg': 'not found', 'data': null}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService side effects', () {
    late _FakeHttpClientAdapter adapter;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiService.clearToken();

      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
        interceptors: [ResponseNormalizeInterceptor()],
      );
      adapter = _FakeHttpClientAdapter();
      networkDioClient.dio.httpClientAdapter = adapter;
    });

    tearDown(() async {
      await ApiService.clearToken();
    });

    test('login success sets token', () async {
      final result = await AuthService.login(
        username: 'valid-user',
        password: 'valid-password',
      );

      expect(result['token'], 'server-token-123');
      expect(ApiService.authorization, 'server-token-123');
    });

    test('login failure returns message and does not set token', () async {
      final result = await AuthService.login(
        username: 'invalid-user',
        password: 'invalid-password',
      );

      expect(result['token'], isNull);
      expect(result['message'], 'Invalid username or password');
      expect(ApiService.authorization, '');
    });

    test('repository login stores the username for offline data', () async {
      const local = LocalAuthDataSource();
      await const AuthRepositoryImpl(
        local,
      ).login(username: 'valid-user', password: 'valid-password');

      expect(await local.readUsername(), 'valid-user');
    });

    test(
      'logout clears token regardless of backend response payload',
      () async {
        await ApiService.setToken('token-before-logout');
        expect(ApiService.authorization, 'token-before-logout');

        final res = await AuthService.logout();

        expect(res, isA<ApiResponse?>());
        expect(ApiService.authorization, '');
      },
    );

    test('deleteAccount sends the password in a DELETE body', () async {
      final res = await AuthService.deleteAccount(password: 'valid-password');

      expect(res?.isSuccess, isTrue);
      expect(adapter.lastDelete?.data, {'password': 'valid-password'});
      expect(adapter.lastDelete?.queryParameters, isEmpty);
    });

    test('deleteAccount with a wrong password keeps the session', () async {
      await ApiService.setToken('live-token');

      final res = await AuthService.deleteAccount(password: 'wrong');

      expect(res?.isSuccess, isFalse);
      expect(res?.msg, 'Invalid credentials');
      expect(ApiService.authorization, 'live-token');
    });
  });
}
