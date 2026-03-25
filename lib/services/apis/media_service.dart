import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:retentio/services/index.dart';

/// Matches API §5: image 5 MB; audio/video 200 MB.
enum MediaSlotKind { image, video, audio }

enum MediaPrecheck { ok, fileNotFound, unknownType, wrongType, fileTooLarge }

class MediaService {
  MediaService._();

  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int maxAudioVideoBytes = 200 * 1024 * 1024;

  static int maxBytesFor(MediaSlotKind kind) =>
      kind == MediaSlotKind.image ? maxImageBytes : maxAudioVideoBytes;

  /// Classify by file extension (client-side hint only).
  static MediaSlotKind? classifyFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    const images = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
    const audio = {'mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac', 'opus'};
    const video = {'mp4', 'mov', 'webm', 'mkv', 'qt'};
    if (images.contains(ext)) return MediaSlotKind.image;
    if (video.contains(ext)) return MediaSlotKind.video;
    if (audio.contains(ext)) return MediaSlotKind.audio;
    return null;
  }

  static Future<MediaPrecheck> precheckSlot(
    MediaSlotKind slot,
    String filePath,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return MediaPrecheck.fileNotFound;
    final kind = classifyFile(filePath);
    if (kind == null) return MediaPrecheck.unknownType;
    if (kind != slot) return MediaPrecheck.wrongType;
    final len = await file.length();
    if (len > maxBytesFor(slot)) return MediaPrecheck.fileTooLarge;
    return MediaPrecheck.ok;
  }

  static String? _contentTypeForPath(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
        return 'audio/ogg';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
      case '.qt':
        return 'video/quicktime';
      case '.webm':
        return 'video/webm';
      default:
        return null;
    }
  }

  /// Returns media id, or `null` if upload failed.
  static Future<String?> upload({
    required String filePath,
    required MediaSlotKind slotKind,
    String? clientId,
    void Function(int count, int total)? onSendProgress,
  }) async {
    final check = await precheckSlot(slotKind, filePath);
    if (check != MediaPrecheck.ok) return null;

    final name = p.basename(filePath);
    final res = await dioClient.uploadFile(
      Api.media,
      filePath: filePath,
      fileName: name,
      contentType: _contentTypeForPath(filePath),
      clientId: clientId,
      onSendProgress: onSendProgress,
    );
    if (res?.isSuccess != true || res?.data == null) return null;
    final data = res!.data;
    if (data is Map && data['id'] != null) {
      return data['id'].toString();
    }
    return null;
  }
}
