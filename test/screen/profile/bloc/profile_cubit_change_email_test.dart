import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/screen/profile/bloc/profile_cubit.dart';

import '../../../helpers/test_wrapper.dart';

class _FakeEmailApi extends Interceptor {
  /// When set, GET /api/profile waits for it before answering.
  Completer<void>? profileGate;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method == 'PATCH' && options.path == '/api/profile/email') {
      final password = (options.data as Map)['password'];
      if (password == 'right') {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'username': 'alice',
                'email': 'old@example.com',
                'email_verified': true,
                'pending_email': 'new@example.com',
              },
            },
          ),
        );
        return;
      }
      if (password == 'no-data') {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'data': 'done'},
          ),
        );
        return;
      }
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {'msg': 'Invalid credentials'},
          ),
        ),
      );
      return;
    }
    await profileGate?.future;
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'data': {
            'username': 'alice',
            'email': 'old@example.com',
            'email_verified': true,
          },
        },
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeEmailApi api;

  setUp(() async {
    await setupTestEnvironment();
    api = _FakeEmailApi();
    networkDioClient.dio.interceptors.add(api);
  });

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  Future<ProfileCubit> loadedCubit() async {
    final c = ProfileCubit(
      wipeOfflineData: () async {},
      isOnline: () async => true,
    );
    addTearDown(c.close);
    await c.getProfile();
    return c;
  }

  test('success keeps the current email until the link is opened', () async {
    final c = await loadedCubit();

    expect(await c.changeEmail('new@example.com', 'right'), isNull);
    expect(c.state.user.email, 'old@example.com');
    expect(c.state.user.emailVerified, isTrue);
  });

  test(
    'wrong password returns the server message and keeps the user',
    () async {
      final c = await loadedCubit();

      expect(
        await c.changeEmail('new@example.com', 'wrong'),
        'Invalid credentials',
      );
      expect(c.state.user.email, 'old@example.com');
      expect(c.state.user.emailVerified, isTrue);
    },
  );

  test('success with non-user data keeps the current user', () async {
    final c = await loadedCubit();

    expect(await c.changeEmail('new@example.com', 'no-data'), isNull);
    expect(c.state.user.email, 'old@example.com');
  });

  test('a profile load started before the change does not undo it', () async {
    final c = await loadedCubit();
    api.profileGate = Completer<void>();
    final staleLoad = c.getProfile();

    expect(await c.changeEmail('new@example.com', 'right'), isNull);
    api.profileGate!.complete();
    await staleLoad;

    expect(c.state.user.email, 'old@example.com');
    expect(c.state.status, ProfileStatus.loaded);
  });
}
