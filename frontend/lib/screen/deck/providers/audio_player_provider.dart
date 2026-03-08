import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wordupx/services/apis/api_service.dart';
import 'package:wordupx/utils/log.dart';

final audioPlayerProvider = NotifierProvider(
  AudioPlayerNotifier.new,
  dependencies: [audioUrlProvider],
);
final audioUrlProvider = Provider.autoDispose<String>(
  (ref) => throw UnimplementedError(
    'audioUrlProvider must be overridden in AudioPlayerNotifier',
  ),
);

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  // late AudioPlayer? _justAudioPlayer;

  late PlayerController? _waveformController;
  late StreamSubscription<PlayerState>? _playerStateSubscription;

  PlayerController get waveformController => _waveformController!;

  @override
  AudioPlayerState build() {
    final audioUrl = ref.watch(audioUrlProvider);
    _initPlayers();
    _loadAudio();
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
    _waveformController = PlayerController();
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
    if (!state.isReady) return;
    if (state.isPlaying == true) {
      await _waveformController?.pausePlayer();
    } else {
      await _waveformController?.startPlayer();
    }
    _waveformController?.setFinishMode(finishMode: .pause);
  }

  Future<void> _loadAudio() async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/audio/${state.audioUrl.split('/').last}.mp3';
      if (!File(path).existsSync()) {
        logger.i("开始下载音频...");
        final file = await ApiService.downloadFile(state.audioUrl, path);
        logger.i("下载完成: $file");
        if (file?.isEmpty == true) {
          logger.e("下载失败");
          return;
        }
      }
      //  await _justAudioPlayer?.setFilePath(path);
      await _waveformController?.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
      );
      _waveformController?.waveformExtraction
          .extractWaveformData(path: path, noOfSamples: 100)
          .then(
            (waveformData) =>
                state = state.copyWith(isReady: true, waveform: waveformData),
          );
    } catch (e) {
      logger.e(e);
    }
  }
}

class AudioPlayerState {
  final String audioUrl;
  final bool isPlaying;
  final bool isReady;
  final List<double> waveform;

  AudioPlayerState({
    this.audioUrl = '',
    this.isPlaying = false,
    this.isReady = false,
    this.waveform = const [],
  });

  AudioPlayerState copyWith({
    String? audioUrl,
    bool? isPlaying,
    bool? isReady,
    List<double>? waveform,
  }) => AudioPlayerState(
    audioUrl: audioUrl ?? this.audioUrl,
    isPlaying: isPlaying ?? this.isPlaying,
    isReady: isReady ?? this.isReady,
    waveform: waveform ?? this.waveform,
  );
}
