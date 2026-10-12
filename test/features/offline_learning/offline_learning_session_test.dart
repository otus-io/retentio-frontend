import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:retentio/features/offline_learning/data/datasources/hive_offline_learning_store.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_profile_api_interceptor.dart';
import '../../helpers/test_wrapper.dart';

class _FailingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(DioException(requestOptions: options));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offline_session');
    await setupTestEnvironment();
    Hive.init(dir.path);
  });

  tearDown(() async {
    networkDioClient.dio.interceptors.clear();
    await Hive.deleteFromDisk();
    dir.deleteSync(recursive: true);
    tearDownTestEnvironment();
  });

  test('uses the stored username and reuses the session', () async {
    SharedPreferences.setMockInitialValues({'username': 'alice'});
    final sessions = OfflineLearningSessions();

    final first = await sessions.current();
    final second = await sessions.current();

    expect(first!.accountId, 'alice');
    expect(first.store, isA<HiveOfflineLearningStore>());
    expect(identical(first, second), isTrue);
  });

  test('fetches and saves the username when none is stored', () async {
    attachFakeProfileApiInterceptor();
    final sessions = OfflineLearningSessions();

    final session = await sessions.current();

    expect(session!.accountId, 'tester');
    expect(await const LocalAuthDataSource().readUsername(), 'tester');
  });

  test('returns null when the account cannot be identified', () async {
    networkDioClient.dio.interceptors.add(_FailingInterceptor());
    expect(await OfflineLearningSessions().current(), isNull);

    final empty = OfflineLearningSessions(
      readUsername: () async => '',
      fetchUsername: () async => '',
    );
    expect(await empty.current(), isNull);
  });

  test('exposes one shared resolver', () {
    expect(
      identical(
        OfflineLearningSessions.instance,
        OfflineLearningSessions.instance,
      ),
      isTrue,
    );
  });

  test('switching accounts opens a separate session', () async {
    var name = 'alice';
    final sessions = OfflineLearningSessions(readUsername: () async => name);

    final alice = await sessions.current();
    name = 'bob';
    final bob = await sessions.current();

    expect(alice!.accountId, 'alice');
    expect(bob!.accountId, 'bob');
    expect(identical(alice.store, bob.store), isFalse);
  });
}
