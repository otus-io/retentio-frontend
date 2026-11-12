import 'package:retentio/models/catalog_deck.dart';
import 'package:retentio/models/deck_contribution.dart';
import 'package:retentio/models/qa_review_preview.dart';
import 'package:retentio/models/deck_updates.dart';
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
      throw Exception(res?.msg ?? 'Unknown error');
    }

    return DeckUpdatesResult.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<DeckUpdatesSummary> getDeckUpdatesSummary(String deckId) async {
    final res = await ApiService.get(
      Api.deckUpdates,
      pathParams: {'id': deckId},
      queryParams: {'summary': '1'},
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'Unknown error');
    }
    return DeckUpdatesSummary.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<DeckUpdateFactDetail> getDeckUpdateFact({
    required String deckId,
    required String factId,
  }) async {
    final res = await ApiService.get(
      Api.deckUpdateFact,
      pathParams: {'id': deckId, 'factId': factId},
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'Unknown error');
    }
    return DeckUpdateFactDetail.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<int> syncDeck(
    String deckId, {
    int? targetVersion,
    List<SyncFactDecision>? decisions,
  }) async {
    final body = <String, dynamic>{};
    if (targetVersion != null) {
      body['target_version'] = targetVersion;
    }
    if (decisions != null && decisions.isNotEmpty) {
      body['decisions'] = decisions.map((d) => d.toJson()).toList();
    }
    final res = await ApiService.post(
      Api.deckSync,
      pathParams: {'id': deckId},
      body: body,
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'Unknown error');
    }
    return _toInt((res.data as Map)['source_version']) ?? 0;
  }

  Future<String?> submitFactReport({
    required String importDeckId,
    required String factId,
    required String message,
  }) {
    return _submitContribution(
      Api.deckFactReport,
      pathParams: {'id': importDeckId, 'factId': factId},
      body: {'message': message},
    );
  }

  /// Freezes current private overlay as a `fact_edit` contribution.
  Future<String?> submitFactEditContribution({
    required String importDeckId,
    required String factId,
    String? message,
    int? entryIndex,
  }) {
    final body = <String, dynamic>{};
    if (message != null && message.trim().isNotEmpty) {
      body['message'] = message.trim();
    }
    if (entryIndex != null) {
      body['entry_index'] = entryIndex;
    }
    return _submitContribution(
      Api.deckFactEditContribution,
      pathParams: {'id': importDeckId, 'factId': factId},
      body: body,
    );
  }

  /// Submits a `local_facts` row as `fact_add`.
  Future<String?> submitFactAddContribution({
    required String importDeckId,
    required String factId,
    String? message,
  }) {
    final body = <String, dynamic>{};
    if (message != null && message.trim().isNotEmpty) {
      body['message'] = message.trim();
    }
    return _submitContribution(
      Api.deckFactAddContribution,
      pathParams: {'id': importDeckId, 'factId': factId},
      body: body,
    );
  }

  Future<String?> submitFactTagsContribution({
    required String importDeckId,
    required String factId,
    List<String>? addTags,
    List<String>? removeTags,
    String? message,
  }) {
    return _submitContribution(
      Api.deckFactTagsContribution,
      pathParams: {'id': importDeckId, 'factId': factId},
      body: _tagContributionBody(
        addTags: addTags,
        removeTags: removeTags,
        message: message,
      ),
    );
  }

  Future<String?> submitDeckTagsContribution({
    required String importDeckId,
    List<String>? addTags,
    List<String>? removeTags,
    String? message,
  }) {
    return _submitContribution(
      Api.deckTagsContribution,
      pathParams: {'id': importDeckId},
      body: _tagContributionBody(
        addTags: addTags,
        removeTags: removeTags,
        message: message,
      ),
    );
  }

  /// Asks the author to adopt this importer's QA sign-offs (`qa_review`).
  /// Refreshes the importer's open request when one exists. Throws with the
  /// API `msg` (e.g. `nothing to review`) on failure.
  Future<QAReviewSummary> submitQAReview({
    required String importDeckId,
    String? message,
  }) async {
    final body = <String, dynamic>{
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
    };
    final res = await ApiService.post(
      Api.deckQAReviewContribution,
      pathParams: {'id': importDeckId},
      body: body,
    );
    final summary = res?.data is Map
        ? QAReviewSummary.tryParse((res!.data as Map)['qa_review'])
        : null;
    if (res == null || !res.isSuccess || summary == null) {
      throw Exception(res?.msg ?? 'submit_contribution_failed');
    }
    return summary;
  }

  /// Author: live status of each sign-off in a `qa_review` request.
  Future<QAReviewPreview> getQAReviewPreview({
    required String sourceDeckId,
    required String contributionId,
  }) async {
    final res = await ApiService.get(
      Api.deckQAReviewPreview,
      pathParams: {'id': sourceDeckId, 'contributionId': contributionId},
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'qa_review_preview_failed');
    }
    return QAReviewPreview.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<DeckContributionsPage> listContributions(
    String sourceDeckId, {
    String? status,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    // One extra row tells whether another page exists (`meta.has_more` is not
    // kept on ApiResponse).
    final query = <String, dynamic>{
      'limit': limit + 1,
      'offset': offset,
      if (status != null && status.isNotEmpty) 'status': status,
      if (type != null && type.isNotEmpty) 'type': type,
    };
    final res = await ApiService.get(
      Api.deckContributions,
      pathParams: {'id': sourceDeckId},
      queryParams: query,
    );
    if (res == null || !res.isSuccess) {
      throw Exception(res?.msg ?? 'list_contributions_failed');
    }
    final data = res.data;
    final list = <DeckContribution>[];
    if (data is Map && data['contributions'] is List) {
      for (final item in data['contributions'] as List) {
        if (item is Map) {
          final raw = Map<String, dynamic>.from(item);
          raw.putIfAbsent('source_deck_id', () => sourceDeckId);
          list.add(DeckContribution.fromJson(raw));
        }
      }
    }
    final hasMore = list.length > limit;
    final page = hasMore ? list.sublist(0, limit) : list;
    return DeckContributionsPage(
      contributions: page,
      total: page.length,
      hasMore: hasMore,
    );
  }

  Future<DeckContribution> acceptContribution({
    required String sourceDeckId,
    required String contributionId,
  }) async {
    final res = await ApiService.post(
      Api.deckContributionAccept,
      pathParams: {'id': sourceDeckId, 'contributionId': contributionId},
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'accept_contribution_failed');
    }
    return DeckContribution.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<DeckContribution> patchContributionStatus({
    required String sourceDeckId,
    required String contributionId,
    required String status,
  }) async {
    final res = await ApiService.patch(
      Api.deckContribution,
      pathParams: {'id': sourceDeckId, 'contributionId': contributionId},
      params: {'status': status},
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'patch_contribution_failed');
    }
    final data = res.data as Map;
    final contrib = data['contribution'];
    final raw = contrib is Map ? contrib : data;
    return DeckContribution.fromJson(Map<String, dynamic>.from(raw));
  }

  /// Returns the new `contribution_id` when the API includes it in `data`.
  Future<String?> _submitContribution(
    String path, {
    required Map<String, String> pathParams,
    required Map<String, dynamic> body,
  }) async {
    final res = await ApiService.post(path, pathParams: pathParams, body: body);
    if (res == null || !res.isSuccess) {
      throw Exception(res?.msg ?? 'submit_contribution_failed');
    }
    final data = res.data;
    if (data is Map) {
      final id = data['contribution_id']?.toString().trim() ?? '';
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  Map<String, dynamic> _tagContributionBody({
    List<String>? addTags,
    List<String>? removeTags,
    String? message,
  }) {
    final body = <String, dynamic>{};
    if (addTags != null && addTags.isNotEmpty) {
      body['add_tags'] = addTags;
    }
    if (removeTags != null && removeTags.isNotEmpty) {
      body['remove_tags'] = removeTags;
    }
    if (message != null && message.trim().isNotEmpty) {
      body['message'] = message.trim();
    }
    return body;
  }

  int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
