import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/offline_learning/data/datasources/study_sync_remote_data_source.dart';
import 'package:retentio/models/api_response.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StudyApiAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.method == 'GET') {
      if (options.path != '/api/decks/deck-1') {
        return _json({'msg': 'deck not found'}, 404);
      }
      return _json({
        'code': 0,
        'data': {
          'id': 'deck-1',
          'name': 'Deck',
          'stats': {'total_reviews': 7, 'total_reviews_today': 2},
        },
      }, 200);
    }
    switch ((options.data as Map)['card_id']) {
      case 'ok':
        return _json({
          'code': 0,
          'msg': 'ok',
          'data': {'last_review': 10, 'due_date': 70, 'new_interval': 60},
        }, 200);
      case 'bad':
        return _json({'msg': 'interval required'}, 400);
      case 'auth':
        return _json({'msg': 'unauthorized'}, 401);
      case 'gone':
        return _json({'msg': 'card not found'}, 404);
      case 'gone-message':
        return _json({'message': 'card not found'}, 404);
      case 'proxy':
        return ResponseBody.fromString('<html>Not Found</html>', 404);
      default:
        throw const SocketException('offline');
    }
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, int status) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StudyApiAdapter adapter;
  final source = StudySyncRemoteDataSource();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.clearToken();
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
    adapter = _StudyApiAdapter();
    networkDioClient.dio.httpClientAdapter = adapter;
  });

  group('patchCard', () {
    test('sends Idempotency-Key to PATCH card and maps 2xx data', () async {
      final result = await source.patchCard('deck-1', {
        'card_id': 'ok',
      }, operationId: 'op-1');

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/api/decks/deck-1/card');
      expect(request.headers['Idempotency-Key'], 'op-1');
      expect(result.httpStatus, 200);
      expect(result.isSuccess, isTrue);
      expect(result.isApiError, isFalse);
      expect(result.data, {
        'last_review': 10,
        'due_date': 70,
        'new_interval': 60,
      });
    });

    for (final (cardId, status, message) in [
      ('bad', 400, 'interval required'),
      ('auth', 401, 'unauthorized'),
      ('gone', 404, 'card not found'),
    ]) {
      test('maps HTTP $status from the error response', () async {
        final result = await source.patchCard('deck-1', {
          'card_id': cardId,
        }, operationId: 'op-$status');

        expect(result.httpStatus, status);
        expect(result.isSuccess, isFalse);
        expect(result.message, message);
        expect(result.data, isNull);
        expect(result.isApiError, isTrue);
      });
    }

    test('flags a 404 with a `message` envelope as an API error', () async {
      final result = await source.patchCard('deck-1', {
        'card_id': 'gone-message',
      }, operationId: 'op-msg');

      expect(result.httpStatus, 404);
      expect(result.isApiError, isTrue);
    });

    test('does not flag a 404 without an API envelope', () async {
      final result = await source.patchCard('deck-1', {
        'card_id': 'proxy',
      }, operationId: 'op-proxy');

      expect(result.httpStatus, 404);
      expect(result.isApiError, isFalse);
    });

    test('maps a network error to a null status', () async {
      final result = await source.patchCard('deck-1', {
        'card_id': 'offline',
      }, operationId: 'op-net');

      expect(result.httpStatus, isNull);
      expect(result.isSuccess, isFalse);
      expect(result.isApiError, isFalse);
    });

    test('treats statuses outside 2xx as failure', () {
      expect(const StudyPatchResult(httpStatus: 199).isSuccess, isFalse);
      expect(const StudyPatchResult(httpStatus: 300).isSuccess, isFalse);
    });

    test('uses the injected patch function', () async {
      Map<String, dynamic>? sentHeaders;
      final injected = StudySyncRemoteDataSource(
        patchFn: (deckId, body, headers) async {
          sentHeaders = headers;
          return ApiResponse(code: 0, data: {'hidden_status': true});
        },
      );

      final result = await injected.patchCard('deck-1', {
        'card_id': 'c',
        'hidden': true,
      }, operationId: 'op-h');

      expect(sentHeaders, {'Idempotency-Key': 'op-h'});
      expect(result.data, {'hidden_status': true});
      expect(adapter.requests, isEmpty);
    });
  });

  group('401 handling', () {
    setUp(() async {
      await ApiService.setToken('t');
      networkDioClient.dio.interceptors.add(ResponseNormalizeInterceptor());
    });
    tearDown(networkDioClient.dio.interceptors.clear);

    test('sync PATCH keeps the session', () async {
      final result = await source.patchCard('deck-1', {
        'card_id': 'auth',
      }, operationId: 'op-401');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(result.httpStatus, 401);
      expect(adapter.requests.single.extra, {
        ResponseNormalizeInterceptor.keepSessionOn401: true,
      });
      expect(ApiService.authorization, 't');
    });

    test('other requests still clear the session', () async {
      await ApiService.patch(
        '/api/decks/{id}/card',
        pathParams: {'id': 'deck-1'},
        params: {'card_id': 'auth'},
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(ApiService.authorization, isNot('t'));
    });
  });

  test('ApiService.patch without headers sends no Idempotency-Key', () async {
    await ApiService.patch(
      '/api/decks/{id}/card',
      pathParams: {'id': 'deck-1'},
      params: {'card_id': 'ok'},
    );

    expect(adapter.requests.single.headers, isNot(contains('Idempotency-Key')));
  });

  group('fetchDeckCounts', () {
    test('reads review counters from deck detail stats', () async {
      final counts = await source.fetchDeckCounts('deck-1');

      expect(adapter.requests.single.path, '/api/decks/deck-1');
      expect(counts?.totalReviews, 7);
      expect(counts?.totalReviewsToday, 2);
    });

    test('returns null when the deck detail request fails', () async {
      expect(await source.fetchDeckCounts('missing'), isNull);
    });

    test('uses the injected deck detail function', () async {
      final injected = StudySyncRemoteDataSource(
        deckDetailFn: (id) async => Deck.fromJson({
          'id': id,
          'stats': {'total_reviews': 3, 'total_reviews_today': 1},
        }),
      );

      final counts = await injected.fetchDeckCounts('deck-2');

      expect(counts?.totalReviews, 3);
      expect(counts?.totalReviewsToday, 1);
    });
  });
}
