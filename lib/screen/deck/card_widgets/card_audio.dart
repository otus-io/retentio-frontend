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
    this.useExternalScope = false,
  });

  final Color? color;
  final String audioUrl;

  /// Icon-only control for the field tab bar (next to the note icon); no waveform.
  final bool compact;

  /// When true, [audioUrlProvider] is already overridden above (e.g. by [FactContent]).
  final bool useExternalScope;

  @override
  State<CardAudio> createState() => _CardAudioState();
}

class _CardAudioState extends State<CardAudio>
    with AutomaticKeepAliveClientMixin {
  static const _kCompactSize = 36.0;
  static const _kCompactIconSize = 22.0;
  static const _kFullHeight = 50.0;
  static const _kFullIconSize = 28.0;
  static const _kLoadingOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final core = Consumer(
      builder: (context, ref, child) {
        final audioState = ref.watch(audioPlayerProvider);
        final accent = widget.color ?? Colors.blue;

        if (audioState.loadFailed) {
          final failIcon = Icon(
            LucideIcons.volumeX,
            size: widget.compact ? 20 : _kFullIconSize,
            color: Theme.of(context).disabledColor,
          );
          return widget.compact
              ? Tooltip(
                  message: context.loc.cardAudioUnavailable,
                  child: SizedBox(
                    width: _kCompactSize,
                    height: _kCompactSize,
                    child: Center(child: failIcon),
                  ),
                )
              : SizedBox(
                  height: _kFullHeight,
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
        final notifier = ref.read(audioPlayerProvider.notifier);
        // Keep play control geometry stable while the player prepares so the
        // tab bar / row does not reflow when isReady flips.
        final color = isReady
            ? accent
            : accent.withValues(alpha: _kLoadingOpacity);

        if (widget.compact) {
          return SizedBox(
            width: _kCompactSize,
            height: _kCompactSize,
            child: IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: _kCompactSize,
                minHeight: _kCompactSize,
              ),
              iconSize: _kCompactIconSize,
              color: color,
              onPressed: isReady ? notifier.playPause : null,
              icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play),
            ),
          );
        }

        return SizedBox(
          height: _kFullHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                padding: const EdgeInsets.all(8),
                iconSize: _kFullIconSize,
                color: color,
                onPressed: isReady ? notifier.playPause : null,
                icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final position = ref.watch(
                      audioPlayerProvider.select((value) => value.positionMs),
                    );
                    final max = ref.watch(
                      audioPlayerProvider.select(
                        (value) => value.maxDurationMs,
                      ),
                    );
                    final progress = max > 0 ? position.clamp(0, max) : 0;
                    return SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: accent,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.35),
                        thumbColor: accent,
                        disabledActiveTrackColor: accent.withValues(
                          alpha: _kLoadingOpacity,
                        ),
                        disabledInactiveTrackColor: Colors.grey.withValues(
                          alpha: 0.25,
                        ),
                        disabledThumbColor: accent.withValues(
                          alpha: _kLoadingOpacity,
                        ),
                      ),
                      child: Slider(
                        value: progress.toDouble(),
                        min: 0,
                        max: (max <= 0 ? 1 : max).toDouble(),
                        onChanged: !isReady || max <= 0
                            ? null
                            : (value) => ref
                                  .read(audioPlayerProvider.notifier)
                                  .seekToMs(value.round()),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (widget.useExternalScope) {
      return core;
    }
    return ProviderScope(
      overrides: [audioUrlProvider.overrideWithValue(widget.audioUrl)],
      child: core,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
