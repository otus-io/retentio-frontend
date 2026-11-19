import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:retentio/core/network/dio_client.dart';
import 'package:retentio/core/network/download_http2_adapter.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/card_service.dart';

typedef FetchDeckFn = Future<Deck> Function(String deckId);
typedef FetchFactsPageFn =
    Future<OfflineFactsPage> Function(String deckId, int limit, int offset);
typedef FetchCardsFn = Future<List<OfflineCard>> Function(String deckId);

/// Every fact id of the deck, or null when the list could not be read.
typedef FetchFactIdsFn = Future<List<String>?> Function(String deckId);

/// Pinned media versions of one fact, or null when the lookup failed.
typedef FetchMediaVersionsFn =
    Future<Map<String, int>?> Function(String deckId, String factId);

/// Returns the written path, or null/empty when the download failed.
typedef DownloadMediaFn = Future<String?> Function(String url, String path);

/// One part of a media batch, in request order: [bytes] is the file, or null
/// when the server could not serve it (`X-Media-Status` 403 or 404).
typedef MediaBatchPartFn =
    Future<void> Function(String mediaKey, Stream<List<int>>? bytes);

/// Streams the files of [mediaKeys] (`id` or `id?v=N`) through [onPart];
/// throws when the request fails or the response breaks off, after the parts
/// handed over so far.
typedef DownloadMediaBatchFn =
    Future<void> Function(List<String> mediaKeys, MediaBatchPartFn onPart);

class OfflineFactsPage {
  const OfflineFactsPage({
    required this.facts,
    required this.hasMore,
    this.tags = const [],
  });

  final List<OfflineFact> facts;
  final bool hasMore;

  /// Tag objects of the page's facts, possibly repeated.
  final List<Tag> tags;
}

Future<OfflineFactsPage> fetchOfflineFactsPage(
  String deckId,
  int limit,
  int offset,
) async {
  final res = await ApiService.get(
    Api.facts,
    pathParams: {'id': deckId},
    queryParams: {'limit': limit, 'offset': offset},
  );
  return parseOfflineFactsPage(deckId, res?.data, limit: limit);
}

Future<List<String>?> fetchOfflineFactIds(String deckId) async {
  final res = await ApiService.get(Api.factIds, pathParams: {'id': deckId});
  final ids = res != null && res.isSuccess && res.data is Map
      ? (res.data as Map)['fact_ids']
      : null;
  return ids is List ? [for (final id in ids) '$id'] : null;
}

Future<Map<String, int>?> fetchOfflineMediaVersions(
  String deckId,
  String factId,
) async => (await CardService.getFactDetail(deckId, factId))?.mediaVersions;

Future<void> downloadOfflineMediaBatch(
  List<String> mediaKeys,
  MediaBatchPartFn onPart,
) async {
  final res = await networkDioClient.dio.post<ResponseBody>(
    Api.mediaBatch,
    data: {
      'items': [
        for (final key in mediaKeys)
          switch (key.split('?v=')) {
            [final id, final v] => {'id': id, 'v': int.parse(v)},
            _ => {'id': key},
          },
      ],
    },
    options: Options(
      responseType: ResponseType.stream,
      extra: {DownloadHttp2Adapter.extraKey: true},
    ),
  );
  final type = res.headers.value(Headers.contentTypeHeader) ?? '';
  final boundary = RegExp(
    r'^multipart/mixed;\s*boundary="?([^";]+)"?',
  ).firstMatch(type)?.group(1);
  if (boundary == null) throw StateError('media batch is not multipart: $type');
  final reader = _MultipartReader(res.data!.stream, boundary);
  for (
    var h = await reader.nextHeaders();
    h != null;
    h = await reader.nextHeaders()
  ) {
    final id = h['x-media-id'] ?? '';
    final version = h['x-media-version'];
    final key = version == null ? id : '$id?v=$version';
    final bytes = reader.body(h);
    if (h['x-media-status'] == '200') {
      await onPart(key, bytes);
    } else {
      await bytes.drain<void>();
      await onPart(key, null);
    }
  }
}

/// Reads a multipart body whose parts state their `Content-Length` (none
/// means empty), as `POST /api/media/batch` sends it. A boundary-scanning
/// parser leaves the open part hanging when the body breaks off; this one
/// throws.
class _MultipartReader {
  _MultipartReader(Stream<List<int>> body, this.boundary)
    : _chunks = StreamIterator(body);

  final String boundary;
  final StreamIterator<List<int>> _chunks;
  List<int> _chunk = const [];
  var _offset = 0;

