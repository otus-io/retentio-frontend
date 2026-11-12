import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Serves the endpoints QA mode talks to: fact ids (optionally unverified
/// only), fact detail, fact quality,
/// deck quality stats, and the `fact_edit` contribution POST.
class FakeQaApiAdapter implements HttpClientAdapter {
  FakeQaApiAdapter({
    this.factIds = const ['fact-1', 'fact-2'],
    this.entriesByFactId = const {},
    Map<String, Map<String, dynamic>> qualityByFactId = const {},
    this.mediaVersionsByFactId = const {},
    Map<String, dynamic>? stats,
    this.qualityPutFails = false,
    this.contributionFails = false,
    this.factIdsFails = false,
    Set<String> verifiedFactIds = const {},
  }) : stats = stats == null ? null : Map<String, dynamic>.from(stats),
       qualityByFactId = Map<String, Map<String, dynamic>>.of(qualityByFactId),
       verifiedFactIds = Set<String>.of(verifiedFactIds);

  final List<String> factIds;

  /// Fact id → `entries` payload; missing fact ids answer 404.
  final Map<String, List<Map<String, dynamic>>> entriesByFactId;

  /// Fact id → quality `entries` payload; missing ids answer 404 (no record).
  /// A successful quality PUT stores its entries here, like the server.
  final Map<String, Map<String, dynamic>> qualityByFactId;

  /// When true, `GET …/facts/{id}/quality` answers 500.
  bool qualityGetFails = false;

  /// Fact id → snapshot `media_versions` for that fact's GET response.
  final Map<String, Map<String, int>> mediaVersionsByFactId;

  /// `data` for `/quality/stats`; `null` answers 404. Mutated on quality PUT.
  Map<String, dynamic>? stats;

  bool qualityPutFails;
  bool contributionFails;

  /// When true, `GET …/facts/ids` answers 500.
  bool factIdsFails;

  /// When set, `POST …/contributions/qa-review` answers 400 with this `msg`.
  String? qaReviewError;

  /// How many times `POST …/contributions/qa-review` was hit.
  int qaReviewPosts = 0;

  /// Facts left out of `GET …/facts/ids?unverified_columns=…`. A successful
  /// quality PUT adds its fact, like a server sign-off.
  final Set<String> verifiedFactIds;

  /// `unverified_columns` of each `GET …/facts/ids` (`null` when absent).
  final List<String?> unverifiedColumnsQueries = [];

  final List<Map<String, dynamic>> qualityPuts = [];
  final List<Map<String, dynamic>> contributionPosts = [];
  final List<String> factPatches = [];

  /// How many times `GET …/facts/ids` was hit.
  int factIdsRequestCount = 0;

  /// How many times `GET …/quality/stats` was hit.
  int statsRequestCount = 0;

  /// Optional gate awaited before answering `GET …/quality/stats`.
  /// Used by tests to assert busy stays true during header refresh.
  Future<void>? statsHold;

  Completer<void>? _statsHoldStarted;

  /// Completes the first time [statsHold] is awaited (if set).
  Future<void> get waitUntilStatsHold {
    final existing = _statsHoldStarted;
    if (existing != null) return existing.future;
    final next = Completer<void>();
    _statsHoldStarted = next;
    return next.future;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final method = options.method;

    if (method == 'GET' && path.endsWith('/quality/stats')) {
      statsRequestCount++;
      final hold = statsHold;
      if (hold != null) {
        final started = _statsHoldStarted ??= Completer<void>();
        if (!started.isCompleted) started.complete();
        await hold;
      }
      final data = stats;
      if (data == null) return _error('Quality stats not found', 404);
      return _ok(data);
    }

    if (path.endsWith('/quality')) {
      final factId = _factIdFrom(path, suffix: '/quality');
      if (method == 'PUT') {
        if (qualityPutFails) {
          return _error('fact not in pinned snapshot', 400);
        }
        final body = options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : <String, dynamic>{};
        qualityPuts.add(body);
        verifiedFactIds.add(factId);
        final entries = body['entries'];
        qualityByFactId[factId] = entries is Map
            ? Map<String, dynamic>.from(entries)
            : <String, dynamic>{};
        return _ok({
          'quality': {
            'fact_id': factId,
            'entries': entries is Map
                ? Map<String, dynamic>.from(entries)
                : <String, dynamic>{},
          },
        });
      }
      if (method == 'GET') {
        if (qualityGetFails) return _error('Error retrieving quality', 500);
        final entries = qualityByFactId[factId];
        if (entries == null) return _error('Quality not found', 404);
        return _ok({
          'quality': {'fact_id': factId, 'entries': entries},
        });
      }
    }

    if (method == 'POST' && path.endsWith('/contributions/qa-review')) {
      qaReviewPosts++;
      final error = qaReviewError;
      if (error != null) return _error(error, 400);
      final aspects = _humanAspectCount();
      if (aspects == 0) return _error('nothing to review', 400);
      return _ok({
        'contribution_id': 'qa-1',
        'type': 'qa_review',
        'status': 'open',
        'qa_review': {'facts': verifiedFactIds.length, 'aspects': aspects},
      }, statusCode: 201);
    }

    if (method == 'POST' && path.endsWith('/edit')) {
      if (contributionFails) {
        return _error('daily contribution limit exceeded', 429);
      }
      contributionPosts.add(
        options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : <String, dynamic>{},
      );
      return _ok({'contribution_id': 'cont-1'}, statusCode: 201);
    }

    if (method == 'GET' && path.endsWith('/facts/ids')) {
      factIdsRequestCount++;
      final columns = options.queryParameters['unverified_columns']?.toString();
      unverifiedColumnsQueries.add(columns);
      if (factIdsFails) return _error('Error listing facts', 500);
      return _ok({
        'fact_ids': [
          for (final id in factIds)
            if (columns == null || !verifiedFactIds.contains(id)) id,
        ],
      });
    }

    if (method == 'GET' && path.contains('/facts/')) {
      final factId = path.split('/facts/').last;
      final entries = entriesByFactId[factId];
      if (entries == null) return _error('Fact not found', 404);
      return _ok({
        'fact': {'id': factId, 'entries': entries},
        if (mediaVersionsByFactId[factId] != null)
          'media_versions': mediaVersionsByFactId[factId],
      });
    }

    if (method == 'PATCH' && path.contains('/facts/')) {
      final factId = path.split('/facts/').last;
      factPatches.add(factId);
      return _ok({'fact_id': factId});
    }

    return _error('not found', 404);
  }

  /// Human sign-offs stored on verified facts (what a qa_review would carry).
  int _humanAspectCount() {
    var n = 0;
    for (final id in verifiedFactIds) {
      for (final entry in (qualityByFactId[id] ?? const {}).values) {
        if (entry is! Map) continue;
        for (final aspect in entry.values) {
          if (aspect is Map && aspect['model'] == 'human') n++;
        }
      }
    }
    return n;
  }

  String _factIdFrom(String path, {required String suffix}) {
    return path.substring(0, path.length - suffix.length).split('/facts/').last;
  }

  ResponseBody _ok(Map<String, dynamic> data, {int statusCode = 200}) =>
      _json({'code': 0, 'msg': 'ok', 'data': data}, statusCode);

  ResponseBody _error(String msg, int statusCode) =>
      _json({'code': -1, 'msg': msg}, statusCode);

  ResponseBody _json(Map<String, dynamic> body, int statusCode) =>
      ResponseBody.fromString(
        jsonEncode(body),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
