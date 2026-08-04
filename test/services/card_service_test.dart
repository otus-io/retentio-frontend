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

/// Serves GET `/api/decks/{id}/card` payloads keyed by deck id.
class _FakeNextCardHttpClientAdapter implements HttpClientAdapter {
  _FakeNextCardHttpClientAdapter(this.dataByDeckId);

  final Map<String, Map<String, dynamic>> dataByDeckId;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final deckId = options.path
        .split('/api/decks/')
        .last
        .replaceAll('/card', '');
    final data = dataByDeckId[deckId];
    if (options.method != 'GET' || data == null) {
      return _jsonResponse({'code': -1, 'msg': 'not found', 'data': null}, 404);
    }
    return _jsonResponse({'code': 0, 'msg': 'ok', 'data': data}, 200);
  }

  @override
  void close({bool force = false}) {}
}

/// Serves GET `/api/decks/{id}` deck detail payloads keyed by deck id.
class _FakeDeckDetailHttpClientAdapter implements HttpClientAdapter {
  _FakeDeckDetailHttpClientAdapter(this.dataByDeckId);

  final Map<String, Map<String, dynamic>> dataByDeckId;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final deckId = options.path.split('/api/decks/').last;
    final data = dataByDeckId[deckId];
    if (options.method != 'GET' || data == null) {
      return _jsonResponse({'code': -1, 'msg': 'not found', 'data': null}, 404);
    }
    return _jsonResponse({'code': 0, 'msg': 'ok', 'data': data}, 200);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _deckPayload({
  required int cardsCount,
  required int dueCards,
}) => {
  'id': 'deck-1',
  'name': 'Deck one',
  'rate': 30,
  'fields': <String>[],
  'stats': {
    'cards_count': cardsCount,
    'facts_count': 4,
    'unseen_cards': 2,
    'reviewed_cards': cardsCount - 2,
    'due_cards': dueCards,
    'hidden_cards': 0,
    'new_cards_today': 0,
    'last_reviewed_at': 0,
  },
  'min_interval': 60,
  'def_interval': 300,
  'max_interval': 86400,
};

Map<String, dynamic> _cardPayload(String id) => {
  'id': id,
  'fact_id': 'fact-$id',
  'template': [
    [0],
    [1],
  ],
  'last_review': 1763269700,
  'due_date': 1763269800,
  'hidden': false,
  'created_at': 1763269600,
  'front': [
    {'text': 'front-$id'},
  ],
  'back': [
    {'text': 'back-$id'},
  ],
};

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

  group('CardService.getNextDueCard', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiService.clearToken();

      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      networkDioClient.dio.httpClientAdapter = _FakeNextCardHttpClientAdapter({
        'empty-deck': {'card': <dynamic>[]},
        'single-card': {'card': _cardPayload('only'), 'urgency': 1.0},
        'two-cards': {
          'card': _cardPayload('first'),
          'urgency': 2.0,
          'next_card': {..._cardPayload('second'), 'urgency': 0.5},
        },
      });
    });

    test('returns no cards for an empty deck', () async {
      final result = await CardService.getNextDueCard('empty-deck');

      expect(result.cardDetail, isNull);
      expect(result.nextCardDetail, isNull);
    });

    test('returns no lookahead when the deck has a single card', () async {
      final result = await CardService.getNextDueCard('single-card');

      expect(result.cardDetail?.card.id, 'only');
      expect(result.nextCardDetail, isNull);
    });

    test('parses next_card with its own urgency', () async {
      final result = await CardService.getNextDueCard('two-cards');

      expect(result.cardDetail?.card.id, 'first');
      expect(result.cardDetail?.urgency, 2.0);
      expect(result.nextCardDetail?.card.id, 'second');
      expect(result.nextCardDetail?.urgency, 0.5);
    });

    test('returns no cards when the request fails', () async {
      final result = await CardService.getNextDueCard('missing-deck');

      expect(result.cardDetail, isNull);
      expect(result.nextCardDetail, isNull);
    });
  });

  group('CardService.getCardsStats without a tag filter', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiService.clearToken();

      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      networkDioClient.dio.httpClientAdapter = _FakeDeckDetailHttpClientAdapter(
        {'deck-1': _deckPayload(cardsCount: 12, dueCards: 5)},
      );
    });

    test('maps deck detail stats to cards and due counts', () async {
      final stats = await CardService.getCardsStats('deck-1');

      expect(stats?.totalCards, 12);
      expect(stats?.dueCards, 5);
    });

    test('returns null when the deck detail request fails', () async {
      final stats = await CardService.getCardsStats('missing-deck');

      expect(stats, isNull);
    });
  });
}
