import 'dart:typed_data';

import 'package:wordupx/models/media.dart';
import 'package:wordupx/models/res_base_model.dart';
import 'package:wordupx/services/index.dart';
import 'api_service.dart';

class MediaService {
  /// Upload a file. Returns created media metadata or null on failure.
  /// After upload, use MediaService.forFact(media) to get entryValue ([audio:id] / [image:id])
  /// and fieldNameSuffix (audio / img) for fact entries and field names.
  static Future<MediaItem?> upload(
    String filePath, {
    String? fileName,
    String? clientId,
    void Function(int count, int total)? onSendProgress,
  }) async {
    final res = await dioClient.uploadFile(
      Api.media,
      filePath: filePath,
      fileName: fileName,
      onSendProgress: onSendProgress,
    );
    if (res?.isSuccess != true || res?.data is! Map) return null;
    return MediaItem.fromJson(Map<String, dynamic>.from(res!.data as Map));
  }

  /// Entry value and field name suffix for adding this media to a fact.
  /// [entryValue] is [audio:id] or [image:id]; [fieldNameSuffix] is "audio" or "img".
  static ({String entryValue, String fieldNameSuffix}) forFact(
    MediaItem media,
  ) => (
    entryValue: media.entryPlaceholder,
    fieldNameSuffix: media.fieldNameSuffix,
  );

  /// List user media. Optional since (unix ts), limit, offset.
  static Future<List<MediaItem>> list({
    int? since,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{};
    if (since != null) queryParams['since'] = since;
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    final res = await ApiService.get(
      Api.media,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    if (res?.isSuccess != true) return [];
    final data = res!.data;
    if (data is! List) return [];
    return data
        .map((e) => e is Map<String, dynamic> ? MediaItem.fromJson(e) : null)
        .whereType<MediaItem>()
        .toList();
  }

  /// Download media file as bytes. Uses GET /api/media/{id} (binary).
  static Future<Uint8List?> download(String mediaId) async {
    final path = '/api/media/$mediaId';
    try {
      return await dioClient.getImageUint8ListFrom(path);
    } catch (_) {
      return null;
    }
  }

  /// Delete media by ID.
  static Future<ResBaseModel?> delete(String mediaId) async {
    return ApiService.delete(Api.mediaById, pathParams: {'id': mediaId});
  }
}
