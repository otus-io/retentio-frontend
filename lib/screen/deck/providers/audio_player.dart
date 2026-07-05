import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/screen/deck/providers/card_audio_mic_handoff.dart';
import 'package:retentio/utils/audio_cache_utils.dart';
import 'package:retentio/utils/log.dart';

final audioPlayerProvider = NotifierProvider(
  AudioPlayerNotifier.new,
  dependencies: [audioUrlProvider],
);
final audioUrlProvider = Provider.autoDispose<String>(
  (ref) => throw UnimplementedError(
    'audioUrlProvider must be overridden in AudioPlayerNotifier',
  ),
);

Future<String> _localAudioCachePath(String audioUrl) async {
  final dir = await getTemporaryDirectory();
  return p.join(dir.path, 'audio', cacheFileNameForAudioUrl(audioUrl));
}

Future<void> _logInvalidAudioFile(String path) async {
  final f = File(path);
  if (!await f.exists()) return;
  final n = await f.length();
  final head = <int>[];
  await for (final chunk in f.openRead(0, 12)) {
    head.addAll(chunk);
    if (head.length >= 12) break;
  }
  final hex = head.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final isFtypM4a = head.length >= 8 && bytesLookLikeIsoBmffFtyp(head);
  logger.e(
    'preparePlayer diagnostics: bytes=$n prefixHex=$hex '
    '${isFtypM4a && n < kMinAudioFileBytesForPlayback ? "(empty M4A shell — no mic audio on Simulator, or upload failed) " : ""}'
    '(JSON error body often starts with 7b22)',
  );
}

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  int? _micHandoffRegId;

  @override
  AudioPlayerState build() {
    final audioUrl = ref.watch(audioUrlProvider);
    final micHandoff = ref.read(cardAudioMicHandoffProvider.notifier);
    _initPlayers();
    _micHandoffRegId = micHandoff.register(() async {
      final c = _player;
      if (c != null) {
        await c.pause();
      }
    });
    _loadAudio(audioUrl);
    ref.onDispose(() {
      logger.w('AudioPlayerNotifier  dispose');
      final id = _micHandoffRegId;
      if (id != null) {
        micHandoff.unregister(id);
      }
      _positionSubscription?.cancel();
      _playerStateSubscription?.cancel();
      _durationSubscription?.cancel();
      unawaited(_player?.dispose());
    });
    return AudioPlayerState(audioUrl: audioUrl);
  }

  void _initPlayers() {
    _player = AudioPlayer();
    _playerStateSubscription = _player?.playerStateStream.listen((playerState) {
      if (ref.mounted) {
        state = state.copyWith(
          isPlaying:
              playerState.playing &&
              playerState.processingState != ProcessingState.completed,
        );
      }
    });
    _positionSubscription = _player?.positionStream.listen((position) {
      if (ref.mounted) {
        state = state.copyWith(positionMs: position.inMilliseconds);
      }
    });
    _durationSubscription = _player?.durationStream.listen((duration) {
      if (ref.mounted && duration != null) {
        state = state.copyWith(maxDurationMs: duration.inMilliseconds);
      }
    });
  }

  Future<void> playPause() async {
    if (state.loadFailed || !state.isReady) return;
    final player = _player;
    if (player == null) return;
    if (state.isPlaying) {
      await player.pause();
      return;
    }
    final atEnd =
        player.processingState == ProcessingState.completed ||
        (state.maxDurationMs > 0 &&
            state.positionMs >= state.maxDurationMs - 200);
    if (atEnd) {
      await player.seek(Duration.zero);
      if (ref.mounted) {
        state = state.copyWith(positionMs: 0);
      }
    }
    await player.play();
  }

  Future<void> seekToMs(int ms) async {
    if (state.loadFailed || !state.isReady) return;
    final max = state.maxDurationMs;
    final clamped = max > 0 ? ms.clamp(0, max) : ms.clamp(0, 1 << 30);
    final player = _player;
    if (player != null) {
      await player.seek(Duration(milliseconds: clamped));
    }
    if (ref.mounted) {
      state = state.copyWith(positionMs: clamped);
    }
  }

  Future<void> _loadAudio(String audioUrl) async {
    try {
      final path = await _localAudioCachePath(audioUrl);
      final cacheFile = File(path);
      final cacheExists = cacheFile.existsSync();
      var cacheBytes = -1;
      if (cacheExists) {
        try {
          cacheBytes = cacheFile.lengthSync();
        } catch (_) {}
      }
      final cacheUsable = cacheExists && cacheBytes > 0;
      if (!cacheUsable) {
        if (cacheExists) {
          try {
            await cacheFile.delete();
          } catch (_) {}
        }
        logger.i("开始下载音频...");
        final file = await ApiService.downloadFile(audioUrl, path);
        logger.i("下载完成: $file");
        if (file == null || file.isEmpty) {
          logger.e("下载失败");
          if (ref.mounted) {
            state = state.copyWith(loadFailed: true);
          }
          return;
        }
      }
      var pathForPlayer = await renameMp3CacheToM4aIfFtyp(path);
      final bytes = await File(pathForPlayer).length();
      if (bytes == 0) {
        logger.w("Audio file is empty: $pathForPlayer");
        if (ref.mounted) {
          state = state.copyWith(loadFailed: true);
        }
        return;
      }
      if (bytes < kMinAudioFileBytesForPlayback) {
        logger.w(
          'Audio file too small ($bytes B), skipping playback. '
          'Use a real device or Simulator → I/O → Microphone, then re-record.',
        );
        if (ref.mounted) {
          state = state.copyWith(loadFailed: true);
        }
        return;
      }
      final max = await _player?.setFilePath(pathForPlayer);
      if (!ref.mounted) return;
      final maxMs = max?.inMilliseconds ?? 0;
      state = state.copyWith(
        isReady: true,
        maxDurationMs: maxMs > 0 ? maxMs : state.maxDurationMs,
        positionMs: 0,
      );
    } catch (e) {
      logger.e(e);
      if (ref.mounted) {
        state = state.copyWith(loadFailed: true);
      }
      try {
        await _logInvalidAudioFile(await _localAudioCachePath(audioUrl));
      } catch (_) {}
    }
  }
}

class AudioPlayerState {
  final String audioUrl;
  final bool isPlaying;
  final bool isReady;

  /// True when the file is missing, empty, too small, or decode/prepare failed.
  final bool loadFailed;

  /// Playback position in milliseconds (last known; kept while paused).
  final int positionMs;

  /// Total duration in milliseconds from native player, or 0 if unknown.
  final int maxDurationMs;

  AudioPlayerState({
    this.audioUrl = '',
    this.isPlaying = false,
    this.isReady = false,
    this.loadFailed = false,
    this.positionMs = 0,
    this.maxDurationMs = 0,
  });

  AudioPlayerState copyWith({
    String? audioUrl,
    bool? isPlaying,
    bool? isReady,
    bool? loadFailed,
    int? positionMs,
    int? maxDurationMs,
  }) => AudioPlayerState(
    audioUrl: audioUrl ?? this.audioUrl,
    isPlaying: isPlaying ?? this.isPlaying,
    isReady: isReady ?? this.isReady,
    loadFailed: loadFailed ?? this.loadFailed,
    positionMs: positionMs ?? this.positionMs,
    maxDurationMs: maxDurationMs ?? this.maxDurationMs,
  );
}
