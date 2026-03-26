import 'dart:ui';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/screen/deck/providers/audio_player.dart';

class CardAudio extends StatefulWidget {
  const CardAudio({super.key, required this.audioUrl, this.color});

  final Color? color;
  final String audioUrl;

  @override
  State<CardAudio> createState() => _CardAudioState();
}

class _CardAudioState extends State<CardAudio>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ProviderScope(
      overrides: [audioUrlProvider.overrideWithValue(widget.audioUrl)],
      child: Consumer(
        builder: (context, ref, child) {
          final audioState = ref.watch(audioPlayerProvider);
          if (audioState.loadFailed) {
            return SizedBox(
              width: context.width,
              height: 50,
              child: Tooltip(
                message: context.loc.cardAudioUnavailable,
                child: Center(
                  child: Icon(
                    LucideIcons.volumeX,
                    size: 28,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ),
            );
          }
          final isReady = audioState.isReady;
          return Stack(
            alignment: Alignment.center,
            children: [
              !isReady
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : AudioFileWaveforms(
                      size: Size(context.width, 50),
                      playerController: ref
                          .watch(audioPlayerProvider.notifier)
                          .waveformController,
                      waveformData: ref.watch(
                        audioPlayerProvider.select((value) => value.waveform),
                      ),
                      waveformType: WaveformType.fitWidth,
                      playerWaveStyle: PlayerWaveStyle(
                        fixedWaveColor: Colors.grey,
                        liveWaveColor: widget.color ?? Colors.blue,
                        spacing: 6,
                        waveThickness: 3,
                      ),
                    ),
              if (!ref.watch(
                    audioPlayerProvider.select((value) => value.isPlaying),
                  ) &&
                  isReady) ...[
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: SizedBox(),
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.all(10),
                  iconSize: 30,
                  color: widget.color,
                  onPressed: ref.read(audioPlayerProvider.notifier).playPause,
                  icon: Icon(LucideIcons.play),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
