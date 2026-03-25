/// Builds API body for `POST .../facts/{operation}` (single fact).
class AddFactPayload {
  AddFactPayload._();

  /// One-based index for fallback labels (`Field 1`, …).
  static List<String> resolveFieldLabels({
    required int entryCount,
    required List<String?> userNamesByRow,
    required List<String> deckFields,
    required String Function(int oneBasedIndex) fallbackForIndex,
  }) {
    return List.generate(entryCount, (i) {
      final user = userNamesByRow[i];
      if (user != null && user.isNotEmpty) return user;
      if (i < deckFields.length) return deckFields[i];
      return fallbackForIndex(i + 1);
    });
  }

  static Map<String, dynamic> buildFactBody({
    required List<Map<String, dynamic>> entries,
    required List<String> fields,
  }) => {
    'facts': [
      {'entries': entries, 'fields': fields},
    ],
  };

  static Map<String, dynamic> buildEntryJson({
    required String text,
    String? imageId,
    String? videoId,
    String? audioId,
  }) {
    final m = <String, dynamic>{};
    final t = text.trim();
    if (t.isNotEmpty) m['text'] = t;
    if (imageId != null && imageId.isNotEmpty) m['image'] = imageId;
    if (videoId != null && videoId.isNotEmpty) m['video'] = videoId;
    if (audioId != null && audioId.isNotEmpty) m['audio'] = audioId;
    return m;
  }

  static bool entryHasAnyContent(Map<String, dynamic> entry) =>
      entry.isNotEmpty;
}
