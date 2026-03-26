import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/attachment_chip.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/services/apis/media_service.dart';

class AddFactEntryRow extends StatefulWidget {
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

  @override
  State<AddFactEntryRow> createState() => _AddFactEntryRowState();
}

class _AddFactEntryRowState extends State<AddFactEntryRow> {
  late final FocusNode _fieldNameFocus;
  bool _fieldNameEditorOpen = false;

  @override
  void initState() {
    super.initState();
    _fieldNameFocus = FocusNode();
    _fieldNameFocus.addListener(_onFieldNameFocusChange);
    widget.row.fieldName.addListener(_onFieldNameTextChange);
  }

  void _onFieldNameFocusChange() {
    if (!_fieldNameFocus.hasFocus) {
      setState(() {
        _fieldNameEditorOpen = false;
      });
    }
  }

  void _onFieldNameTextChange() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.row.fieldName.removeListener(_onFieldNameTextChange);
    _fieldNameFocus.removeListener(_onFieldNameFocusChange);
    _fieldNameFocus.dispose();
    super.dispose();
  }

  void _openFieldNameEditor() {
    setState(() => _fieldNameEditorOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fieldNameFocus.requestFocus();
    });
  }

  bool get _hasCustomFieldName => widget.row.fieldName.text.trim().isNotEmpty;

  bool get _showFieldNameTextField =>
      _fieldNameEditorOpen || _fieldNameFocus.hasFocus;

  Widget _buildContentField(ThemeData theme, AppLocalizations loc) {
    final row = widget.row;
    const kindsOrder = [
      MediaSlotKind.image,
      MediaSlotKind.video,
      MediaSlotKind.audio,
    ];
    final activeKinds = kindsOrder
        .where((k) => row.pathFor(k) != null)
        .toList(growable: false);
    final showMediaChips = activeKinds.isNotEmpty;

    final textField = TextField(
      controller: widget.row.content,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: loc.addFactContentHint,
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.fromLTRB(showMediaChips ? 2 : 10, 8, 10, 10),
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
          padding: const EdgeInsets.only(left: 6, top: 6),
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final kind in activeKinds)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      addFactAttachmentChipIcon(kind),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    IconButton(
                      tooltip: loc.addFactClearAttachment,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () => widget.onClearSlot(kind),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
    final theme = widget.theme;
    final loc = widget.loc;
    final baseLabelSize = theme.textTheme.labelSmall?.fontSize ?? 11;
    final collapsedFontSize = (baseLabelSize * 0.5).clamp(8.0, 14.0);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: collapsedFontSize,
    );
    const collapsedPadding = EdgeInsets.symmetric(horizontal: 5, vertical: 4);
    const chipRadius = 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showFieldNameTextField)
          TextField(
            controller: widget.row.fieldName,
            focusNode: _fieldNameFocus,
            style: theme.textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: loc.addFactFieldNameHint,
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _fieldNameFocus.unfocus(),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openFieldNameEditor,
                borderRadius: BorderRadius.circular(chipRadius),
                child: Padding(
                  padding: collapsedPadding,
                  child: Text(
                    _hasCustomFieldName
                        ? widget.row.fieldName.text.trim()
                        : loc.addFactFieldShortLabel,
                    style: labelStyle,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.outlineColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildContentField(theme, loc),
        ),
      ],
    );
  }
}
