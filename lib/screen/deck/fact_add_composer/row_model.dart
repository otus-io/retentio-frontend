import 'package:flutter/widgets.dart';

import 'package:retentio/services/apis/media_service.dart';

/// One editable entry row in the add-fact form (text fields + optional attachment).
class AddFactRowModel {
  AddFactRowModel({String? initialFieldName})
    : fieldName = TextEditingController(text: initialFieldName ?? ''),
      content = TextEditingController(),
      hostKey = GlobalKey();

  /// Default rows when the deck has no field names, or one row per deck field with
  /// [fieldName] prefilled so labels match the deck editor.
  static List<AddFactRowModel> listForDeckFields(List<String> deckFields) {
    if (deckFields.isEmpty) {
      return [AddFactRowModel(), AddFactRowModel()];
    }
    return [
      for (final raw in deckFields)
        AddFactRowModel(
          initialFieldName: raw.trim().isEmpty ? null : raw.trim(),
        ),
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
