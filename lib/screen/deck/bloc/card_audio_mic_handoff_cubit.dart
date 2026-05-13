import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lets [FactAdd]/[FactEdit] stop every active card player and briefly
/// deactivate the iOS audio session before mic capture.
class CardAudioMicHandoffCubit extends Cubit<int> {
  CardAudioMicHandoffCubit() : super(0);

  int _nextId = 0;
  final Map<int, Future<void> Function()> _pausers = <int, Future<void> Function()>{};

  int register(Future<void> Function() stopPlaybackForMic) {
    final id = _nextId++;
    _pausers[id] = stopPlaybackForMic;
    return id;
  }

  void unregister(int id) {
    _pausers.remove(id);
  }

  Future<void> pauseAllForMic() async {
    for (final fn in _pausers.values.toList()) {
      try {
        await fn();
      } catch (_) {
        // best-effort stop before mic
      }
    }
    if (kIsWeb || !Platform.isIOS) {
      return;
    }
    try {
      final session = await AudioSession.instance;
      await session.setActive(
        false,
        avAudioSessionSetActiveOptions:
            AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
    } catch (_) {}
  }
}
