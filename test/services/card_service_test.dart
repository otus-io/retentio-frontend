import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/card_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCardHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isCardPatch =
        options.method == 'PATCH' &&
        options.path.contains('/api/decks/') &&
        options.path.endsWith('/card');
    if (!isCardPatch) {
      return _jsonResponse({'code': -1, 'msg': 'not found', 'data': null}, 404);
    }

    final body = options.data is Map<String, dynamic>
        ? options.data as Map<String, dynamic>
        : <String, dynamic>{};
    final cardId = body['card_id']?.toString();

    switch (cardId) {
      case 'success':
        return _jsonResponse({
          'code': 0,
          'msg': 'Card interval updated successfully',
          'data': {'last_review': 1, 'due_date': 151, 'new_interval': 150},
        }, 200);
      case 'empty-map':
        return _jsonResponse({
          'code': 0,
          'msg': 'ok',
          'data': <String, dynamic>{},
        }, 200);
      case 'empty-list':
        return _jsonResponse({
          'code': 0,
          'msg': 'ok',
          'data': <dynamic>[],
        }, 200);
      case 'null-data':
        return _jsonResponse({'code': 0, 'msg': 'ok'}, 200);
      case 'failure-with-data':
        return _jsonResponse({
          'code': -1,
          'msg': 'rejected',
          'data': {'reason': 'conflict'},
        }, 200);
      case 'bad-request':
        return _jsonResponse({
          'msg': 'last_review cannot be in the future',
        }, 400);
      default:
        return _jsonResponse({
          'code': -1,
          'msg': 'unknown card_id',
          'data': null,
        }, 404);
    }
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CardService.updateCard', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiService.clearToken();

      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      networkDioClient.dio.httpClientAdapter = _FakeCardHttpClientAdapter();
    });

    test('returns true when patch succeeds with non-empty data', () async {
      final result = await CardService.updateCard('deck-1', {
        'card_id': 'success',
        'interval': 150,
        'last_review': 1,
      });

      expect(result, isTrue);
    });

    test('returns null when response data is an empty map', () async {
      final result = await CardService.updateCard('deck-1', {
        'card_id': 'empty-map',
        'interval': 150,
        'last_review': 1,
      });

      expect(result, isNull);
    });

    test('returns null when response data is an empty list', () async {
      final result = await CardService.updateCard('deck-1', {
        'card_id': 'empty-list',
        'interval': 150,
        'last_review': 1,
      });

      expect(result, isNull);
    });

    test('returns null when response data is missing', () async {
      final result = await CardService.updateCard('deck-1', {
        'card_id': 'null-data',
        'interval': 150,
        'last_review': 1,
      });

      expect(result, isNull);
    });

    test(
      'returns false when response has data but is not successful',
      () async {
        final result = await CardService.updateCard('deck-1', {
          'card_id': 'failure-with-data',
          'interval': 150,
          'last_review': 1,
        });

        expect(result, isFalse);
      },
    );

    test(
      'returns null on 400 without throwing when error response has no data',
      () async {
        final result = await CardService.updateCard('deck-1', {
          'card_id': 'bad-request',
          'interval': 150,
          'last_review': 1782999334,
        });

        expect(result, isNull);
      },
    );
  });
}
