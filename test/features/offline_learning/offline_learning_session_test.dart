import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:retentio/features/deck_study/data/repositories/deck_study_legacy_service_repository.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/features/offline_learning/data/datasources/hive_offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_sync_service.dart';
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

  test('session sync flushes the account queue', () async {
    final sessions = OfflineLearningSessions(
      readUsername: () async => 'alice',
      isOnline: () async => true,
    );

    final result = await (await sessions.current())!.sync.flush(force: true);

    expect(result.status, OfflineSyncStatus.synced);
    expect(result.sent, 0);
  });

  test('study repository serves the session store and syncs changes', () async {
    var onlineChecks = 0;
    final session = (await OfflineLearningSessions(
      readUsername: () async => 'alice',
      isOnline: () async {
        onlineChecks++;
        return false;
      },
    ).current())!;
    await session.store.putDeck(
      const OfflineDeck(id: 'd1', name: 'N5', fields: ['W'], downloadedAt: 1),
    );
    await session.store.putFacts(const [
      OfflineFact(
        deckId: 'd1',
        id: 'f1',
        entries: [FactEntry(text: 'cat', image: 'img1')],
      ),
    ]);
    await session.store.putCards(const [
      OfflineCard(
        deckId: 'd1',
        id: 'c1',
        factId: 'f1',
        template: [
          [0],
          [0],
        ],
        lastReview: 0,
        dueDate: 1,
      ),
    ]);
    final repo = offlineFirstStudyRepository(
      Future.value(session),
      remote: DeckStudyLegacyServiceRepository(),
    );

    final result = await repo.loadNextDueCard(deckId: 'd1');
    await repo.submitCard(
      DeckStudySubmitRequest.hide(deckId: 'd1', cardId: 'c1'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      result.cardDetail!.card.front.single.items.last.value,
      '${Env.host}/api/media/img1',
    );
    expect(onlineChecks, 1);
  });

  test('clear deletes the account data and media folder', () async {
    final session = (await OfflineLearningSessions(
      readUsername: () async => 'alice',
      documentsDir: () async => dir.path,
    ).current())!;
    await session.store.putMediaPath('m1', '${session.mediaRootDir}/d1/m1');
    Directory('${session.mediaRootDir}/d1').createSync(recursive: true);

    await session.clear();
    expect(await session.store.getMediaPath('m1'), isNull);
    expect(Directory(session.mediaRootDir).existsSync(), isFalse);

    await session.clear();
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
