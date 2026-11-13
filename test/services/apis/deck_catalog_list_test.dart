import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/l10n/app_localizations_en.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fails with [error], or answers [status] with [body] when [error] is null.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.error, this.body, this.status = 200});

  final DioExceptionType? error;
  final int status;
  final Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (error != null) {
      throw DioException(
        requestOptions: options,
        type: error!,
        error: const SocketException('Failed host lookup'),
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.clearToken();
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
  });

  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.connectionError,
  ]) {
    test(
      '${type.name} throws a network error instead of an empty page',
      () async {
        networkDioClient.dio.httpClientAdapter = _Adapter(error: type);

        final error = await DeckCatalogService.of.getCatalog().then<Object?>(
          (_) => null,
          onError: (Object e) => e,
        );

        expect(error, isA<Exception>());
        final loc = AppLocalizationsEn();
        expect(
          ApiErrorMessages.resolve(rawApiErrorMessage(error!), loc),
          loc.noNetworkConnection,
        );
      },
    );
  }

  test('an empty catalog still returns an empty page', () async {
    networkDioClient.dio.httpClientAdapter = _Adapter(
      body: {
        'code': 0,
        'data': {
          'decks': <dynamic>[],
          'meta': {'total': 0, 'has_more': false},
        },
      },
    );

    final page = await DeckCatalogService.of.getCatalog();

    expect(page.decks, isEmpty);
    expect(page.meta.hasMore, isFalse);
  });

  test('catalog deck lookup throws when the network is down', () async {
    networkDioClient.dio.httpClientAdapter = _Adapter(
      error: DioExceptionType.connectionError,
    );

    await expectLater(
      DeckCatalogService.of.getCatalogDeck('d1'),
      throwsA(isA<Exception>()),
    );
  });

  test('catalog deck lookup returns null when the server says 404', () async {
    networkDioClient.dio.httpClientAdapter = _Adapter(
      status: 404,
      body: {'code': 404, 'msg': 'Deck not found in catalog'},
    );

    expect(await DeckCatalogService.of.getCatalogDeck('d1'), isNull);
  });
}
