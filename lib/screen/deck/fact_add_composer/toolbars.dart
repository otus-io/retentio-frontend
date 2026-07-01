import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/widgets/app_icon_button.dart';

const _kToolbarPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);
const _kToolbarBorderAlpha = 0.35;
const _kToolbarSurfaceAlpha = 0.72;
const _kToolbarBorderRadius = 14.0;
const _kRowControlsPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 4);
const _kRowControlsBorderRadius = 12.0;

class AddFactMediaToolbar extends HookWidget {
  const AddFactMediaToolbar({
    super.key,
    required this.loc,
    required this.theme,
    required this.hasMediaOnTargetRow,
    required this.onPickFiles,
    required this.onPickGallery,
    required this.onClearTargetAttachment,
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
    final scheme = theme.colorScheme;
    return Container(
      padding: _kToolbarPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: _kToolbarSurfaceAlpha,
        ),
        border: Border.all(
          color: scheme.outline.withValues(alpha: _kToolbarBorderAlpha),
        ),
        borderRadius: BorderRadius.circular(_kToolbarBorderRadius),
      ),
      child: Row(
        children: [
          Tooltip(
            message: loc.addFactAttachMediaTooltip,
            child: AppIconButton(
              padding: EdgeInsets.zero,
              constraints: _iconBtn,
              onPressed: mediaPicksLocked ? null : onPickFiles,
              onLongPress: mediaPicksLocked || !hasMediaOnTargetRow
                  ? null
                  : onClearTargetAttachment,
              icon: LucideIcons.paperclip,
              color: accent,
            ),
          ),
          Tooltip(
            message: loc.addFactGalleryMediaTooltip,
            child: AppIconButton(
              padding: EdgeInsets.zero,
              constraints: _iconBtn,
              onPressed: mediaPicksLocked ? null : onPickGallery,
              onLongPress: mediaPicksLocked || !hasMediaOnTargetRow
                  ? null
                  : onClearTargetAttachment,
              icon: LucideIcons.images,
              color: accent,
            ),
          ),
          if (showVoiceRecord && onVoiceRecordTap != null)
            Tooltip(
              message: isRecordingVoice
                  ? loc.addFactStopRecordingTooltip
                  : loc.addFactRecordAudioTooltip,
              child: AppIconButton(
                padding: EdgeInsets.zero,
                constraints: _iconBtn,
                onPressed: onVoiceRecordTap,
                onLongPress: onVoiceRecordLongPress,
                icon: LucideIcons.mic,
                color: accent,
                iconWidget: isRecordingVoice
                    ? _RecordingMic(color: theme.colorScheme.error)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Mic icon with continuous outward ripples while recording.
class _RecordingMic extends HookWidget {
  const _RecordingMic({required this.color});

  final Color color;

  static const _iconSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final wave = useAnimationController(
      duration: const Duration(milliseconds: 1600),
    );

    useEffect(() {
      wave.repeat();
      return () => wave.stop();
    }, [wave]);

    return AnimatedBuilder(
      animation: wave,
      builder: (context, _) {
        final t = wave.value;
        const ripple = 0.8;
        const iconHot = 0.75;

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
                  color: color.withValues(
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
            color: color.withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class AddFactRowControls extends HookWidget {
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

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: _kRowControlsPadding,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(
            alpha: _kToolbarSurfaceAlpha,
          ),
          border: Border.all(
            color: scheme.outline.withValues(alpha: _kToolbarBorderAlpha),
          ),
          borderRadius: BorderRadius.circular(_kRowControlsBorderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconButton(
              icon: LucideIcons.plus,
              onPressed: onAddRow,
              tooltip: loc.addFactAddRow,
            ),
            if (rowCount > 1)
              AppIconButton(
                icon: LucideIcons.minus,
                onPressed: onRemoveRow,
                variant: AppIconButtonVariant.danger,
                tooltip: loc.addFactRemoveRow,
              ),
          ],
        ),
      ),
    );
  }
}
