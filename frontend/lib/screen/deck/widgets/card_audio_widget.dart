import 'dart:ui';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wordupx/extensions/context_extension.dart';
import 'package:wordupx/screen/deck/providers/audio_player_provider.dart';

class CardAudioWidget extends StatefulWidget {
  const CardAudioWidget({super.key, required this.audioUrl, this.color});

  final Color? color;
  final String audioUrl;

  @override
  State<CardAudioWidget> createState() => _CardAudioWidgetState();
}

class _CardAudioWidgetState extends State<CardAudioWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ProviderScope(
      overrides: [audioUrlProvider.overrideWithValue(widget.audioUrl)],
      child: Consumer(
        builder: (context, ref, child) {
          final isReady = ref.watch(audioPlayerProvider).isReady;
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
