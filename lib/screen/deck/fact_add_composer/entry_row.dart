import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/card_widgets/card_audio.dart';
import 'package:retentio/screen/deck/fact_add_composer/attachment_chip.dart';
import 'package:retentio/screen/deck/fact_add_composer/media_play_url.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/screen/deck/fact_add_composer/wiki_ruby_content_editor.dart';
import 'package:retentio/screen/deck/fact_add_composer/wiki_ruby_wrap_action.dart';
import 'package:retentio/services/apis/media_service.dart';
import 'package:retentio/widgets/app_input.dart';

const _kAttachmentKindsOrder = <MediaSlotKind>[
  MediaSlotKind.image,
  MediaSlotKind.video,
  MediaSlotKind.audio,
];
const _kContentFieldPaddingWithMedia = EdgeInsets.fromLTRB(10, 4, 6, 10);
const _kContentFieldPaddingNoMedia = EdgeInsets.fromLTRB(10, 8, 6, 10);
const _kMediaChipWrapPadding = EdgeInsets.fromLTRB(6, 6, 6, 0);
const _kMediaChipWrapSpacing = 2.0;
const _kMediaChipIconSize = 18.0;
const _kMediaChipAudioControlSize = 28.0;
const _kMediaChipClearConstraints = BoxConstraints.tightFor(
  width: 28,
  height: 28,
);
const _kCollapsedLabelPadding = EdgeInsets.symmetric(
  horizontal: 5,
  vertical: 4,
);
const _kCollapsedLabelRadius = 4.0;
const _kFieldNameCollapsedMinSize = 8.0;
const _kFieldNameCollapsedMaxSize = 14.0;
const _kFieldNameCollapsedScale = 0.5;
const _kFieldNameBaseFallbackSize = 11.0;
const _kFieldNameContentPadding = EdgeInsets.fromLTRB(0, 0, 0, 6);
const _kRowSpacing = 8.0;
const _kContentContainerRadius = 12.0;
const _kContentContainerAlpha = 0.52;
const _kContentEditFontScale = 1.32;
const _kContentBaseFallbackSize = 14.0;
const _kRecordingTargetBorderWidth = 2.0;
const _kRecordingTargetFillAlpha = 0.18;
const _kRecordingPlaceholderPadding = EdgeInsets.fromLTRB(10, 10, 10, 6);
const _kRecordingPlaceholderIconSize = 18.0;

/// Enlarged content style used for fact composer fields (always on).
@visibleForTesting
TextStyle addFactEntryContentEditStyle(
  TextStyle base, {
  double fallbackSize = _kContentBaseFallbackSize,
}) {
  final size = base.fontSize ?? fallbackSize;
  return base.copyWith(fontSize: size * _kContentEditFontScale);
}

/// Ensures [base] has an explicit font size before applying edit scale.
@visibleForTesting
TextStyle addFactEntryContentBaseStyle(
  TextStyle base, {
  double fallbackSize = _kContentBaseFallbackSize,
}) {
  return base.copyWith(fontSize: base.fontSize ?? fallbackSize);
}

class AddFactEntryRow extends HookWidget {
  const AddFactEntryRow({
    super.key,
    required this.row,
    required this.loc,
    required this.theme,
    required this.outlineColor,
    required this.onClearSlot,
    this.isRecordingTarget = false,
    this.isMediaTarget = false,
  });

  final AddFactRowModel row;
  final AppLocalizations loc;
  final ThemeData theme;
  final Color outlineColor;
  final void Function(MediaSlotKind kind) onClearSlot;

  /// True while the mic is recording and this row will receive the clip.
  final bool isRecordingTarget;

  /// True when this row is the sticky media target (recording or cleared for re-record).
  final bool isMediaTarget;

