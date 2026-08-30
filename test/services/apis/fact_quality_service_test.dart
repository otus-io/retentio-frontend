import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/fact_quality_service.dart';
import 'package:retentio/services/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_qa_api_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeQaApiAdapter adapter;

  void useAdapter(FakeQaApiAdapter next) {
    adapter = next;
    networkDioClient.dio.httpClientAdapter = adapter;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.clearToken();
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
    useAdapter(
      FakeQaApiAdapter(
        qualityByFactId: {
          'fact-1': {
            '0': {
              'text': {'score': 10, 'model': 'human'},
            },
          },
        },
        stats: {'verified_aspects': 3, 'total_aspects': 8, 'columns': {}},
      ),
    );
  });

  group('Api quality routes', () {
    test('point at the documented endpoints', () {
      expect(Api.factQuality, '/api/decks/{id}/facts/{factId}/quality');
      expect(Api.deckQualityStats, '/api/decks/{id}/quality/stats');
      expect(Api.factIds, '/api/decks/{id}/facts/ids');
    });
  });

  group('FactQualityService.getFactQuality', () {
    test('parses a stored record', () async {
      final quality = await FactQualityService.of.getFactQuality(
        deckId: 'imp-1',
        factId: 'fact-1',
      );

      expect(quality, isNotNull);
      expect(quality!.aspectsAt(0)['text']!.isHuman, isTrue);
    });

    test('returns null when the fact has no record (404)', () async {
      final quality = await FactQualityService.of.getFactQuality(
        deckId: 'imp-1',
        factId: 'fact-2',
      );

      expect(quality, isNull);
    });

    test('returns null when the payload has no quality object', () async {
      networkDioClient.dio.httpClientAdapter = _StaticAdapter(
        data: {'unexpected': true},
      );

      final quality = await FactQualityService.of.getFactQuality(
        deckId: 'imp-1',
        factId: 'fact-1',
      );

      expect(quality, isNull);
    });

    test('returns null when the request fails at transport level', () async {
      networkDioClient.dio.httpClientAdapter = _ThrowingAdapter();

      final quality = await FactQualityService.of.getFactQuality(
        deckId: 'imp-1',
        factId: 'fact-1',
      );

      expect(quality, isNull);
    });
  });

  group('FactQualityService.getDeckQualityStats', () {
    test('parses deck counters', () async {
      final stats = await FactQualityService.of.getDeckQualityStats('imp-1');

      expect(stats?.verifiedAspects, 3);
      expect(stats?.totalAspects, 8);
    });

    test('returns null when stats are unavailable', () async {
      useAdapter(FakeQaApiAdapter());

      expect(await FactQualityService.of.getDeckQualityStats('imp-1'), isNull);
    });

    test('returns null when the request fails at transport level', () async {
      networkDioClient.dio.httpClientAdapter = _ThrowingAdapter();

      expect(await FactQualityService.of.getDeckQualityStats('imp-1'), isNull);
    });
  });

  group('FactQualityService.putFactQuality', () {
    test('sends the entries body', () async {
      await FactQualityService.of.putFactQuality(
        deckId: 'imp-1',
        factId: 'fact-1',
        entries: {
          '0': {
            'text': {'score': 10, 'model': 'human'},
          },
        },
      );

      expect(adapter.qualityPuts, hasLength(1));
      expect(adapter.qualityPuts.first['entries'], contains('0'));
    });

    test('throws the API message on failure', () async {
      useAdapter(FakeQaApiAdapter(qualityPutFails: true));

      expect(
        () => FactQualityService.of.putFactQuality(
          deckId: 'imp-1',
          factId: 'fact-1',
          entries: const {'0': <String, dynamic>{}},
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('fact not in pinned snapshot'),
          ),
        ),
      );
    });
  });
}

/// Answers every request with the same `data` payload.
class _StaticAdapter implements HttpClientAdapter {
  _StaticAdapter({required this.data});

  final Map<String, dynamic> data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'code': 0, 'msg': 'ok', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw StateError('boom');
  }

  @override
  void close({bool force = false}) {}
}
