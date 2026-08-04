import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/screen/deck/providers/audio_player.dart';
import 'package:retentio/widgets/app_icon_button.dart';

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
      builder: (context, ref, child) => _player(context, ref),
    );
    if (widget.useExternalScope) {
      return core;
    }
    return ProviderScope(
      overrides: [audioUrlProvider.overrideWithValue(widget.audioUrl)],
      child: core,
    );
  }

  Widget _player(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final accent = widget.color ?? Colors.blue;

    if (audioState.loadFailed) {
      return _loadFailure(context);
    }

    final isReady = audioState.isReady;
    final isPlaying = ref.watch(
      audioPlayerProvider.select((value) => value.isPlaying),
    );
    final notifier = ref.read(audioPlayerProvider.notifier);
    // Keep play control geometry stable while the player prepares so the
    // tab bar / row does not reflow when isReady flips.
    final color = isReady ? accent : accent.withValues(alpha: _kLoadingOpacity);
    final onPlayPause = isReady ? notifier.playPause : null;

    return widget.compact
        ? _compactControl(
            color: color,
            isPlaying: isPlaying,
            onPressed: onPlayPause,
          )
        : _fullControl(
            accent: accent,
            color: color,
            isPlaying: isPlaying,
            isReady: isReady,
            onPressed: onPlayPause,
          );
  }

  Widget _loadFailure(BuildContext context) {
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

  Widget _compactControl({
    required Color color,
    required bool isPlaying,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: _kCompactSize,
      height: _kCompactSize,
      // Raw IconButton: this control must stay 36 px to fit the field tab bar,
      // while AppIconButton clamps its touch target to a 44 px minimum.
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(
          minWidth: _kCompactSize,
          minHeight: _kCompactSize,
        ),
        iconSize: _kCompactIconSize,
        color: color,
        onPressed: onPressed,
        icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play),
      ),
    );
  }

  Widget _fullControl({
    required Color accent,
    required Color color,
    required bool isPlaying,
    required bool isReady,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: _kFullHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIconButton(
            icon: isPlaying ? LucideIcons.pause : LucideIcons.play,
            size: _kFullIconSize,
            iconSize: _kFullIconSize,
            padding: const EdgeInsets.all(8),
            color: color,
            onPressed: onPressed,
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) => _progressSlider(
                context,
                ref,
                accent: accent,
                isReady: isReady,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressSlider(
    BuildContext context,
    WidgetRef ref, {
    required Color accent,
    required bool isReady,
  }) {
    final position = ref.watch(
      audioPlayerProvider.select((value) => value.positionMs),
    );
    final max = ref.watch(
      audioPlayerProvider.select((value) => value.maxDurationMs),
    );
    final progress = max > 0 ? position.clamp(0, max) : 0;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: accent,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.35),
        thumbColor: accent,
        disabledActiveTrackColor: accent.withValues(alpha: _kLoadingOpacity),
        disabledInactiveTrackColor: Colors.grey.withValues(alpha: 0.25),
        disabledThumbColor: accent.withValues(alpha: _kLoadingOpacity),
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
  }

  @override
  bool get wantKeepAlive => true;
}
