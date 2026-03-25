import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';

class AddFactMediaToolbar extends StatelessWidget {
  const AddFactMediaToolbar({
    super.key,
    required this.loc,
    required this.theme,
    required this.hasMediaOnTargetRow,
    required this.onPickFiles,
    required this.onPickGallery,
    required this.onClearTargetAttachment,
  });

  final AppLocalizations loc;
  final ThemeData theme;
  final bool hasMediaOnTargetRow;
  final VoidCallback onPickFiles;
  final VoidCallback onPickGallery;
  final VoidCallback onClearTargetAttachment;

  static const _iconBtn = BoxConstraints(minWidth: 44, minHeight: 44);

  @override
  Widget build(BuildContext context) {
    final accent = hasMediaOnTargetRow ? theme.colorScheme.primary : null;
    return Row(
      children: [
        Tooltip(
          message: loc.addFactAttachMediaTooltip,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: _iconBtn,
            onPressed: onPickFiles,
            onLongPress: hasMediaOnTargetRow ? onClearTargetAttachment : null,
            icon: Icon(LucideIcons.paperclip, color: accent),
          ),
        ),
        Tooltip(
          message: loc.addFactGalleryMediaTooltip,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: _iconBtn,
            onPressed: onPickGallery,
            onLongPress: hasMediaOnTargetRow ? onClearTargetAttachment : null,
            icon: Icon(LucideIcons.images, color: accent),
          ),
        ),
      ],
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
