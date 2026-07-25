/// Builds API body for `POST .../facts/{operation}` (single fact).
class AddFactPayload {
  AddFactPayload._();

  /// Label for column [columnIndex] from the deck (or localized fallback).
  static String deckColumnLabel({
    required int columnIndex,
    required List<String> deckFields,
    required String Function(int oneBasedIndex) fallbackForIndex,
  }) {
    if (columnIndex < deckFields.length) {
      final s = deckFields[columnIndex].trim();
      if (s.isNotEmpty) return s;
    }
    return fallbackForIndex(columnIndex + 1);
  }

  static Map<String, dynamic> buildFactBody({
    required List<Map<String, dynamic>> entries,
    List<String>? tagNames,
    List<String>? tagIds,
  }) {
    final fact = <String, dynamic>{'entries': entries};
    // Prefer existing tag IDs (TagPicker). Names auto-create; do not send both.
    if (tagIds != null && tagIds.isNotEmpty) {
      fact['tag_ids'] = tagIds;
    } else if (tagNames != null && tagNames.isNotEmpty) {
      fact['tags'] = tagNames;
    }
    return {
      'facts': [fact],
    };
  }

  static Map<String, dynamic> buildEntryJson({
    required String text,
    String? imageId,
    String? videoId,
    String? audioId,
  }) {
    final m = <String, dynamic>{};
    final t = text.trim();
    if (t.isNotEmpty) m['text'] = t;
    if (imageId != null && imageId.trim().isNotEmpty) {
      m['image'] = imageId.trim();
    }
    if (videoId != null && videoId.trim().isNotEmpty) {
      m['video'] = videoId.trim();
    }
    if (audioId != null && audioId.trim().isNotEmpty) {
      m['audio'] = audioId.trim();
    }
    return m;
  }

  static bool entryHasAnyContent(Map<String, dynamic> entry) =>
      entry.isNotEmpty;
}
