import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/screen/deck/providers/audio_player.dart';

class CardAudio extends StatefulWidget {
  const CardAudio({
    super.key,
    required this.audioUrl,
    this.color,
    this.compact = false,
  });

  final Color? color;
  final String audioUrl;

  /// Icon-only control for the field tab bar (next to the note icon); no waveform.
  final bool compact;

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
            final failIcon = Icon(
              LucideIcons.volumeX,
              size: widget.compact ? 20 : 28,
              color: Theme.of(context).disabledColor,
            );
            return widget.compact
                ? Tooltip(
                    message: context.loc.cardAudioUnavailable,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: failIcon,
                    ),
                  )
                : SizedBox(
                    height: 50,
                    child: Tooltip(
                      message: context.loc.cardAudioUnavailable,
                      child: Center(child: failIcon),
                    ),
                  );
          }
          final isReady = audioState.isReady;
          final isPlaying = ref.watch(
            audioPlayerProvider.select((value) => value.isPlaying),
          );
          final accent = widget.color ?? Colors.blue;
          if (!isReady) {
            return widget.compact
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : const SizedBox(
                    height: 50,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
          }
          if (widget.compact) {
            return IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              iconSize: 22,
              color: accent,
              onPressed: ref.read(audioPlayerProvider.notifier).playPause,
              icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play),
            );
          }
          return SizedBox(
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  padding: const EdgeInsets.all(8),
                  iconSize: 28,
                  color: accent,
                  onPressed: ref.read(audioPlayerProvider.notifier).playPause,
                  icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return AudioFileWaveforms(
                        size: Size(constraints.maxWidth, 50),
                        playerController: ref
                            .watch(audioPlayerProvider.notifier)
                            .waveformController,
                        waveformData: ref.watch(
                          audioPlayerProvider.select((value) => value.waveform),
                        ),
                        waveformType: WaveformType.fitWidth,
                        playerWaveStyle: PlayerWaveStyle(
                          fixedWaveColor: Colors.grey,
                          liveWaveColor: accent,
                          spacing: 6,
                          waveThickness: 3,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
