import 'package:retentio/models/api_response.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';

class TagService {
  static final TagService of = TagService._();
  TagService._();

  /// 创建标签
  Future<ApiResponse?> createTag({
    required String name,
    String description = '',
  }) async {
    return ApiService.post(
      Api.tags,
      body: {'name': name, 'description': description},
    );
  }

  /// 列出标签，可按场景过滤
  /// [usedOn]: 'fact' | 'deck' | null（全量）
  /// [deckId]: used_on=fact 时必传
  /// [unused]: only with used_on=fact — `exclude` | `only` (omit = facts-in-deck + globally unused)
  Future<List<Tag>> getTags({
    String? usedOn,
    String? deckId,
    String? unused,
  }) async {
    if (usedOn == 'fact' && (deckId == null || deckId.trim().isEmpty)) {
      throw ArgumentError.value(
        deckId,
        'deckId',
        'deckId is required when usedOn is fact',
      );
    }
    try {
      final query = <String, dynamic>{
        'used_on': ?usedOn,
        'deck_id': ?deckId,
        'unused': ?unused,
      };
      final res = await ApiService.get(
        Api.tags,
        queryParams: query.isEmpty ? null : query,
      );
      final data = res?.data;
      if (data is Map && data['tags'] is List) {
        return (data['tags'] as List)
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// 获取单个标签
  Future<Tag?> getTag(String tagId) async {
    try {
      final res = await ApiService.get(Api.tag, pathParams: {'tagId': tagId});
      final data = res?.data;
      if (data is Map && data['tag'] is Map) {
        return Tag.fromJson(Map<String, dynamic>.from(data['tag'] as Map));
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// 更新标签
  Future<ApiResponse?> updateTag(
    String tagId, {
    String? name,
    String? description,
  }) async {
    final body = <String, dynamic>{'name': ?name, 'description': ?description};
    return ApiService.patch(
      Api.tag,
      pathParams: {'tagId': tagId},
      params: body,
    );
  }

  /// 删除标签
  Future<ApiResponse?> deleteTag(String tagId) async {
    return ApiService.delete(Api.tag, pathParams: {'tagId': tagId});
  }

  // ── Deck <-> Tag ──────────────────────────────────────────

  /// 关联标签到卡组（幂等 PUT，无 body）
  Future<List<Tag>> addTagToDeck(String deckId, String tagId) async {
    try {
      final res = await ApiService.put(
        Api.deckTag,
        pathParams: {'id': deckId, 'tagId': tagId},
      );
      return _parseTags(res?.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 从卡组移除标签
  Future<List<Tag>> removeTagFromDeck(String deckId, String tagId) async {
    try {
      final res = await ApiService.delete(
        Api.deckTag,
        pathParams: {'id': deckId, 'tagId': tagId},
      );
      return _parseTags(res?.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 列出卡组上的所有标签
  Future<List<Tag>> getDeckTags(String deckId) async {
    try {
      final res = await ApiService.get(
        Api.deckTags,
        pathParams: {'id': deckId},
      );
      return _parseTags(res?.data);
    } catch (e) {
      rethrow;
    }
  }

  // ── Fact <-> Tag ──────────────────────────────────────────

  /// 关联标签到词条（幂等 PUT，无 body）
  Future<List<Tag>> addTagToFact(
    String deckId,
    String factId,
    String tagId,
  ) async {
    try {
      final res = await ApiService.put(
        Api.factTag,
        pathParams: {'id': deckId, 'factId': factId, 'tagId': tagId},
      );
      return _parseTags(res?.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 从词条移除标签
  Future<List<Tag>> removeTagFromFact(
    String deckId,
    String factId,
    String tagId,
  ) async {
    try {
      final res = await ApiService.delete(
        Api.factTag,
        pathParams: {'id': deckId, 'factId': factId, 'tagId': tagId},
      );
      return _parseTags(res?.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 列出词条上的所有标签
  Future<List<Tag>> getFactTags(String deckId, String factId) async {
    try {
      final res = await ApiService.get(
        Api.factTags,
        pathParams: {'id': deckId, 'factId': factId},
      );
      return _parseTags(res?.data);
    } catch (e) {
      rethrow;
    }
  }

  // ── Tag -> Facts ──────────────────────────────────────────

  /// Cross-deck `{deck_id, fact_id}` pairs for facts with this tag.
  Future<List<TagFactRef>> getTagFacts(String tagId) async {
    try {
      final res = await ApiService.get(
        Api.tagFacts,
        pathParams: {'tagId': tagId},
      );
      final data = res?.data;
      if (data is Map && data['facts'] is List) {
        return (data['facts'] as List)
            .whereType<Map>()
            .map((e) => TagFactRef.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // ── helpers ───────────────────────────────────────────────

  List<Tag> _parseTags(dynamic data) {
    if (data is Map && data['tags'] is List) {
      return (data['tags'] as List)
          .map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
