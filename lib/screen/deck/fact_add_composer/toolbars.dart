import 'dart:math' as math;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/recorder_level_smooth.dart';

class AddFactMediaToolbar extends StatelessWidget {
  const AddFactMediaToolbar({
    super.key,
    required this.loc,
    required this.theme,
    required this.hasMediaOnTargetRow,
    required this.onPickFiles,
    required this.onPickGallery,
    required this.onClearTargetAttachment,
    required this.voiceRecorder,
    this.mediaPicksLocked = false,
    this.showVoiceRecord = false,
    this.isRecordingVoice = false,
    this.onVoiceRecordTap,
    this.onVoiceRecordLongPress,
  });

  final AppLocalizations loc;
  final ThemeData theme;
  final bool hasMediaOnTargetRow;
  final VoidCallback onPickFiles;
  final VoidCallback onPickGallery;
  final VoidCallback onClearTargetAttachment;
  final RecorderController voiceRecorder;
  final bool mediaPicksLocked;
  final bool showVoiceRecord;
  final bool isRecordingVoice;
  final VoidCallback? onVoiceRecordTap;
  final VoidCallback? onVoiceRecordLongPress;

  static const _iconBtn = BoxConstraints(minWidth: 44, minHeight: 44);

  @override
  Widget build(BuildContext context) {
    final accent = hasMediaOnTargetRow && !mediaPicksLocked
        ? theme.colorScheme.primary
        : null;
    return Row(
      children: [
        Tooltip(
          message: loc.addFactAttachMediaTooltip,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: _iconBtn,
            onPressed: mediaPicksLocked ? null : onPickFiles,
            onLongPress: mediaPicksLocked || !hasMediaOnTargetRow
                ? null
                : onClearTargetAttachment,
            icon: Icon(LucideIcons.paperclip, color: accent),
          ),
        ),
        Tooltip(
          message: loc.addFactGalleryMediaTooltip,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: _iconBtn,
            onPressed: mediaPicksLocked ? null : onPickGallery,
            onLongPress: mediaPicksLocked || !hasMediaOnTargetRow
                ? null
                : onClearTargetAttachment,
            icon: Icon(LucideIcons.images, color: accent),
          ),
        ),
        if (showVoiceRecord && onVoiceRecordTap != null)
          Tooltip(
            message: isRecordingVoice
                ? loc.addFactStopRecordingTooltip
                : loc.addFactRecordAudioTooltip,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: _iconBtn,
              onPressed: onVoiceRecordTap,
              onLongPress: onVoiceRecordLongPress,
              icon: isRecordingVoice
                  ? _InputReactiveMic(
                      controller: voiceRecorder,
                      color: theme.colorScheme.error,
                    )
                  : Icon(LucideIcons.mic, color: accent),
            ),
          ),
      ],
    );
  }
}

/// Mic icon with continuous outward ripples; animation stays gentle when quiet
/// and becomes much stronger when input level is high.
class _InputReactiveMic extends StatefulWidget {
  const _InputReactiveMic({required this.controller, required this.color});

  final RecorderController controller;
  final Color color;

  @override
  State<_InputReactiveMic> createState() => _InputReactiveMicState();
}

class _InputReactiveMicState extends State<_InputReactiveMic>
    with SingleTickerProviderStateMixin {
  static const _iconSize = 24.0;

  late final AnimationController _wave;

  double _level = 0;

  void _onRecorder() {
    if (!mounted) return;
    double raw = 0.0;
    try {
      final data = widget.controller.waveData;
      if (data.isNotEmpty) {
        raw = data[data.length - 1];
      }
    } catch (_) {
      raw = 0.0;
    }
    final next = smoothRecorderVisualizationLevel(_level, raw);
    if (!mounted) return;
    setState(() => _level = next);
  }

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    widget.controller.addListener(_onRecorder);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onRecorder);
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wave,
      builder: (context, _) {
        final t = _wave.value;
        final w = _level.clamp(0.0, 1.0);
        // Ripples: linear blend — soft when quiet, full when loud.
        final ripple = 0.10 + 0.90 * w;
        // Icon pulse: ramps up faster at high levels so speech feels obvious.
        final iconHot = 0.07 + 0.93 * (w * w);

        return SizedBox(
          width: _iconSize,
          height: _iconSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < 3; i++)
                _rippleRing(phase: ((t + i / 3.0) % 1.0), strength: ripple),
              Transform.scale(
                scale:
                    1.0 +
                    iconHot *
                        0.24 *
                        (0.4 + 0.6 * math.sin(t * math.pi * 2 * 5.5)),
                child: Icon(
                  LucideIcons.mic,
                  color: widget.color.withValues(
                    alpha:
                        (0.84 +
                                0.16 *
                                    iconHot *
                                    (0.45 +
                                        0.55 * math.sin(t * math.pi * 2 * 4)))
                            .clamp(0.0, 1.0),
                  ),
                  size: _iconSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rippleRing({required double phase, required double strength}) {
    final scale = 1.0 + phase * (0.30 + strength * 0.72);
    final opacity = ((1.0 - phase) * (0.07 + strength * 0.45)).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: _iconSize,
        height: _iconSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.color.withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class AddFactRowControls extends StatelessWidget {
  const AddFactRowControls({
    super.key,
    required this.loc,
    required this.theme,
    required this.rowCount,
    required this.onAddRow,
    required this.onRemoveRow,
  });

  final AppLocalizations loc;
  final ThemeData theme;
  final int rowCount;
  final VoidCallback onAddRow;
  final VoidCallback onRemoveRow;

  static const _iconBtn = BoxConstraints(minWidth: 44, minHeight: 44);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: loc.addFactAddRow,
            padding: EdgeInsets.zero,
            constraints: _iconBtn,
            onPressed: onAddRow,
            icon: Icon(LucideIcons.plus),
          ),
          if (rowCount > 1)
            IconButton(
              tooltip: loc.addFactRemoveRow,
              padding: EdgeInsets.zero,
              constraints: _iconBtn,
              onPressed: onRemoveRow,
              icon: Icon(LucideIcons.minus, color: theme.colorScheme.error),
            ),
        ],
      ),
    );
  }
}
