import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/services/apis/review_stats_service.dart';
import 'package:retentio/services/index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
  });

  test('uses the documented route and days query parameter', () async {
    final adapter = _ReviewStatsAdapter();
    networkDioClient.dio.httpClientAdapter = adapter;

    final result = await ReviewStatsService.of.getByDay(
      deckId: 'deck-1',
      days: 7,
    );

    expect(Api.reviewsByDay, '/api/decks/{id}/reviews/by-day');
    expect(adapter.lastRequest?.path, '/api/decks/deck-1/reviews/by-day');
    expect(adapter.lastRequest?.queryParameters['days'], 7);
    expect(result.days, hasLength(7));
  });

  test('rejects unsupported ranges before making a request', () {
    expect(
      () => ReviewStatsService.of.getByDay(deckId: 'deck-1', days: 14),
      throwsArgumentError,
    );
  });

  test('throws the API message on 400, 403, 404, and 500 responses', () async {
    for (final status in [400, 403, 404, 500]) {
      networkDioClient.dio.httpClientAdapter = _ReviewStatsAdapter(
        statusCode: status,
        message: 'failure-$status',
      );
      await expectLater(
        ReviewStatsService.of.getByDay(deckId: 'deck-1', days: 7),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('failure-$status'),
          ),
        ),
      );
    }
  });

  test('rejects malformed successful payloads', () async {
    networkDioClient.dio.httpClientAdapter = _ReviewStatsAdapter(
      data: {
        'timezone': 'UTC',
        'days': [
          {'day': 'bad-date', 'count': 1},
        ],
      },
    );

    await expectLater(
      ReviewStatsService.of.getByDay(deckId: 'deck-1', days: 7),
      throwsFormatException,
    );
  });
}

class _ReviewStatsAdapter implements HttpClientAdapter {
  _ReviewStatsAdapter({this.statusCode = 200, this.message = 'ok', this.data});

  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final responseData =
        data ??
        {
          'timezone': 'UTC',
          'days': List.generate(7, (index) {
            final day = DateTime.utc(2026, 9, 13).add(Duration(days: index));
            return {
              'day':
                  '${day.year}${day.month.toString().padLeft(2, '0')}'
                  '${day.day.toString().padLeft(2, '0')}',
              'count': index,
            };
          }),
        };
    return ResponseBody.fromString(
      jsonEncode({'code': 0, 'msg': message, 'data': responseData}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
