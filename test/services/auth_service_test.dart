import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/models/api_response.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiService.clearToken();

      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      networkDioClient.dio.httpClientAdapter = _FakeHttpClientAdapter();
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
  });
}
