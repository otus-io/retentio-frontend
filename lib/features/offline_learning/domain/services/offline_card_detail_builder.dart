import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/models/card.dart';

/// Derives the study-time [CardDetail] from cached card, fact and deck fields.
CardDetail buildOfflineCardDetail({
  required OfflineCard card,
  required OfflineFact fact,
  required List<String> deckFields,
  required double urgency,
  required String Function(String mediaId) resolveMedia,
}) {
  List<CardSlot> side(int index) {
    final indexes = index < card.template.length
        ? card.template[index]
        : const <int>[];
    return [
      for (final i in indexes)
        if (i >= 0 && i < fact.entries.length)
          _slot(i, fact, deckFields, resolveMedia),
    ];
  }

  return CardDetail(
    card: Card(
      back: side(1),
      createdAt: card.createdAt,
      dueDate: card.dueDate,
      factId: card.factId,
      front: side(0),
      hidden: card.hidden,
      id: card.id,
      lastReview: card.lastReview,
      template: card.template,
    ),
    urgency: urgency,
  );
}

CardSlot _slot(
  int i,
  OfflineFact fact,
  List<String> deckFields,
  String Function(String) resolveMedia,
) {
  final entry = fact.entries[i];
  final field = i < deckFields.length ? deckFields[i] : '';
  return CardSlot.fromJson({
    if (field.isNotEmpty) 'field': field,
    if (entry.text.isNotEmpty) 'text': entry.text,
    if (entry.audio.isNotEmpty) 'audio': resolveMedia(entry.audio),
    if (entry.image.isNotEmpty) 'image': resolveMedia(entry.image),
    if (entry.video.isNotEmpty) 'video': resolveMedia(entry.video),
    if (entry.json.isNotEmpty) 'json': resolveMedia(entry.json),
  });
}