  /// The next part's headers with lower-case names, or null after the
  /// closing boundary.
  Future<Map<String, String>?> nextHeaders() async {
    final delimiter = await _line();
    if (delimiter == '--$boundary--') return null;
    if (delimiter != '--$boundary') {
      throw FormatException('bad multipart boundary', delimiter);
    }
    final headers = <String, String>{};
    for (var line = await _line(); line.isNotEmpty; line = await _line()) {
      final colon = line.indexOf(':');
      if (colon < 0) throw FormatException('bad multipart header', line);
      headers[line.substring(0, colon).trim().toLowerCase()] = line
          .substring(colon + 1)
          .trim();
    }
    return headers;
  }

  /// The body of the part [headers] belong to; read it to the end before
  /// asking for the next part.
  Stream<List<int>> body(Map<String, String> headers) async* {
    var left = int.parse(headers['content-length'] ?? '0');
    while (left > 0) {
      await _ensure();
      final end = min(_chunk.length, _offset + left);
      yield _chunk.sublist(_offset, end);
      left -= end - _offset;
      _offset = end;
    }
    final after = await _line();
    if (after.isNotEmpty) {
      throw FormatException('part longer than stated', after);
    }
  }

  /// Bytes up to the next CRLF.
  Future<String> _line() async {
    final bytes = <int>[];
    while (true) {
      if (_offset >= _chunk.length) {
        await _ensure();
      }
      final b = _chunk[_offset++];
      if (b == 0x0A && bytes.isNotEmpty && bytes.last == 0x0D) {
        return latin1.decode(bytes.sublist(0, bytes.length - 1));
      }
      bytes.add(b);
    }
  }

  Future<void> _ensure() async {
    while (_offset >= _chunk.length) {
      if (!await _chunks.moveNext()) {
        throw StateError('media batch cut off');
      }
      _chunk = _chunks.current;
      _offset = 0;
    }
  }
}

Future<List<OfflineCard>> fetchOfflineCards(String deckId) async {
  final res = await ApiService.get(Api.cards, pathParams: {'id': deckId});
  return parseOfflineCards(deckId, res?.data);
}

/// `ApiResponse` drops the envelope `meta`, so `has_more` is inferred from a
/// full page.
OfflineFactsPage parseOfflineFactsPage(
  String deckId,
  dynamic data, {
  required int limit,
}) {
  final rawFacts = data is Map ? data['facts'] : null;
  if (rawFacts is! List) {
    throw StateError('facts response is missing the facts list');
  }
  final pageVersions = (data as Map)['media_versions'];
  final facts = [
    for (final f in rawFacts.whereType<Map>())
      _withListedVersions(
        _parseFact(deckId, Map<String, dynamic>.from(f)),
        f['media_versions'] ?? pageVersions,
      ),
  ];
  return OfflineFactsPage(
    facts: facts,
    hasMore: rawFacts.length >= limit,
    tags: [
      for (final f in rawFacts.whereType<Map>())
        for (final t in (f['tags'] as List? ?? const []).whereType<Map>())
          if (t['id'] != null)
            Tag(
              id: '${t['id']}',
              name: '${t['name'] ?? ''}',
              description: '${t['description'] ?? ''}',
            ),
    ],
  );
}

/// The list endpoint is not documented to return `media_versions`; use them
/// when present, otherwise leave the fact unresolved.
OfflineFact _withListedVersions(OfflineFact fact, dynamic raw) {
  if (raw is! Map) return fact;
  final versions = <String, int>{};
  for (final id in fact.mediaIds) {
    final value = raw[id];
    final v = value is num ? value.toInt() : int.tryParse('$value');
    if (v != null && v > 0) versions[id] = v;
  }
  return fact.withMediaVersions(versions);
}

OfflineFact _parseFact(String deckId, Map<String, dynamic> json) => OfflineFact(
  deckId: deckId,
  id: '${json['id'] ?? ''}',
  entries: [
    for (final e in (json['entries'] as List? ?? const []).whereType<Map>())
      FactEntry.fromJson(Map<String, dynamic>.from(e)),
  ],
  tagIds: [
    for (final t in (json['tags'] as List? ?? const []).whereType<Map>())
      if (t['id'] != null) '${t['id']}',
  ],
);

List<OfflineCard> parseOfflineCards(String deckId, dynamic data) {
  final rawCards = data is Map ? data['cards'] : null;
  if (rawCards is! List) {
    throw StateError('cards response is missing the cards list');
  }
  return [
    for (final c in rawCards.whereType<Map>())
      OfflineCard.fromJson({
        ...Map<String, dynamic>.from(c),
        'deck_id': deckId,
        'dirty': false,
      }),
  ];
}