  Widget _buildContentField(
    ThemeData theme,
    AppLocalizations loc, {
    required FocusNode contentFocus,
    required TextStyle contentStyle,
    GlobalKey<WikiRubyContentEditorState>? rubyEditorKey,
  }) {
    final row = this.row;
    final activeKinds = _kAttachmentKindsOrder
        .where((k) => row.pathFor(k) != null)
        .toList(growable: false);
    final showMediaChips = activeKinds.isNotEmpty;
    final useRubyEditor = wikiRubyContentUsesReadingEditor(row.content.text);
    final fieldPadding = showMediaChips
        ? _kContentFieldPaddingWithMedia
        : _kContentFieldPaddingNoMedia;

    final Widget textField;
    if (useRubyEditor) {
      textField = WikiRubyContentEditor(
        key: rubyEditorKey,
        storage: row.content,
        baseStyle: contentStyle,
        readingHint: loc.factRubyReadingHint,
        contentPadding: fieldPadding,
      );
    } else {
      textField = AppInput(
        controller: row.content,
        focusNode: contentFocus,
        style: contentStyle,
        enableInteractiveSelection: true,
        contextMenuBuilder: (context, editableTextState) {
          return wikiRubySelectionToolbar(
            context: context,
            editableTextState: editableTextState,
            loc: loc,
            onRubyWrap: ({required start, required end}) async {
              wikiRubyApplyWrapToController(
                row.content,
                '',
                start: start,
                end: end,
              );
            },
          );
        },
        isDense: true,
        border: InputBorder.none,
        contentPadding: fieldPadding,
        minLines: 1,
        maxLines: 3,
      );
    }

    // Note: [isMediaTarget] intentionally does not gate this early return. Its
    // highlight is drawn by the outer container border/fill, so keeping the
    // content subtree stable here avoids reparenting (and losing the tap
    // cursor) when a plain row becomes the media target.
    if (!showMediaChips && !isRecordingTarget) {
      return textField;
    }

    final audioPath = row.audioPath;
    final audioPlayUrl = attachmentAudioPlayUrl(audioPath);
    final nonAudioKinds = activeKinds
        .where((k) => k != MediaSlotKind.audio)
        .toList(growable: false);

    // Opaque so empty space beside the audio control (and other dead areas in
    // the box) still receive taps; play/clear/text children win the arena when
    // hit directly.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => row.requestContentFocus?.call(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecordingTarget)
            Padding(
              padding: _kRecordingPlaceholderPadding,
              child: Row(
                children: [
                  Icon(
                    LucideIcons.mic,
                    size: _kRecordingPlaceholderIconSize,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.addFactRecordingTargetHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (audioPath != null)
            Padding(
              padding: _kMediaChipWrapPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (audioPlayUrl != null)
                    CardAudio(
                      audioUrl: audioPlayUrl,
                      color: theme.colorScheme.primary,
                      compact: true,
                    )
                  else
                    Icon(
                      addFactAttachmentChipIcon(MediaSlotKind.audio),
                      size: _kMediaChipIconSize,
                      color: theme.colorScheme.primary,
                    ),
                  // Raw IconButton: AppIconButton enforces a 44px minimum, but
                  // this clear control must stay compact (28×28).
                  IconButton(
                    tooltip: loc.addFactClearAttachment,
                    onPressed: () => onClearSlot(MediaSlotKind.audio),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: _kMediaChipClearConstraints,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(
                        _kMediaChipAudioControlSize,
                        _kMediaChipAudioControlSize,
                      ),
                      maximumSize: const Size(
                        _kMediaChipAudioControlSize,
                        _kMediaChipAudioControlSize,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      LucideIcons.x,
                      size: _kMediaChipIconSize,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (nonAudioKinds.isNotEmpty)
            Padding(
              padding: _kMediaChipWrapPadding,
              child: Wrap(
                spacing: _kMediaChipWrapSpacing,
                runSpacing: _kMediaChipWrapSpacing,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final kind in nonAudioKinds)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          addFactAttachmentChipIcon(kind),
                          size: _kMediaChipIconSize,
                          color: theme.colorScheme.primary,
                        ),
                        // Raw IconButton: AppIconButton enforces a 44px
                        // minimum, but this clear control must stay 28×28.
                        IconButton(
                          tooltip: loc.addFactClearAttachment,
                          onPressed: () => onClearSlot(kind),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: _kMediaChipClearConstraints,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(
                              _kMediaChipAudioControlSize,
                              _kMediaChipAudioControlSize,
                            ),
                            maximumSize: const Size(
                              _kMediaChipAudioControlSize,
                              _kMediaChipAudioControlSize,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          icon: Icon(
                            LucideIcons.x,
                            size: _kMediaChipIconSize,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          textField,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldNameFocus = useFocusNode();
    final contentFocus = useFocusNode();
    final fieldNameEditorOpen = useState(false);
    final fieldNameTextTick = useListenable(row.fieldName);
    useListenable(row.content);
    useListenable(fieldNameFocus);
    final rubyEditorKey = useMemoized(
      GlobalKey<WikiRubyContentEditorState>.new,
    );

    final useRubyEditor = wikiRubyContentUsesReadingEditor(row.content.text);
    useEffect(() {
      void focusContentEnd() {
        if (wikiRubyContentUsesReadingEditor(row.content.text)) {
          rubyEditorKey.currentState?.focusEnd();
          return;
        }
        final text = row.content.text;
        row.content.selection = TextSelection.collapsed(offset: text.length);
        contentFocus.requestFocus();
      }

      row.requestContentFocus = focusContentEnd;
      return () {
        if (identical(row.requestContentFocus, focusContentEnd)) {
          row.requestContentFocus = null;
        }
      };
    }, [contentFocus, rubyEditorKey, row]);

    final wasRubyEditor = useRef(useRubyEditor);
    useEffect(() {
      if (wasRubyEditor.value && !useRubyEditor) {
        // Last ruby removed — hand focus to the plain field at storage caret.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          contentFocus.requestFocus();
        });
      }
      wasRubyEditor.value = useRubyEditor;
      return null;
    }, [useRubyEditor, contentFocus]);

    useEffect(() {
      void onFieldNameFocusChange() {
        if (!fieldNameFocus.hasFocus) {
          fieldNameEditorOpen.value = false;
        }
      }

      fieldNameFocus.addListener(onFieldNameFocusChange);
      return () => fieldNameFocus.removeListener(onFieldNameFocusChange);
    }, [fieldNameFocus]);

    void openFieldNameEditor() {
      fieldNameEditorOpen.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) fieldNameFocus.requestFocus();
      });
    }

    final hasCustomFieldName = fieldNameTextTick.text.trim().isNotEmpty;
    final showFieldNameTextField =
        fieldNameEditorOpen.value || fieldNameFocus.hasFocus;

    final theme = this.theme;
    final scheme = theme.colorScheme;
    final loc = this.loc;
    final baseLabelSize =
        theme.textTheme.labelSmall?.fontSize ?? _kFieldNameBaseFallbackSize;
    final collapsedFontSize = (baseLabelSize * _kFieldNameCollapsedScale).clamp(
      _kFieldNameCollapsedMinSize,
      _kFieldNameCollapsedMaxSize,
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontSize: collapsedFontSize,
      fontWeight: FontWeight.w600,
    );
    final contentStyle = addFactEntryContentEditStyle(
      addFactEntryContentBaseStyle(
        theme.textTheme.bodyMedium ?? const TextStyle(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showFieldNameTextField)
          AppInput(
            controller: row.fieldName,
            focusNode: fieldNameFocus,
            style: theme.textTheme.bodyMedium,
            enableInteractiveSelection: true,
            contextMenuBuilder: (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState,
              );
            },
            hint: loc.addFactFieldNameHint,
            isDense: true,
            border: InputBorder.none,
            contentPadding: _kFieldNameContentPadding,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => fieldNameFocus.unfocus(),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: openFieldNameEditor,
                borderRadius: BorderRadius.circular(_kCollapsedLabelRadius),
                child: Padding(
                  padding: _kCollapsedLabelPadding,
                  child: Text(
                    hasCustomFieldName
                        ? row.fieldName.text.trim()
                        : loc.addFactFieldShortLabel,
                    style: labelStyle,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: _kRowSpacing),
        Container(
          decoration: BoxDecoration(
            color: isMediaTarget || isRecordingTarget
                ? scheme.primary.withValues(alpha: _kRecordingTargetFillAlpha)
                : scheme.surfaceContainerHighest.withValues(
                    alpha: _kContentContainerAlpha,
                  ),
            border: Border.all(
              color: isMediaTarget || isRecordingTarget
                  ? scheme.primary
                  : outlineColor,
              width: isMediaTarget || isRecordingTarget
                  ? _kRecordingTargetBorderWidth
                  : 1,
            ),
            borderRadius: BorderRadius.circular(_kContentContainerRadius),
          ),
          child: _buildContentField(
            theme,
            loc,
            contentFocus: contentFocus,
            contentStyle: contentStyle,
            rubyEditorKey: rubyEditorKey,
          ),
        ),
      ],
    );
  }
}
