import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/attachment_chip.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/services/apis/media_service.dart';
import 'package:retentio/widgets/app_icon_button.dart';
import 'package:retentio/widgets/app_input.dart';

const _kAttachmentKindsOrder = <MediaSlotKind>[
  MediaSlotKind.image,
  MediaSlotKind.video,
  MediaSlotKind.audio,
];
const _kContentFieldPaddingWithMedia = EdgeInsets.fromLTRB(2, 8, 6, 10);
const _kContentFieldPaddingNoMedia = EdgeInsets.fromLTRB(10, 8, 6, 10);
const _kContentSuffixConstraints = BoxConstraints(minWidth: 40, minHeight: 36);
const _kMediaChipWrapPadding = EdgeInsets.only(left: 6, top: 6);
const _kMediaChipWrapSpacing = 2.0;
const _kMediaChipIconSize = 18.0;
const _kMediaChipClearConstraints = BoxConstraints(minWidth: 28, minHeight: 28);
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
const _kFieldNameSuffixConstraints = BoxConstraints(
  minWidth: 36,
  minHeight: 32,
);
const _kRowSpacing = 8.0;
const _kContentContainerRadius = 12.0;
const _kContentContainerAlpha = 0.52;

Future<void> _pastePlainTextInto({
  required TextEditingController controller,
  required FocusNode? focusBeforePaste,
}) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final pasted = data?.text;
  if (pasted == null || pasted.isEmpty) return;

  focusBeforePaste?.requestFocus();

  var sel = controller.selection;
  if (!sel.isValid) {
    sel = TextSelection.collapsed(offset: controller.text.length);
  }
  final text = controller.text;
  final newText = text.replaceRange(sel.start, sel.end, pasted);
  final newOffset = sel.start + pasted.length;
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newOffset),
  );
}

class AddFactEntryRow extends HookWidget {
  const AddFactEntryRow({
    super.key,
    required this.row,
    required this.loc,
    required this.theme,
    required this.outlineColor,
    required this.onClearSlot,
  });

  final AddFactRowModel row;
  final AppLocalizations loc;
  final ThemeData theme;
  final Color outlineColor;
  final void Function(MediaSlotKind kind) onClearSlot;

  Widget _buildContentField(
    ThemeData theme,
    AppLocalizations loc, {
    required FocusNode contentFocus,
  }) {
    final row = this.row;
    final activeKinds = _kAttachmentKindsOrder
        .where((k) => row.pathFor(k) != null)
        .toList(growable: false);
    final showMediaChips = activeKinds.isNotEmpty;

    final textField = AppInput(
      controller: row.content,
      focusNode: contentFocus,
      style: theme.textTheme.bodyMedium,
      enableInteractiveSelection: true,
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
      hint: loc.addFactContentHint,
      isDense: true,
      border: InputBorder.none,
      contentPadding: showMediaChips
          ? _kContentFieldPaddingWithMedia
          : _kContentFieldPaddingNoMedia,
      suffixConstraints: _kContentSuffixConstraints,
      suffix: AppIconButton(
        tooltip: loc.addFactPasteFromClipboard,
        onPressed: () => _pastePlainTextInto(
          controller: row.content,
          focusBeforePaste: contentFocus,
        ),
        icon: LucideIcons.clipboardPaste,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
        visualDensity: VisualDensity.compact,
      ),
      minLines: 1,
      maxLines: 3,
    );

    if (!showMediaChips) {
      return textField;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _kMediaChipWrapPadding,
          child: Wrap(
            spacing: _kMediaChipWrapSpacing,
            runSpacing: _kMediaChipWrapSpacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final kind in activeKinds)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      addFactAttachmentChipIcon(kind),
                      size: _kMediaChipIconSize,
                      color: theme.colorScheme.primary,
                    ),
                    AppIconButton(
                      tooltip: loc.addFactClearAttachment,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: _kMediaChipClearConstraints,
                      onPressed: () => onClearSlot(kind),
                      icon: LucideIcons.x,
                      size: _kMediaChipIconSize,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(child: textField),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldNameFocus = useFocusNode();
    final contentFocus = useFocusNode();
    final fieldNameEditorOpen = useState(false);
    final fieldNameTextTick = useListenable(row.fieldName);
    useListenable(fieldNameFocus);

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
            suffixConstraints: _kFieldNameSuffixConstraints,
            suffix: AppIconButton(
              tooltip: loc.addFactPasteFromClipboard,
              onPressed: () => _pastePlainTextInto(
                controller: row.fieldName,
                focusBeforePaste: fieldNameFocus,
              ),
              icon: LucideIcons.clipboardPaste,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
            ),
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
            color: scheme.surfaceContainerHighest.withValues(
              alpha: _kContentContainerAlpha,
            ),
            border: Border.all(color: outlineColor),
            borderRadius: BorderRadius.circular(_kContentContainerRadius),
          ),
          child: _buildContentField(theme, loc, contentFocus: contentFocus),
        ),
      ],
    );
  }
}
