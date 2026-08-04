import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/services/apis/api_service.dart';

/// Real clips are larger; Simulator / failed records often upload tiny `ftyp` shells.
const int kMinAudioFileBytesForPlayback = 256;

typedef AudioDownloadFn = Future<String?> Function(String url, String path);

String cacheFileNameForAudioUrl(String audioUrl) {
  final uri = Uri.parse(audioUrl);
  var path = uri.path;
  while (path.endsWith('/') && path.isNotEmpty) {
    path = path.substring(0, path.length - 1);
  }
  var baseName = p.basename(path);
  if (baseName.isEmpty || baseName == '/' || baseName == '.') {
    baseName = 'audio_${uri.path.hashCode.abs()}';
  }
  final lower = baseName.toLowerCase();
  return lower.endsWith('.mp3') ||
          lower.endsWith('.m4a') ||
          lower.endsWith('.aac') ||
          lower.endsWith('.wav')
      ? baseName
      : '$baseName.mp3';
}

Future<String> localAudioCachePath(String audioUrl) async {
  final dir = await getTemporaryDirectory();
  return p.join(dir.path, 'audio', cacheFileNameForAudioUrl(audioUrl));
}

/// Downloads in progress, keyed by cache path, so concurrent callers for the
/// same clip share one download instead of writing the same file twice.
final Map<String, Future<String?>> _inFlightDownloads = {};

/// Ensures [audioUrl] is present in the shared temp audio cache.
/// Returns the cache path, or null when the URL is empty or download fails.
Future<String?> ensureAudioCached(
  String audioUrl, {
  AudioDownloadFn? download,
  Future<String> Function(String audioUrl)? cachePath,
}) async {
  final url = audioUrl.trim();
  if (url.isEmpty) return null;

  final path = await (cachePath ?? localAudioCachePath)(url);
  final cacheFile = File(path);
  var cacheBytes = -1;
  if (cacheFile.existsSync()) {
    try {
      cacheBytes = cacheFile.lengthSync();
    } catch (_) {}
  }
  // A partial or truncated file is unplayable, so re-download instead of
  // serving it: a download in flight leaves exactly that behind.
  if (cacheBytes >= kMinAudioFileBytesForPlayback) {
    return path;
  }

  final pending = _inFlightDownloads[path];
  if (pending != null) {
    return pending;
  }
  final operation =
      _downloadToCache(
        url,
        path,
        download ?? ApiService.downloadFile,
      ).whenComplete(() {
        // Must not return the removed future: whenComplete would await itself.
        _inFlightDownloads.remove(path);
      });
  _inFlightDownloads[path] = operation;
  return operation;
}

Future<String?> _downloadToCache(
  String url,
  String path,
  AudioDownloadFn download,
) async {
  final cacheFile = File(path);
  if (cacheFile.existsSync()) {
    try {
      await cacheFile.delete();
    } catch (_) {}
  }
  final file = await download(url, path);
  if (file == null || file.isEmpty) {
    return null;
  }
  return path;
}

/// Distinct non-empty audio item URLs on [card] front and back.
List<String> audioUrlsOnCard(Card card) {
  final urls = <String>{};
  for (final slot in [...card.front, ...card.back]) {
    for (final item in slot.items) {
      if (item.type != 'audio') continue;
      final value = item.value.trim();
      if (value.isNotEmpty) urls.add(value);
    }
  }
  return urls.toList(growable: false);
}

/// Best-effort cache fill for every audio URL on [card]. Failures are ignored.
Future<void> prefetchCardAudio(
  Card card, {
  AudioDownloadFn? download,
  Future<String> Function(String audioUrl)? cachePath,
}) async {
  for (final url in audioUrlsOnCard(card)) {
    try {
      await ensureAudioCached(url, download: download, cachePath: cachePath);
    } catch (_) {}
  }
}

/// True if [head] has at least 8 bytes and bytes 4–7 spell `ftyp` (ISO BMFF).
bool bytesLookLikeIsoBmffFtyp(List<int> head) {
  if (head.length < 8) return false;
  return head[4] == 0x66 &&
      head[5] == 0x74 &&
      head[6] == 0x79 &&
      head[7] == 0x70;
}

/// If we cached as .mp3 but bytes are ISO-BMFF (`ftyp`), rename to .m4a for AVFoundation.
Future<String> renameMp3CacheToM4aIfFtyp(String path) async {
  if (!path.toLowerCase().endsWith('.mp3')) return path;
  final f = File(path);
  if (!await f.exists()) return path;
  final head = <int>[];
  await for (final chunk in f.openRead(0, 12)) {
    head.addAll(chunk);
    if (head.length >= 12) break;
  }
  if (!bytesLookLikeIsoBmffFtyp(head)) {
    return path;
  }
  final m4aPath = '${path.substring(0, path.length - 4)}.m4a';
  try {
    await f.rename(m4aPath);
    return m4aPath;
  } catch (_) {
    return path;
  }
}
