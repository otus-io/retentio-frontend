import 'package:dio/dio.dart';
import 'package:retentio/core/network/network.dart';

/// Serves deck list and review-by-day responses for statistics widget tests.
class FakeStatisticsApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.uri.path;
    if (options.method == 'GET' && _isDeckList(path)) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'msg': 'ok',
            'data': {
              'decks': [_deck],
            },
          },
        ),
      );
      return;
    }

    if (options.method == 'GET' && path.endsWith('/reviews/by-day')) {
      final days = int.parse('${options.queryParameters['days']}');
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'code': 0, 'msg': 'ok', 'data': _reviewData(days)},
        ),
      );
      return;
    }

    handler.next(options);
  }
}

bool _isDeckList(String path) =>
    path == '/api/decks' || path.endsWith('/api/decks');

Map<String, dynamic> _reviewData(int days) {
  return {
    'timezone': 'UTC',
    'days': List.generate(days, (index) {
      final day = DateTime.utc(
        2026,
        9,
        19,
      ).subtract(Duration(days: days - index - 1));
      final month = day.month.toString().padLeft(2, '0');
      final dayOfMonth = day.day.toString().padLeft(2, '0');
      return {'day': '${day.year}$month$dayOfMonth', 'count': 1};
    }),
  };
}

const _deck = {
  'id': 'deck-1',
  'name': 'Deck 1',
  'rate': 30,
  'fields': ['Front', 'Back'],
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

FakeStatisticsApiInterceptor attachFakeStatisticsApiInterceptor() {
  final interceptor = FakeStatisticsApiInterceptor();
  networkDioClient.dio.interceptors.add(interceptor);
  return interceptor;
}

void detachFakeStatisticsApiInterceptor(
  FakeStatisticsApiInterceptor interceptor,
) {
  networkDioClient.dio.interceptors.remove(interceptor);
}
