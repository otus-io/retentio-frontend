import 'package:retentio/models/deck.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/services/apis/media_service.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';

/// Public model for edit rows so logic can be unit-tested.
class FactEditRowModel {
  FactEditRowModel({
    required this.row,
    this.existingImageId,
    this.existingVideoId,
    this.existingAudioId,
  });

  final AddFactRowModel row;
  String? existingImageId;
  String? existingVideoId;
  String? existingAudioId;

  String? existingFor(MediaSlotKind kind) {
    switch (kind) {
      case MediaSlotKind.image:
        return existingImageId;
      case MediaSlotKind.video:
        return existingVideoId;
      case MediaSlotKind.audio:
        return existingAudioId;
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
    }
  }

  void clearAllAttachments() {
    row.clearAllAttachments();
    existingImageId = null;
    existingVideoId = null;
    existingAudioId = null;
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
  }
}

bool factEditRowHasAttachment(FactEditRowModel row) {
  return row.row.hasAttachment ||
      row.existingImageId != null ||
      row.existingVideoId != null ||
      row.existingAudioId != null;
}

bool factEditRowHasAnyContent(FactEditRowModel row) {
  return row.row.content.text.trim().isNotEmpty ||
      factEditRowHasAttachment(row);
}

/// How many entry rows to show when editing — matches [AddFactRowModel.listForDeckFields].
///
/// Uses every deck column; keeps extra fact entries when the fact has more slots
/// than the deck currently defines.
int factEditRowCount({
  required List<String> deckFields,
  required int factEntryCount,
}) {
  if (deckFields.isNotEmpty) {
    return factEntryCount > deckFields.length
        ? factEntryCount
        : deckFields.length;
  }
  return factEntryCount > 0 ? factEntryCount : 2;
}

/// Builds edit rows for all deck columns, prefilled from [fact] entries by index.
List<FactEditRowModel> buildFactEditRowsFromFact({
  required Fact fact,
  required List<String> deckFields,
}) {
  final rowCount = factEditRowCount(
    deckFields: deckFields,
    factEntryCount: fact.entries.length,
  );
  return List.generate(rowCount, (i) {
    final entry = i < fact.entries.length ? fact.entries[i] : const FactEntry();
    final row = AddFactRowModel(
      initialFieldName: factEditInitialFieldName(
        index: i,
        deckFields: deckFields,
        factFields: fact.fields,
      ),
    );
    row.content.text = entry.text;
    final model = FactEditRowModel(
      row: row,
      existingImageId: entry.image.trim().isEmpty ? null : entry.image.trim(),
      existingVideoId: entry.video.trim().isEmpty ? null : entry.video.trim(),
      existingAudioId: entry.audio.trim().isEmpty ? null : entry.audio.trim(),
    )..seedRowAttachmentPathsFromExisting();
    return model;
  });
}

/// Label for entry row [index] when opening edit fact.
///
/// Column names live on the deck ([Deck.fields]); GET fact returns entries only.
String? factEditInitialFieldName({
  required int index,
  required List<String> deckFields,
  List<String> factFields = const [],
}) {
  if (index < deckFields.length) {
    final fromDeck = deckFields[index].trim();
    if (fromDeck.isNotEmpty) return fromDeck;
  }
  if (index < factFields.length) {
    final fromFact = factFields[index].trim();
    if (fromFact.isNotEmpty) return fromFact;
  }
  return null;
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
