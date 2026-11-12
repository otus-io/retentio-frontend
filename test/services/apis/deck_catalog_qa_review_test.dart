import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/models/qa_review_preview.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers each request with [status] and [body]; records method, path, data.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

  _ScriptedAdapter use(int status, Map<String, dynamic> body) {
    final adapter = _ScriptedAdapter(status, body);
    networkDioClient.dio.httpClientAdapter = adapter;
    return adapter;
  }

  group('submitQAReview', () {
    test('posts to the import deck and returns the summary', () async {
      final adapter = use(201, {
        'code': 0,
        'data': {
          'contribution_id': 'c1',
          'type': 'qa_review',
          'qa_review': {'facts': 3, 'aspects': 5},
        },
      });

      final summary = await DeckCatalogService.of.submitQAReview(
        importDeckId: 'imp-1',
        message: '  walked it  ',
      );

      expect(summary.facts, 3);
      expect(summary.aspects, 5);
      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.path, endsWith('/api/decks/imp-1/contributions/qa-review'));
      expect(req.data, {'message': 'walked it'});
    });

    test('sends no message when blank', () async {
      final adapter = use(201, {
        'code': 0,
        'data': {
          'qa_review': {'facts': 1, 'aspects': 1},
        },
      });
      await DeckCatalogService.of.submitQAReview(
        importDeckId: 'imp-1',
        message: ' ',
      );
      expect(adapter.requests.single.data, isEmpty);
    });

    test('throws the API message on failure', () async {
      use(400, {'code': -1, 'msg': 'nothing to review'});
      expect(
        () => DeckCatalogService.of.submitQAReview(importDeckId: 'imp-1'),
        throwsA(
          isA<Exception>().having(
            (e) => '$e',
            'msg',
            contains('nothing to review'),
          ),
        ),
      );
    });

    test('throws when a success lacks the summary', () async {
      use(201, {
        'code': 0,
        'data': {'contribution_id': 'c1'},
      });
      expect(
        () => DeckCatalogService.of.submitQAReview(importDeckId: 'imp-1'),
        throwsException,
      );
    });
  });

  group('getQAReviewPreview', () {
    test('reads the preview on the source deck', () async {
      final adapter = use(200, {
        'code': 0,
        'data': {
          'summary': {'ready': 1, 'changed': 0, 'verified': 0, 'removed': 0},
          'facts': [
            {
              'fact_id': 'fa',
              'preview': 'Apple',
              'aspects': [
                {'entry': 0, 'aspect': 'text', 'status': 'ready'},
              ],
            },
          ],
        },
      });

      final preview = await DeckCatalogService.of.getQAReviewPreview(
        sourceDeckId: 'src-1',
        contributionId: 'c1',
      );

      expect(preview.count(QAReviewItemStatus.ready), 1);
      expect(preview.facts.single.factId, 'fa');
      expect(
        adapter.requests.single.path,
        endsWith('/api/decks/src-1/contributions/c1/qa-review'),
      );
    });

    test('throws the API message on failure', () async {
      use(403, {'code': -1, 'msg': 'Not authorized'});
      expect(
        () => DeckCatalogService.of.getQAReviewPreview(
          sourceDeckId: 'src-1',
          contributionId: 'c1',
        ),
        throwsA(
          isA<Exception>().having((e) => '$e', 'msg', contains('Not author')),
        ),
      );
    });
  });
}
