import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  PlayerController? _waveformController;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int>? _positionSubscription;
  int? _micHandoffRegId;

  PlayerController get waveformController => _waveformController!;

  @override
  AudioPlayerState build() {
    final audioUrl = ref.watch(audioUrlProvider);
    _initPlayers();
    _micHandoffRegId = ref.read(cardAudioMicHandoffProvider.notifier).register(
      () async {
        final c = _waveformController;
        if (c != null) {
          await c.stopPlayer();
        }
      },
    );
    _loadAudio(audioUrl);
    ref.onDispose(() {
      logger.w('AudioPlayerNotifier  dispose');
      final id = _micHandoffRegId;
      if (id != null) {
        ref.read(cardAudioMicHandoffProvider.notifier).unregister(id);
      }
      _positionSubscription?.cancel();
      _playerStateSubscription?.cancel();
      _waveformController?.dispose();
    });
    return AudioPlayerState(audioUrl: audioUrl);
  }

  void _initPlayers() {
    _waveformController = PlayerController()
      // false: do not force .playback AVAudioSession; RecorderController needs
      // .playAndRecord when adding facts over an open card (see audio_waveforms).
      ..overrideAudioSession = false
      ..updateFrequency = UpdateFrequency.medium;
    _playerStateSubscription = _waveformController?.onPlayerStateChanged.listen(
      (playerState) {
        if (ref.mounted) {
          state = state.copyWith(isPlaying: playerState == PlayerState.playing);
        }
      },
    );
    _positionSubscription = _waveformController?.onCurrentDurationChanged
        .listen((ms) {
          if (ref.mounted) {
            state = state.copyWith(positionMs: ms);
          }
        });
  }

  Future<void> playPause() async {
    if (state.loadFailed || !state.isReady) return;
    if (state.isPlaying == true) {
      await _waveformController?.pausePlayer();
    } else {
      await _waveformController?.startPlayer();
    }
    _waveformController?.setFinishMode(finishMode: FinishMode.pause);
  }

  Future<void> seekToMs(int ms) async {
    if (state.loadFailed || !state.isReady) return;
    final max = state.maxDurationMs;
    final clamped = max > 0 ? ms.clamp(0, max) : ms.clamp(0, 1 << 30);
    final c = _waveformController;
    if (c != null) {
      await c.seekTo(clamped);
    }
    if (ref.mounted) {
      state = state.copyWith(positionMs: clamped);
    }
  }

  Future<void> skipSeconds(int deltaSeconds) async {
    final next = state.positionMs + deltaSeconds * 1000;
    await seekToMs(next);
  }

  Future<void> _loadAudio(String audioUrl) async {
    try {
      final path = await _localAudioCachePath(audioUrl);
      if (!File(path).existsSync()) {
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
      await _waveformController?.preparePlayer(
        path: pathForPlayer,
        shouldExtractWaveform: false,
      );
      if (!ref.mounted) return;
      final maxMs =
          await _waveformController?.getDuration(DurationType.max) ?? -1;
      state = state.copyWith(
        isReady: true,
        maxDurationMs: maxMs > 0 ? maxMs : state.maxDurationMs,
      );

      unawaited(
        _waveformController?.waveformExtraction
            .extractWaveformData(path: pathForPlayer, noOfSamples: 100)
            .then((waveformData) {
              if (!ref.mounted) return;
              state = state.copyWith(waveform: waveformData);
            }),
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
  final List<double> waveform;

  /// Playback position in milliseconds (last known; kept while paused).
  final int positionMs;

  /// Total duration in milliseconds from native player, or 0 if unknown.
  final int maxDurationMs;

  AudioPlayerState({
    this.audioUrl = '',
    this.isPlaying = false,
    this.isReady = false,
    this.loadFailed = false,
    this.waveform = const [],
    this.positionMs = 0,
    this.maxDurationMs = 0,
  });

  AudioPlayerState copyWith({
    String? audioUrl,
    bool? isPlaying,
    bool? isReady,
    bool? loadFailed,
    List<double>? waveform,
    int? positionMs,
    int? maxDurationMs,
  }) => AudioPlayerState(
    audioUrl: audioUrl ?? this.audioUrl,
    isPlaying: isPlaying ?? this.isPlaying,
    isReady: isReady ?? this.isReady,
    loadFailed: loadFailed ?? this.loadFailed,
    waveform: waveform ?? this.waveform,
    positionMs: positionMs ?? this.positionMs,
    maxDurationMs: maxDurationMs ?? this.maxDurationMs,
  );
}
