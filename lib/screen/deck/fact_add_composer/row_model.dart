import 'package:flutter/widgets.dart';

import 'package:retentio/services/apis/media_service.dart';

/// One editable entry row in the add-fact form (text fields + optional attachment).
class AddFactRowModel {
  AddFactRowModel({String? initialFieldName})
    : fieldName = TextEditingController(text: initialFieldName ?? ''),
      content = TextEditingController(),
      hostKey = GlobalKey();

  /// One row per deck column when [deckFields] is non-empty; otherwise two rows
  /// for legacy unnamed decks. Prefills each row's [fieldName] from the deck.
  static List<AddFactRowModel> listForDeckFields(List<String> deckFields) {
    if (deckFields.isEmpty) {
      return List.generate(2, (_) => AddFactRowModel());
    }
    return [
      for (final field in deckFields)
        AddFactRowModel(initialFieldName: field.trim()),
    ];
  }

  final TextEditingController fieldName;
  final TextEditingController content;

  /// Bounds this row’s fields for focus detection (media target, minus button).
  final GlobalKey hostKey;

  /// Up to one file per kind per row (API entry supports image + video + audio).
  String? imagePath;
  String? videoPath;
  String? audioPath;

  void dispose() {
    fieldName.dispose();
    content.dispose();
  }

  bool get hasTextContent => content.text.trim().isNotEmpty;

  bool get hasAttachment =>
      imagePath != null || videoPath != null || audioPath != null;

  String? pathFor(MediaSlotKind kind) {
    switch (kind) {
      case MediaSlotKind.image:
        return imagePath;
      case MediaSlotKind.video:
        return videoPath;
      case MediaSlotKind.audio:
        return audioPath;
    }
  }

  void setPathFor(MediaSlotKind kind, String path) {
    switch (kind) {
      case MediaSlotKind.image:
        imagePath = path;
      case MediaSlotKind.video:
        videoPath = path;
      case MediaSlotKind.audio:
        audioPath = path;
    }
  }

  void clearSlot(MediaSlotKind kind) {
    switch (kind) {
      case MediaSlotKind.image:
        imagePath = null;
      case MediaSlotKind.video:
        videoPath = null;
      case MediaSlotKind.audio:
        audioPath = null;
    }
  }

  void clearAllAttachments() {
    imagePath = null;
    videoPath = null;
    audioPath = null;
  }
}

/// True when the row can be submitted (API requires text and/or media per entry).
bool addFactRowIsSatisfied(AddFactRowModel row) =>
    row.hasTextContent || row.hasAttachment;
