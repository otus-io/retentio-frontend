import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/offline_learning/data/offline_deck_catalog.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';

import '../../../helpers/test_wrapper.dart';

class _DeckApi extends Interceptor {
  _DeckApi({required this.deleteOk});

  final bool deleteOk;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'DELETE' && !deleteOk) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'code': 1, 'msg': 'published decks cannot be deleted'},
        ),
      );
      return;
    }
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'code': 0,
          'msg': 'ok',
          'data': {'decks': <Object>[]},
        },
      ),
    );
  }
}

class _Unreachable extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) =>
      handler.reject(DioException(requestOptions: options));
}

class _UnusedStore implements OfflineLearningStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCatalog implements OfflineDeckCatalog {
  final removed = <String>[];
  Set<String> ready = {'d1'};
  bool fail = false;
  Object? fetchError;

  @override
  Future<List<Deck>> decks(Future<List<Deck>> Function() fetchRemote) async {
    try {
      return await fetchRemote();
    } catch (e) {
      fetchError = e;
      rethrow;
    }
  }

  @override
  Future<Set<String>> readyDeckIds() async => ready;

  @override
  Future<void> remove(String deckId) async {
    if (fail) throw StateError('disk');
    removed.add(deckId);
  }
}

const _deck = Deck(
  id: 'd1',
  name: 'N5',
  rate: 0,
  fields: [],
  minInterval: 0,
  defInterval: 0,
  maxInterval: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(setupTestEnvironment);

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  Future<_FakeCatalog> delete({required bool ok, bool fail = false}) async {
    networkDioClient.dio.interceptors.add(_DeckApi(deleteOk: ok));
    final catalog = _FakeCatalog()..fail = fail;
    final cubit = DeckListCubit(offlineCatalog: catalog);
    await cubit.deleteDeck(_deck);
    await cubit.close();
    return catalog;
  }

  test('deleting a deck drops its offline copy', () async {
    expect((await delete(ok: true)).removed, ['d1']);
  });

  test('a rejected delete keeps the offline copy', () async {
    expect((await delete(ok: false)).removed, isEmpty);
  });

  test('offline cleanup errors do not fail the delete', () async {
    expect((await delete(ok: true, fail: true)).removed, isEmpty);
  });

  test('refresh carries the offline-ready deck ids', () async {
    networkDioClient.dio.interceptors.add(_DeckApi(deleteOk: true));
    final cubit = DeckListCubit(offlineCatalog: _FakeCatalog());
    await cubit.onRefresh();
    await cubit.close();

    expect(cubit.state.offlineReadyDeckIds, {'d1'});
    expect(cubit.state.copyWith(isLoading: true).offlineReadyDeckIds, {'d1'});
  });

  test('a failed deck request reaches the offline catalog', () async {
    networkDioClient.dio.interceptors.add(_Unreachable());
    final catalog = _FakeCatalog();
    final cubit = DeckListCubit(offlineCatalog: catalog);
    await cubit.onRefresh();
    await cubit.close();

    expect(catalog.fetchError, isA<DioException>());
  });

  OfflineLearningSessions sessions({
    Future<String?> Function()? readUsername,
  }) => OfflineLearningSessions(
    readUsername: readUsername ?? () async => 'user',
    openStore: (_) async => _UnusedStore(),
    documentsDir: () async => Directory.systemTemp.path,
  );

  test('loads the account downloader apart from the list', () async {
    networkDioClient.dio.interceptors.add(_DeckApi(deleteOk: true));
    final cubit = DeckListCubit(
      offlineCatalog: _FakeCatalog(),
      sessions: sessions(),
    );

    final loaded = await cubit.stream.firstWhere((s) => s.downloader != null);
    await cubit.close();

    expect(loaded.downloader, isNotNull);
    expect(loaded.copyWith(isLoading: true).downloader, isNotNull);
  });

  test(
    'has no downloader without an account or when the session fails',
    () async {
      networkDioClient.dio.interceptors.add(_DeckApi(deleteOk: true));
      for (final read in <Future<String?> Function()>[
        () async => null,
        () async => throw StateError('locked'),
      ]) {
        final cubit = DeckListCubit(
          offlineCatalog: _FakeCatalog(),
          sessions: sessions(readUsername: read),
        );
        await cubit.onRefresh();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await cubit.close();

        expect(cubit.state.downloader, isNull);
        expect(cubit.state.offlineReadyDeckIds, {'d1'});
      }
    },
  );

  test('a session that opens after the cubit closed is ignored', () async {
    final gate = Completer<String?>();
    final cubit = DeckListCubit(
      offlineCatalog: _FakeCatalog(),
      sessions: sessions(readUsername: () => gate.future),
    );
    await cubit.close();

    gate.complete('user');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cubit.state.downloader, isNull);
  });

  test('refreshOfflineReady rereads the ids without refetching', () async {
    networkDioClient.dio.interceptors.add(_DeckApi(deleteOk: true));
    final catalog = _FakeCatalog();
    final cubit = DeckListCubit(offlineCatalog: catalog);
    await cubit.onRefresh();
    catalog.ready = {'d1', 'd2'};

    await cubit.refreshOfflineReady();
    expect(cubit.state.offlineReadyDeckIds, {'d1', 'd2'});

    await cubit.close();
    catalog.ready = {};
    await cubit.refreshOfflineReady();
    expect(cubit.state.offlineReadyDeckIds, {'d1', 'd2'});
  });
}
