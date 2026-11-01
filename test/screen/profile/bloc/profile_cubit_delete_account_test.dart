import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/screen/profile/bloc/profile_cubit.dart';

import '../../../helpers/test_wrapper.dart';

class _FakeProfileApi extends Interceptor {
  Object? deleteBody;
  bool nullBody = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'DELETE' && options.path == '/api/profile') {
      deleteBody = options.data;
      if (nullBody) {
        handler.resolve(Response(requestOptions: options, statusCode: 200));
        return;
      }
      if ((options.data as Map)['password'] == 'right') {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {'msg': 'Account deleted successfully'},
            },
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
    handler.resolve(
      Response(requestOptions: options, statusCode: 200, data: {'data': {}}),
    );
  }
}

class _FakeSession implements OfflineLearningSession {
  int clears = 0;
  bool failClear = false;

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('disk');
    clears++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeProfileApi api;
  late _FakeSession session;

  setUp(() async {
    await setupTestEnvironment();
    api = _FakeProfileApi();
    networkDioClient.dio.interceptors.add(api);
    session = _FakeSession();
  });

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  ProfileCubit cubit({
    OfflineLearningSession? offline,
    Future<bool> Function()? isOnline,
  }) {
    final c = ProfileCubit(
      offlineSession: () async => offline,
      isOnline: isOnline ?? () async => true,
    );
    addTearDown(c.close);
    return c;
  }

  test('success sends the password and clears offline data', () async {
    final c = cubit(offline: session);

    expect(await c.deleteAccount('right'), isNull);
    expect(api.deleteBody, {'password': 'right'});
    expect(session.clears, 1);
  });

  test('success without offline data', () async {
    expect(await cubit().deleteAccount('right'), isNull);
  });

  test('offline cleanup errors do not fail the deletion', () async {
    session.failClear = true;

    expect(await cubit(offline: session).deleteAccount('right'), isNull);
  });

  test('wrong password returns the server message', () async {
    final c = cubit(offline: session);

    expect(await c.deleteAccount('wrong'), 'Invalid credentials');
    expect(session.clears, 0);
  });

  test('empty response returns a fallback message', () async {
    api.nullBody = true;

    expect(
      await cubit(offline: session).deleteAccount('right'),
      'Unknown error',
    );
    expect(session.clears, 0);
  });

  test('offline returns a network error without calling the API', () async {
    final c = cubit(offline: session, isOnline: () async => false);

    expect(await c.deleteAccount('right'), 'Connect error');
    expect(api.deleteBody, isNull);
    expect(session.clears, 0);
  });

  test('a failing connectivity check does not block deletion', () async {
    final c = cubit(
      offline: session,
      isOnline: () => Future<bool>.error(StateError('plugin')),
    );

    expect(await c.deleteAccount('right'), isNull);
    expect(session.clears, 1);
  });

  test('defaults to the shared offline session lookup', () async {
    final c = ProfileCubit(isOnline: () async => true);
    addTearDown(c.close);

    expect(await c.deleteAccount('right'), isNull);
  });
}
