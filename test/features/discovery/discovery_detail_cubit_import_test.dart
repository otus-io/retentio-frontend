import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/discovery/bloc/discovery_detail_cubit.dart';

import '../../helpers/test_wrapper.dart';

enum _Refresh { ok, fails, empty }

class _CatalogApi extends Interceptor {
  _CatalogApi([this.refresh = _Refresh.ok]);

  final _Refresh refresh;
  var _imported = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.uri.path;
    if (_imported &&
        path == '/api/decks/catalog/src-1' &&
        refresh != _Refresh.ok) {
      if (refresh == _Refresh.fails) {
        handler.reject(DioException(requestOptions: options));
      } else {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'code': 0, 'msg': 'ok'},
          ),
        );
      }
      return;
    }
    if (path == '/api/decks/import') _imported = true;
    final Object? data = switch (path) {
      '/api/decks/catalog/src-1' => {
        'id': 'src-1',
        'name': 'N5',
        'owner': 'o',
        'published_version': 1,
        'fact_count': 1,
        'import_count': _imported ? 1 : 0,
      },
      '/api/decks/import' => {
        'id': 'deck-9',
        'source_deck_id': 'src-1',
        'source_version': 1,
        'imported_at': '2026-01-01T00:00:00Z',
      },
      _ => null,
    };
    if (data == null) {
      handler.reject(DioException(requestOptions: options));
      return;
    }
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {'code': 0, 'msg': 'ok', 'data': data},
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupTestEnvironment();
  });

  void useApi([_Refresh refresh = _Refresh.ok]) =>
      networkDioClient.dio.interceptors.add(_CatalogApi(refresh));

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  test('starts the offline download of the imported deck', () async {
    useApi();
    final downloaded = Completer<String>();
    final cubit = DiscoveryDetailCubit(
      downloadOffline: (id) async => downloaded.complete(id),
    );
    await cubit.load('src-1');

    await cubit.importDeck();

    expect(cubit.state.importStatus, ImportStatus.imported);
    expect(await downloaded.future, 'deck-9');
    await cubit.close();
  });

  test('a failed offline download does not fail the import', () async {
    useApi();
    final cubit = DiscoveryDetailCubit(
      downloadOffline: (_) => Future.error(StateError('disk full')),
    );
    await cubit.load('src-1');

    await cubit.importDeck();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.importStatus, ImportStatus.imported);
    await cubit.close();
  });

  test('default download skips when no account is known', () async {
    useApi();
    final cubit = DiscoveryDetailCubit();
    await cubit.load('src-1');

    await cubit.importDeck();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.importStatus, ImportStatus.imported);
    await cubit.close();
  });

  test('refreshes the import count after importing', () async {
    useApi();
    final cubit = DiscoveryDetailCubit(downloadOffline: (_) async {});
    await cubit.load('src-1');
    expect(cubit.state.deck!.importCount, 0);

    await cubit.importDeck();

    expect(cubit.state.importStatus, ImportStatus.imported);
    expect(cubit.state.deck!.importCount, 1);
    await cubit.close();
  });

  for (final refresh in [_Refresh.fails, _Refresh.empty]) {
    test(
      'keeps the import when refreshing the deck gives ${refresh.name}',
      () async {
        useApi(refresh);
        final cubit = DiscoveryDetailCubit(downloadOffline: (_) async {});
        await cubit.load('src-1');

        await cubit.importDeck();

        expect(cubit.state.importStatus, ImportStatus.imported);
        expect(cubit.state.importError, isNull);
        expect(cubit.state.deck!.importCount, 0);
        await cubit.close();
      },
    );
  }
}
