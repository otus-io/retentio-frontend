import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:logger/logger.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:retentio/features/deck_study/data/repositories/deck_study_legacy_service_repository.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/features/offline_learning/data/datasources/hive_offline_learning_store.dart';
import 'package:retentio/features/offline_learning/data/datasources/study_sync_remote_data_source.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/data/remote_offline_package_data_source.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/models/deck.dart';
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

class _NoRemote implements StudySyncRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Holds every upload until [gate] completes, then answers 500.
class _GatedRemote implements StudySyncRemoteDataSource {
  _GatedRemote(this.gate);

  final Completer<void> gate;
  final patched = <String>[];

  @override
  Future<StudyPatchResult> patchCard(
    String deckId,
    Map<String, dynamic> body, {
    required String operationId,
  }) async {
    patched.add(operationId);
    await gate.future;
    return const StudyPatchResult(httpStatus: 500);
  }

  @override
  Future<OfflineDeckCounts?> fetchDeckCounts(String deckId) async => null;

  @override
  Future<List<OfflineCard>?> fetchCards(String deckId) async => null;
}

/// Resolves to [session] on the first `then` and to null afterwards.
class _SessionThenNull implements Future<OfflineLearningSession?> {
  _SessionThenNull(this.session);

  final OfflineLearningSession session;
  var _calls = 0;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(OfflineLearningSession?) onValue, {
    Function? onError,
  }) => Future<OfflineLearningSession?>.value(
    _calls++ == 0 ? session : null,
  ).then(onValue, onError: onError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offline_session');
    await setupTestEnvironment();
    FlutterSecureStorage.setMockInitialValues({});
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

  test('does not fetch a missing username when told not to', () async {
    attachFakeProfileApiInterceptor();

    expect(
      await OfflineLearningSessions().current(fetchMissingUsername: false),
      isNull,
    );
    expect(await const LocalAuthDataSource().readUsername(), isNull);
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

  test('a sync error after a local change is only logged', () async {
    final session = (await OfflineLearningSessions(
      readUsername: () async => 'alice',
      isOnline: () async => throw StateError('no connectivity plugin'),
    ).current())!;
    await session.store.putDeck(
      const OfflineDeck(id: 'd1', name: 'N5', fields: ['W'], downloadedAt: 1),
    );
    await session.store.putCards(const [
      OfflineCard(
        deckId: 'd1',
        id: 'c1',
        factId: 'f1',
        template: [],
        lastReview: 0,
        dueDate: 1,
      ),
    ]);
    final repo = offlineFirstStudyRepository(
      Future.value(session),
      remote: DeckStudyLegacyServiceRepository(),
    );

    final saved = await repo.submitCard(
      DeckStudySubmitRequest.hide(deckId: 'd1', cardId: 'c1'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(saved, isTrue);
    expect(session.sync.phase.value, OfflineSyncPhase.failed);
  });

  test('a local change without a session logs no warning', () async {
    final session = (await OfflineLearningSessions(
      readUsername: () async => 'alice',
    ).current())!;
    await session.store.putDeck(
      const OfflineDeck(id: 'd1', name: 'N5', fields: ['W'], downloadedAt: 1),
    );
    await session.store.putCards(const [
      OfflineCard(
        deckId: 'd1',
        id: 'c1',
        factId: 'f1',
        template: [],
        lastReview: 0,
        dueDate: 1,
      ),
    ]);
    final warnings = <String>[];
    void listen(LogEvent e) => warnings.add('${e.message}');
    Logger.addLogListener(listen);
    addTearDown(() => Logger.removeLogListener(listen));
    final repo = offlineFirstStudyRepository(
      _SessionThenNull(session),
      remote: DeckStudyLegacyServiceRepository(),
    );

    final saved = await repo.submitCard(
      DeckStudySubmitRequest.hide(deckId: 'd1', cardId: 'c1'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(saved, isTrue);
    expect(warnings, isEmpty);
  });

  test('study repository re-downloads after a fact edit', () async {
    var downloads = 0;
    final store = await HiveOfflineLearningStore.open(accountId: 'alice');
    final session = OfflineLearningSession(
      accountId: 'alice',
      store: store,
      mediaRootDir: '${dir.path}/media',
      downloader: OfflinePackageDownloader(
        store: store,
        mediaRootDir: '${dir.path}/media',
        fetchDeck: (id) async {
          downloads++;
          return Deck.fromJson({'id': id, 'name': 'Deck'});
        },
        fetchFactsPage: (_, _, _) async =>
            const OfflineFactsPage(facts: [], hasMore: false),
        fetchCards: (_) async => [],
        nowSec: () => 1,
      ),
      sync: OfflineSyncService(
        store: store,
        remote: _NoRemote(),
        isOnline: () async => true,
        nowSec: () => 1,
      ),
    );
    await store.putDeck(
      const OfflineDeck(id: 'd1', name: 'N5', fields: ['W'], downloadedAt: 1),
    );
    final repo = offlineFirstStudyRepository(
      Future.value(session),
      remote: DeckStudyLegacyServiceRepository(),
      isOnline: () async => true,
    );

    await repo.resyncLocalCopy('d1');

    expect(downloads, 1);
  });

  test('a failed open is retried on the next call', () async {
    var opens = 0;
    final sessions = OfflineLearningSessions(
      readUsername: () async => 'alice',
      openStore: (accountId) async {
        if (++opens == 1) throw StateError('keychain locked');
        return HiveOfflineLearningStore.open(accountId: accountId);
      },
    );

    await expectLater(sessions.current(), throwsStateError);
    final session = await sessions.current();

    expect(session!.accountId, 'alice');
    expect(opens, 2);
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

  group('removal while background work runs', () {
    late HiveOfflineLearningStore store;
    late Completer<void> deckGate;
    late Completer<void> patchGate;
    late _GatedRemote remote;
    late OfflineLearningSession session;

    setUp(() async {
      store = await HiveOfflineLearningStore.open(accountId: 'alice');
      deckGate = Completer<void>();
      patchGate = Completer<void>();
      remote = _GatedRemote(patchGate);
      final mediaRootDir = '${dir.path}/media';
      session = OfflineLearningSession(
        accountId: 'alice',
        store: store,
        mediaRootDir: mediaRootDir,
        downloader: OfflinePackageDownloader(
          store: store,
          mediaRootDir: mediaRootDir,
          fetchDeck: (id) async {
            await deckGate.future;
            return Deck.fromJson({'id': id, 'name': 'Deck'});
          },
          fetchFactsPage: (_, _, _) async =>
              const OfflineFactsPage(facts: [], hasMore: false),
          fetchCards: (_) async => [],
          nowSec: () => 1,
        ),
        sync: OfflineSyncService(
          store: store,
          remote: remote,
          isOnline: () async => true,
          nowSec: () => 1,
        ),
      );
      await store.putDeck(
        const OfflineDeck(id: 'd1', name: 'd1', fields: [], downloadedAt: 1),
      );
      for (final (id, deckId) in [('op1', 'd1'), ('op2', 'd2')]) {
        await store.updateOperation(
          StudySyncOperation(
            operationId: id,
            sequence: id == 'op1' ? 1 : 2,
            deckId: deckId,
            cardId: 'c-$deckId',
            type: StudySyncType.review,
            createdAt: 0,
            interval: 60,
            lastReview: 1,
          ),
        );
      }
    });

    /// Starts a download of d1 and a flush blocked on its first upload, which
    /// fails with a 500 once released and so writes its op back.
    Future<(Future<bool>, Future<OfflineSyncResult>)> startWork() async {
      final download = session.downloader.download('d1');
      final flush = session.sync.flush(force: true);
      while (remote.patched.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      return (download, flush);
    }

    test('removeDeck is not undone by the download or upload', () async {
      final (download, flush) = await startWork();

      final removed = session.removeDeck('d1');
      deckGate.complete();
      patchGate.complete();
      await removed;
      await flush;

      expect(await download, isFalse);
      expect(await store.getDeck('d1'), isNull);
      expect(
        [for (final op in await store.getOperations()) op.operationId],
        ['op2'],
      );
      // The paused flush did not go on to the other deck's op.
      expect(remote.patched, ['op1']);
    });

    test('clear is not undone by the download or upload', () async {
      final (download, flush) = await startWork();

      final cleared = session.clear();
      deckGate.complete();
      patchGate.complete();
      await cleared;
      await flush;

      expect(await download, isFalse);
      expect(await store.getDecks(), isEmpty);
      expect(await store.getOperations(), isEmpty);
      expect(remote.patched, ['op1']);
    });

    test('background work runs again once removal is done', () async {
      deckGate.complete();
      patchGate.complete();
      await session.removeDeck('d1');

      expect(await session.downloader.download('d1'), isTrue);
      expect(
        (await session.sync.flush(force: true)).status,
        OfflineSyncStatus.partial,
      );
      expect(remote.patched, ['op2']);
    });
  });

  test('removeDeck keeps media shared with another downloaded deck', () async {
    final session = (await OfflineLearningSessions(
      readUsername: () async => 'alice',
      documentsDir: () async => dir.path,
    ).current())!;
    final store = session.store;
    File only(String name) =>
        File('${session.mediaRootDir}/$name')..createSync(recursive: true);
    final own = only('own.mp3');
    final shared = only('shared.png');
    await store.putMediaPath('own', own.path);
    await store.putMediaPath('shared', shared.path);
    await store.putMediaPath('gone', '${session.mediaRootDir}/gone');
    for (final id in ['d1', 'd2']) {
      await store.putDeck(OfflineDeck(id: id, name: id, fields: const []));
    }
    await store.putFacts(const [
      OfflineFact(
        deckId: 'd1',
        id: 'f1',
        entries: [
          FactEntry(audio: 'own', image: 'shared'),
          FactEntry(audio: 'gone'),
          FactEntry(audio: 'unknown'),
        ],
      ),
      OfflineFact(
        deckId: 'd2',
        id: 'f2',
        entries: [FactEntry(image: 'shared')],
      ),
    ]);

    await session.removeDeck('d1');

    expect(await store.getDeck('d1'), isNull);
    expect(own.existsSync(), isFalse);
    expect(await store.getMediaPath('own'), isNull);
    expect(await store.getMediaPath('gone'), isNull);
    expect(shared.existsSync(), isTrue);
    expect(await store.getMediaPath('shared'), shared.path);
  });

  test('removeDeck also deletes media left over from deleted facts', () async {
    final session = (await OfflineLearningSessions(
      readUsername: () async => 'alice',
      documentsDir: () async => dir.path,
    ).current())!;
    final store = session.store;
    final orphan = File('${session.mediaRootDir}/d1/orphan.png')
      ..createSync(recursive: true);
    await store.putMediaPath('orphan', orphan.path);
    await store.putDeck(const OfflineDeck(id: 'd1', name: 'd1', fields: []));

    await session.removeDeck('d1');

    expect(orphan.existsSync(), isFalse);
    expect(await store.getMediaPath('orphan'), isNull);
  });

  test('removeDeck deletes pinned media but keeps the unpinned copy', () async {
    final session = (await OfflineLearningSessions(
      readUsername: () async => 'alice',
      documentsDir: () async => dir.path,
    ).current())!;
    final store = session.store;
    final pinned = File('${session.mediaRootDir}/d1/aud_v=2')
      ..createSync(recursive: true);
    final owned = File('${session.mediaRootDir}/d2/aud')
      ..createSync(recursive: true);
    await store.putMediaPath('aud?v=2', pinned.path);
    await store.putMediaPath('aud', owned.path);
    for (final id in ['d1', 'd2']) {
      await store.putDeck(OfflineDeck(id: id, name: id, fields: const []));
    }
    await store.putFacts(const [
      OfflineFact(
        deckId: 'd1',
        id: 'f1',
        entries: [FactEntry(audio: 'aud')],
        mediaVersions: {'aud': 2},
      ),
      OfflineFact(
        deckId: 'd2',
        id: 'f2',
        entries: [FactEntry(audio: 'aud')],
      ),
    ]);

    await session.removeDeck('d1');

    expect(pinned.existsSync(), isFalse);
    expect(await store.getMediaPath('aud?v=2'), isNull);
    expect(owned.existsSync(), isTrue);
    expect(await store.getMediaPath('aud'), owned.path);
  });

  test(
    'a failed wipe is finished before the account is opened again',
    () async {
      SharedPreferences.setMockInitialValues({'username': 'alice'});
      final seeded = await HiveOfflineLearningStore.open(accountId: 'alice');
      await seeded.putDeck(const OfflineDeck(id: 'd1', name: 'd1', fields: []));
      var opens = 0;
      final sessions = OfflineLearningSessions(
        documentsDir: () async => dir.path,
        openStore: (accountId) async {
          if (++opens <= 2) throw StateError('keychain locked');
          return HiveOfflineLearningStore.open(accountId: accountId);
        },
      );
      Future<List<String>?> pending() async =>
          (await SharedPreferences.getInstance()).getStringList(
            OfflineLearningSessions.pendingWipeKey,
          );

      await expectLater(sessions.wipeCurrentAccount(), throwsStateError);
      await expectLater(sessions.wipeCurrentAccount(), throwsStateError);
      expect(await pending(), ['alice']);

      final session = await sessions.current();

      expect(await session!.store.getDecks(), isEmpty);
      expect(await pending(), isEmpty);
    },
  );

  test('wipeCurrentAccount does nothing without a stored username', () async {
    for (final name in [null, '']) {
      await OfflineLearningSessions(
        readUsername: () async => name,
      ).wipeCurrentAccount();
    }

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(OfflineLearningSessions.pendingWipeKey), isNull);
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
