import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:retentio/models/transcript_sync.dart';
import 'package:retentio/screen/deck/providers/audio_player.dart';
import 'package:retentio/screen/deck/providers/transcript_sync_provider.dart';

/// Overrides for widget tests of transcript + audio UI (no native player).
List<Override> transcriptAudioTestOverrides({
  required String transcriptUrl,
  required String audioUrl,
  AsyncValue<TranscriptSync?> transcriptAsync = const AsyncLoading(),
  int positionMs = 0,
  int maxDurationMs = 120_000,
}) {
  return [
    audioUrlProvider.overrideWithValue(audioUrl),
    audioPlayerProvider.overrideWithBuild((ref, _) {
      ref.watch(audioUrlProvider);
      return AudioPlayerState(
        audioUrl: ref.watch(audioUrlProvider),
        isReady: true,
        positionMs: positionMs,
        maxDurationMs: maxDurationMs,
        loadFailed: false,
      );
    }),
    transcriptSyncProvider(transcriptUrl).overrideWithValue(transcriptAsync),
  ];
}
