import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/offline_learning/data/offline_deck_catalog.dart';
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

class _FakeCatalog implements OfflineDeckCatalog {
  final removed = <String>[];
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

  test('a failed deck request reaches the offline catalog', () async {
    networkDioClient.dio.interceptors.add(_Unreachable());
    final catalog = _FakeCatalog();
    final cubit = DeckListCubit(offlineCatalog: catalog);
    await cubit.onRefresh();
    await cubit.close();

    expect(catalog.fetchError, isA<DioException>());
  });
}
