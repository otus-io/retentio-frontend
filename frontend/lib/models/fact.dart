/// Fact payload from GET/PATCH `/api/decks/{id}/facts/{factId}`.
class FactEntry {
  FactEntry({
    this.text = '',
    this.audio = '',
    this.image = '',
    this.video = '',
  });

  final String text;
  final String audio;
  final String image;
  final String video;

  factory FactEntry.fromJson(Map<String, dynamic> json) => FactEntry(
    text: json['text'] as String? ?? '',
    audio: json['audio'] as String? ?? '',
    image: json['image'] as String? ?? '',
    video: json['video'] as String? ?? '',
  );

  FactEntry copyWithText(String newText) =>
      FactEntry(text: newText, audio: audio, image: image, video: video);

  /// JSON for PATCH `entries` (preserves media when non-empty).
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'text': text};
    if (audio.isNotEmpty) m['audio'] = audio;
    if (image.isNotEmpty) m['image'] = image;
    if (video.isNotEmpty) m['video'] = video;
    return m;
  }
}

class Fact {
  Fact({required this.id, required this.entries, required this.fields});

  final String id;
  final List<FactEntry> entries;
  final List<String> fields;

  factory Fact.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'];
    final fieldsRaw = json['fields'];
    return Fact(
      id: json['id'] as String,
      entries: entriesRaw is List
          ? entriesRaw
                .map(
                  (e) => FactEntry.fromJson(
                    Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
                  ),
                )
                .toList()
          : [],
      fields: fieldsRaw is List
          ? fieldsRaw.map((e) => e as String).toList()
          : [],
    );
  }

  /// Body for PATCH update-fact; `fields` only if same length as [entries].
  Map<String, dynamic> toUpdateBody() {
    final body = <String, dynamic>{
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    if (fields.length == entries.length) {
      body['fields'] = fields;
    }
    return body;
  }

  /// Replaces text per slot; keeps audio/image/video from the original entries.
  Fact withMergedTexts(List<String> texts) {
    if (texts.length != entries.length) {
      throw ArgumentError(
        'texts.length (${texts.length}) must equal entries.length (${entries.length})',
      );
    }
    final merged = List<FactEntry>.generate(
      entries.length,
      (i) => entries[i].copyWithText(texts[i]),
    );
    return Fact(id: id, entries: merged, fields: fields);
  }
}
