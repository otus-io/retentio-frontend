import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Minimal [VideoPlayerPlatform] for tests (pattern from package:video_player tests).
class TestVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _streams = {};
  int _nextId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _nextId++;
    // Single-subscription controller buffers [initialized] until VideoPlayer subscribes
    // (broadcast drops events added before listen).
    final controller = StreamController<VideoEvent>();
    _streams[id] = controller;
    controller.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        size: const Size(100, 100),
        duration: const Duration(seconds: 1),
      ),
    );
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _streams[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    await _streams[playerId]?.close();
    _streams.remove(playerId);
  }

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();
}
