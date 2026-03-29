import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/models/transcript_sync.dart';

final transcriptSyncProvider = FutureProvider.autoDispose
    .family<TranscriptSync?, String>((ref, url) async {
      if (url.isEmpty) return null;
      return fetchTranscriptSync(url);
    });
