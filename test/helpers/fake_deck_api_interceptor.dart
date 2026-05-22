import 'package:dio/dio.dart';
import 'package:retentio/core/network/network.dart';

/// Intercepts deck list/create API calls for [DeckListScreen] / [DeckCreate] tests.
class FakeDeckApiInterceptor extends Interceptor {
  final List<Map<String, dynamic>> _decks = [];

  List<Map<String, dynamic>> get decks => List.unmodifiable(_decks);

  static bool _isDeckListPath(String path) {
    return path == '/api/decks' || path.endsWith('/api/decks');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.uri.path;

    if (options.method == 'GET' && _isDeckListPath(path)) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'msg': 'ok',
            'data': {'decks': _decks},
          },
        ),
      );
      return;
    }

    if (options.method == 'POST' && _isDeckListPath(path)) {
      final body = options.data;
      final map = body is Map<String, dynamic>
          ? body
          : (body is Map
                ? Map<String, dynamic>.from(body)
                : <String, dynamic>{});
      final name = map['name']?.toString() ?? 'deck';
      final deck = {
        'id': 'deck-${_decks.length + 1}',
        'name': name,
        'rate': map['rate'] ?? 30,
        'fields': map['fields'] ?? <String>[],
        'stats': {
          'cards_count': 0,
          'facts_count': 0,
          'unseen_cards': 0,
          'reviewed_cards': 0,
          'due_cards': 0,
          'hidden_cards': 0,
          'new_cards_today': 0,
          'last_reviewed_at': 0,
        },
        'min_interval': 60,
        'def_interval': 300,
        'max_interval': 86400,
        'owner': {'username': 'test', 'email': 'test@example.com'},
      };
      _decks.add(deck);
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'msg': 'ok',
            'data': {'deck_id': deck['id']},
          },
        ),
      );
      return;
    }

    handler.next(options);
  }
}

Interceptor attachFakeDeckApiInterceptor() {
  final interceptor = FakeDeckApiInterceptor();
  networkDioClient.dio.interceptors.add(interceptor);
  return interceptor;
}

void detachFakeDeckApiInterceptor(Interceptor interceptor) {
  networkDioClient.dio.interceptors.remove(interceptor);
}
