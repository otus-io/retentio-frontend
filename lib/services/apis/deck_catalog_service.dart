import 'package:retentio/models/catalog_deck.dart';
import 'package:retentio/models/import_deck_result.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';

class CatalogMeta {
  const CatalogMeta({required this.total, required this.hasMore});

  final int total;
  final bool hasMore;
}

class CatalogPage {
  const CatalogPage({required this.decks, required this.meta});

  final List<CatalogDeck> decks;
  final CatalogMeta meta;
}

class DeckUpdatesResult {
  const DeckUpdatesResult({
    required this.sourceVersion,
    required this.latestVersion,
    required this.addedFacts,
    required this.removedFacts,
    required this.editedFacts,
    required this.mediaChanges,
  });

  final int sourceVersion;
  final int latestVersion;
  final int addedFacts;
  final int removedFacts;
  final int editedFacts;
  final int mediaChanges;

  bool get hasUpdates =>
      latestVersion > sourceVersion ||
      addedFacts > 0 ||
      removedFacts > 0 ||
      editedFacts > 0 ||
      mediaChanges > 0;
}

class DeckCatalogService {
  static final DeckCatalogService of = DeckCatalogService._();
  DeckCatalogService._();

  /// 目录列表，支持分页与搜索。不需要鉴权。
  Future<CatalogPage> getCatalog({
    int limit = 20,
    int offset = 0,
    String? query,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (query != null && query.isNotEmpty) 'query': query,
    };
    final res = await ApiService.get(Api.deckCatalog, queryParams: params);
    final data = res?.data;
    if (data is! Map) {
      return const CatalogPage(
        decks: [],
        meta: CatalogMeta(total: 0, hasMore: false),
      );
    }

    final rawDecks = data['decks'] as List? ?? [];
    final decks = rawDecks
        .map((e) => CatalogDeck.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawMeta = data['meta'] as Map? ?? {};
    final total = _toInt(rawMeta['total']) ?? 0;
    final hasMore =
        rawMeta['has_more'] == true ||
        rawMeta['has_more'] == 'true' ||
        (total > offset + decks.length);

    return CatalogPage(
      decks: decks,
      meta: CatalogMeta(total: total, hasMore: hasMore),
    );
  }

  /// 单条目录详情。不需要鉴权。
  Future<CatalogDeck?> getCatalogDeck(String id) async {
    final res = await ApiService.get(
      Api.deckCatalogById,
      pathParams: {'id': id},
    );
    final data = res?.data;
    if (data is! Map) return null;
    return CatalogDeck.fromJson(Map<String, dynamic>.from(data));
  }

  /// 导入共享卡组。需要鉴权（401 由 ApiService 拦截）。
  /// 抛出 [Exception] 携带 API `msg` 字符串（供 cubit 捕获并传递给 UI 层）。
  Future<ImportDeckResult> importDeck(String sourceDeckId) async {
    final res = await ApiService.post(
      Api.deckImport,
      body: {'source_deck_id': sourceDeckId},
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'import_failed');
    }
    return ImportDeckResult.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<DeckUpdatesResult> getDeckUpdates(String deckId) async {
    final res = await ApiService.get(
      Api.deckUpdates,
      pathParams: {'id': deckId},
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'updates_failed');
    }

    final data = Map<String, dynamic>.from(res.data as Map);
    return DeckUpdatesResult(
      sourceVersion: _toInt(data['source_version']) ?? 0,
      latestVersion: _toInt(data['latest_version']) ?? 0,
      addedFacts: _toInt(data['added_facts']) ?? 0,
      removedFacts: _toInt(data['removed_facts']) ?? 0,
      editedFacts: _toInt(data['edited_facts']) ?? 0,
      mediaChanges: _toInt(data['media_changes']) ?? 0,
    );
  }

  Future<int> syncDeck(String deckId, {int? targetVersion}) async {
    final body = <String, dynamic>{};
    if (targetVersion != null) {
      body['target_version'] = targetVersion;
    }
    final res = await ApiService.post(
      Api.deckSync,
      pathParams: {'id': deckId},
      body: body,
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'sync_failed');
    }
    return _toInt((res.data as Map)['source_version']) ?? 0;
  }

  Future<void> submitFeedback({
    required String importDeckId,
    required String factId,
    required String message,
    String category = 'other',
  }) async {
    final res = await ApiService.post(
      Api.deckFeedback,
      pathParams: {'id': importDeckId},
      body: {'fact_id': factId, 'category': category, 'message': message},
    );
    if (res == null || !res.isSuccess) {
      throw Exception(res?.msg ?? 'submit_feedback_failed');
    }
  }

  int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
