import 'package:flutter/widgets.dart';

import 'package:retentio/services/apis/media_service.dart';

/// One editable entry row in the add-fact form (text fields + optional attachment).
class AddFactRowModel {
  AddFactRowModel()
    : fieldName = TextEditingController(),
      content = TextEditingController(),
      hostKey = GlobalKey();

  final TextEditingController fieldName;
  final TextEditingController content;

  /// Bounds this row’s fields for focus detection (media target, minus button).
  final GlobalKey hostKey;

  /// At most one media file per row (image, video, or audio).
  String? attachmentPath;
  MediaSlotKind? attachmentKind;

  void dispose() {
    fieldName.dispose();
    content.dispose();
  }

  bool get hasTextContent => content.text.trim().isNotEmpty;

  bool get hasAttachment => attachmentPath != null && attachmentKind != null;
}

/// True when the row can be submitted (API requires text and/or media per entry).
bool addFactRowIsSatisfied(AddFactRowModel row) =>
    row.hasTextContent || row.hasAttachment;
