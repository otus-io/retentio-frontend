import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Serves the endpoints QA mode talks to: fact list, fact detail, fact quality,
/// deck quality stats, and the `fact_edit` contribution POST.
class FakeQaApiAdapter implements HttpClientAdapter {
  FakeQaApiAdapter({
    this.factIds = const ['fact-1', 'fact-2'],
    this.entriesByFactId = const {},
    this.qualityByFactId = const {},
    this.mediaVersionsByFactId = const {},
    this.stats,
    this.qualityPutFails = false,
    this.contributionFails = false,
  });

  final List<String> factIds;

  /// Fact id → `entries` payload; missing fact ids answer 404.
  final Map<String, List<Map<String, dynamic>>> entriesByFactId;

  /// Fact id → quality `entries` payload; missing ids answer 404 (no record).
  final Map<String, Map<String, dynamic>> qualityByFactId;

  /// Fact id → snapshot `media_versions` for that fact's GET response.
  final Map<String, Map<String, int>> mediaVersionsByFactId;

  /// `data` for `/quality/stats`; `null` answers 404.
  final Map<String, dynamic>? stats;

  bool qualityPutFails;
  bool contributionFails;

  final List<Map<String, dynamic>> qualityPuts = [];
  final List<Map<String, dynamic>> contributionPosts = [];
  final List<String> factPatches = [];

  /// `offset` of every fact list request, in order.
  final List<int> factListOffsets = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final method = options.method;

    if (method == 'GET' && path.endsWith('/quality/stats')) {
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
        final entries = body['entries'];
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
        final entries = qualityByFactId[factId];
        if (entries == null) return _error('Quality not found', 404);
        return _ok({
          'quality': {'fact_id': factId, 'entries': entries},
        });
      }
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

    if (method == 'GET' && path.endsWith('/facts')) {
      final query = options.queryParameters;
      final limit = int.tryParse('${query['limit']}') ?? factIds.length;
      final offset = int.tryParse('${query['offset']}') ?? 0;
      factListOffsets.add(offset);
      final page = offset >= factIds.length
          ? const <String>[]
          : factIds.sublist(offset, min(offset + limit, factIds.length));
      return _ok({
        'facts': [
          for (final id in page) {'id': id},
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
