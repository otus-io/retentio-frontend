import 'dart:io';

import 'package:path/path.dart' as p;

/// Real clips are larger; Simulator / failed records often upload tiny `ftyp` shells.
const int kMinAudioFileBytesForPlayback = 256;

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
