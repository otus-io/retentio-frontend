import 'package:retentio/models/deck.dart';
import 'package:retentio/services/apis/media_service.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';

/// Public model for edit rows so logic can be unit-tested.
class FactEditRowModel {
  FactEditRowModel({
    required this.row,
    this.existingImageId,
    this.existingVideoId,
    this.existingAudioId,
    this.existingJsonId,
  });

  final AddFactRowModel row;
  String? existingImageId;
  String? existingVideoId;
  String? existingAudioId;
  String? existingJsonId;

  String? existingFor(MediaSlotKind kind) {
    switch (kind) {
      case MediaSlotKind.image:
        return existingImageId;
      case MediaSlotKind.video:
        return existingVideoId;
      case MediaSlotKind.audio:
        return existingAudioId;
      case MediaSlotKind.json:
        return existingJsonId;
    }
  }

  void clearExistingFor(MediaSlotKind kind) {
    switch (kind) {
      case MediaSlotKind.image:
        existingImageId = null;
      case MediaSlotKind.video:
        existingVideoId = null;
      case MediaSlotKind.audio:
        existingAudioId = null;
      case MediaSlotKind.json:
        existingJsonId = null;
    }
  }

  void clearAllAttachments() {
    row.clearAllAttachments();
    existingImageId = null;
    existingVideoId = null;
    existingAudioId = null;
    existingJsonId = null;
  }

  void seedRowAttachmentPathsFromExisting() {
    if (existingImageId != null) {
      row.imagePath = existingImageId;
    }
    if (existingVideoId != null) {
      row.videoPath = existingVideoId;
    }
    if (existingAudioId != null) {
      row.audioPath = existingAudioId;
    }
    if (existingJsonId != null) {
      row.jsonPath = existingJsonId;
    }
  }
}

bool factEditRowHasAttachment(FactEditRowModel row) {
  return row.row.hasAttachment ||
      row.existingImageId != null ||
      row.existingVideoId != null ||
      row.existingAudioId != null ||
      row.existingJsonId != null;
}

bool factEditRowHasAnyContent(FactEditRowModel row) {
  return row.row.content.text.trim().isNotEmpty ||
      factEditRowHasAttachment(row);
}

List<String> factEditResolveFields({
  required List<FactEditRowModel> rows,
  required Deck deck,
  required String Function(int oneBasedIndex) fallbackForIndex,
}) {
  return List.generate(rows.length, (i) {
    final user = rows[i].row.fieldName.text.trim();
    if (user.isNotEmpty) return user;
    if (i < deck.fields.length) return deck.fields[i];
    return fallbackForIndex(i + 1);
  });
}
