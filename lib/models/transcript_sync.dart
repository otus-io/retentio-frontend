import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:retentio/services/apis/api_service.dart';

const String kRetentioTranscriptSyncFormat = 'retentio-transcript-sync';

class TranscriptWord {
  const TranscriptWord({
    required this.word,
    required this.start,
    required this.end,
  });

  final String word;
  final double start;
  final double end;
}

/// Word-level timings for audio sync (`retentio-transcript-sync` JSON from media).
class TranscriptSync {
  TranscriptSync({required this.words, this.annotatedSourceText});

  final List<TranscriptWord> words;

  /// Optional `text` field from transcript JSON (`[[kanji|reading]]` markup). Used to
  /// render furigana when it aligns exactly with [words].
  final String? annotatedSourceText;

  /// Last word index with `start <= t`, or -1 if before first word.
  int wordIndexAt(double tSeconds) {
    if (words.isEmpty) return -1;
    var lo = 0;
    var hi = words.length - 1;
    var best = -1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      if (words[mid].start <= tSeconds) {
        best = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return best;
  }

  /// Next word start in ms strictly after [positionMs], or null if none.
  int? seekMsNextFrom(int positionMs) {
    if (words.isEmpty) return null;
    const slopMs = 25;
    for (final w in words) {
      final startMs = (w.start * 1000).round();
      if (startMs > positionMs + slopMs) return startMs;
    }
    return null;
  }

  /// Seek target for “previous word”: start of current word if already past it, else previous word (or 0).
  int seekMsPrevFrom(int positionMs) {
    if (words.isEmpty) return 0;
    final t = positionMs / 1000.0;
    final i = wordIndexAt(t);
    if (i < 0) return 0;
    final w = words[i];
    const deepIntoWordSec = 0.08;
    if (t - w.start > deepIntoWordSec) {
      return (w.start * 1000).round();
    }
    if (i > 0) {
      return (words[i - 1].start * 1000).round();
    }
    return 0;
  }

  static TranscriptSync? tryParse(String jsonStr) {
    try {
      final dynamic root = json.decode(jsonStr);
      if (root is! Map<String, dynamic>) return null;
      final format = root['format'];
      if (format != kRetentioTranscriptSyncFormat) return null;
      final rawWords = root['words'];
      if (rawWords is! List || rawWords.isEmpty) return null;
      final out = <TranscriptWord>[];
      for (final e in rawWords) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final w = m['word'];
        if (w is! String) continue;
        final start = _asDouble(m['start']);
        final end = _asDouble(m['end']);
        out.add(TranscriptWord(word: w, start: start, end: end));
      }
      if (out.isEmpty) return null;
      String? annotated;
      final textField = root['text'];
      if (textField is String && textField.trim().isNotEmpty) {
        annotated = textField;
      }
      return TranscriptSync(words: out, annotatedSourceText: annotated);
    } catch (_) {
      return null;
    }
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

Future<String> _localTranscriptPath(String url) async {
  final dir = await getTemporaryDirectory();
  return p.join(dir.path, 'transcript', 'tr_${url.hashCode.abs()}.json');
}

/// Downloads once per URL (cached under temp), then parses [TranscriptSync].
Future<TranscriptSync?> fetchTranscriptSync(String url) async {
  if (url.isEmpty) return null;
  final path = await _localTranscriptPath(url);
  final file = File(path);
  if (!await file.exists()) {
    final saved = await ApiService.downloadFile(url, path);
    if (saved == null || saved.isEmpty) return null;
  }
  try {
    final text = await file.readAsString();
    return TranscriptSync.tryParse(text);
  } catch (_) {
    return null;
  }
}
