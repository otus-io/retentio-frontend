import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/discovery/bloc/discovery_detail_cubit.dart';

import '../../helpers/test_wrapper.dart';

class _CatalogApi extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final Object? data = switch (options.uri.path) {
      '/api/decks/catalog/src-1' => {
        'id': 'src-1',
        'name': 'N5',
        'owner': 'o',
        'published_version': 1,
        'fact_count': 1,
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
    networkDioClient.dio.interceptors.add(_CatalogApi());
  });

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  test('starts the offline download of the imported deck', () async {
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
    final cubit = DiscoveryDetailCubit();
    await cubit.load('src-1');

    await cubit.importDeck();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.importStatus, ImportStatus.imported);
    await cubit.close();
  });
}
