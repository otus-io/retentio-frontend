import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:retentio/services/apis/api_service.dart';
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

/// Real clips are larger; Simulator / failed records often upload ~28 B `ftyp` shells.
const int _kMinAudioFileBytes = 256;

String _cacheFileNameForAudioUrl(String audioUrl) {
  final uri = Uri.parse(audioUrl);
  var baseName = p.basename(uri.path);
  if (baseName.isEmpty) {
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

Future<String> _localAudioCachePath(String audioUrl) async {
  final dir = await getTemporaryDirectory();
  return p.join(dir.path, 'audio', _cacheFileNameForAudioUrl(audioUrl));
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
  final isFtypM4a =
      head.length >= 12 &&
      head[4] == 0x66 &&
      head[5] == 0x74 &&
      head[6] == 0x79 &&
      head[7] == 0x70;
  logger.e(
    'preparePlayer diagnostics: bytes=$n prefixHex=$hex '
    '${isFtypM4a && n < _kMinAudioFileBytes ? "(empty M4A shell — no mic audio on Simulator, or upload failed) " : ""}'
    '(JSON error body often starts with 7b22)',
  );
}

/// If we cached as .mp3 but bytes are ISO-BMFF (`ftyp`), rename to .m4a for AVFoundation.
Future<String> _renameMp3CacheToM4aIfFtyp(String path) async {
  if (!path.toLowerCase().endsWith('.mp3')) return path;
  final f = File(path);
  if (!await f.exists()) return path;
  final head = <int>[];
  await for (final chunk in f.openRead(0, 12)) {
    head.addAll(chunk);
    if (head.length >= 12) break;
  }
  if (head.length < 8 ||
      head[4] != 0x66 ||
      head[5] != 0x74 ||
      head[6] != 0x79 ||
      head[7] != 0x70) {
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

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  // late AudioPlayer? _justAudioPlayer;

  late PlayerController? _waveformController;
  late StreamSubscription<PlayerState>? _playerStateSubscription;

  PlayerController get waveformController => _waveformController!;

  @override
  AudioPlayerState build() {
    final audioUrl = ref.watch(audioUrlProvider);
    _initPlayers();
    // Do not read [state] inside _loadAudio until after this method returns — Riverpod
    // leaves the notifier uninitialized until [build] completes.
    _loadAudio(audioUrl);
    ref.onDispose(() {
      logger.w('AudioPlayerNotifier  dispose');
      // _justAudioPlayer?.dispose();
      _playerStateSubscription?.cancel();
      _waveformController?.dispose();
    });
    return AudioPlayerState(audioUrl: audioUrl);
  }

  void _initPlayers() {
    //  _justAudioPlayer = AudioPlayer();
    _waveformController = PlayerController()..overrideAudioSession = true;
    _playerStateSubscription = _waveformController?.onPlayerStateChanged.listen(
      (playerState) {
        if (ref.mounted) {
          state = state.copyWith(isPlaying: playerState == PlayerState.playing);
          if (playerState == PlayerState.paused) {
            _waveformController?.seekTo(0);
          }
        }
      },
    );
  }

  // 播放/暂停控制
  Future<void> playPause() async {
    if (state.loadFailed || !state.isReady) return;
    if (state.isPlaying == true) {
      await _waveformController?.pausePlayer();
    } else {
      await _waveformController?.startPlayer();
    }
    _waveformController?.setFinishMode(finishMode: .pause);
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
      var pathForPlayer = await _renameMp3CacheToM4aIfFtyp(path);
      final bytes = await File(pathForPlayer).length();
      if (bytes == 0) {
        logger.w("Audio file is empty: $pathForPlayer");
        if (ref.mounted) {
          state = state.copyWith(loadFailed: true);
        }
        return;
      }
      if (bytes < _kMinAudioFileBytes) {
        // Not an app bug: e.g. Simulator mic off → empty M4A shell on server (~28 B `ftyp`).
        logger.w(
          'Audio file too small ($bytes B), skipping playback. '
          'Use a real device or Simulator → I/O → Microphone, then re-record.',
        );
        if (ref.mounted) {
          state = state.copyWith(loadFailed: true);
        }
        return;
      }
      //  await _justAudioPlayer?.setFilePath(path);
      await _waveformController?.preparePlayer(
        path: pathForPlayer,
        shouldExtractWaveform: true,
      );
      _waveformController?.waveformExtraction
          .extractWaveformData(path: pathForPlayer, noOfSamples: 100)
          .then((waveformData) {
            if (!ref.mounted) return;
            state = state.copyWith(isReady: true, waveform: waveformData);
          });
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

  AudioPlayerState({
    this.audioUrl = '',
    this.isPlaying = false,
    this.isReady = false,
    this.loadFailed = false,
    this.waveform = const [],
  });

  AudioPlayerState copyWith({
    String? audioUrl,
    bool? isPlaying,
    bool? isReady,
    bool? loadFailed,
    List<double>? waveform,
  }) => AudioPlayerState(
    audioUrl: audioUrl ?? this.audioUrl,
    isPlaying: isPlaying ?? this.isPlaying,
    isReady: isReady ?? this.isReady,
    loadFailed: loadFailed ?? this.loadFailed,
    waveform: waveform ?? this.waveform,
  );
}
