import 'package:retentio/models/publish_preview.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';

class DeckPublishResult {
  const DeckPublishResult({required this.publishedVersion});
  final int publishedVersion;
}

class DeckPublishService {
  static final DeckPublishService of = DeckPublishService._();
  DeckPublishService._();

  /// 将卡组发布到 catalog，使其对所有用户可见。需要鉴权。
  Future<DeckPublishResult> publishDeck(
    String deckId, {
    String visibility = 'public',
  }) async {
    final res = await ApiService.post(
      Api.deckPublish,
      pathParams: {'id': deckId},
      body: {'visibility': visibility},
    );
    if (res == null) {
      throw Exception('Publish failed');
    }
    if (!res.isSuccess) {
      throw Exception(res.msg);
    }

    final data = res.data;
    int version = 1;
    if (data is Map) {
      final v = data['published_version'] ?? data['version'];
      if (v is int) version = v;
      if (v is num) version = v.toInt();
    }
    return DeckPublishResult(publishedVersion: version);
  }

  /// Author: working copy vs last publish. Pass [detail] for id/preview rows.
  Future<PublishPreview> getPublishPreview(
    String deckId, {
    bool detail = false,
  }) async {
    final res = await ApiService.get(
      Api.deckPublishPreview,
      pathParams: {'id': deckId},
      queryParams: detail ? {'detail': '1'} : null,
    );
    if (res == null || !res.isSuccess || res.data is! Map) {
      throw Exception(res?.msg ?? 'Unknown error');
    }
    return PublishPreview.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}
