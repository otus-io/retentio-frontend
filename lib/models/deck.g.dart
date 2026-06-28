// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeckOwner _$DeckOwnerFromJson(Map<String, dynamic> json) => DeckOwner(
  username: json['username'] as String? ?? '',
  email: json['email'] as String? ?? '',
);

Map<String, dynamic> _$DeckOwnerToJson(DeckOwner instance) => <String, dynamic>{
  'username': instance.username,
  'email': instance.email,
};

DeckStats _$DeckStatsFromJson(Map<String, dynamic> json) => DeckStats(
  cardsCount: (json['cards_count'] as num?)?.toInt() ?? 0,
  factsCount: (json['facts_count'] as num?)?.toInt() ?? 0,
  unseenCards: (json['unseen_cards'] as num?)?.toInt() ?? 0,
  reviewedCards: (json['reviewed_cards'] as num?)?.toInt() ?? 0,
  dueCards: (json['due_cards'] as num?)?.toInt() ?? 0,
  hiddenCards: (json['hidden_cards'] as num?)?.toInt() ?? 0,
  newCardsToday: (json['new_cards_today'] as num?)?.toInt() ?? 0,
  lastReviewedAt: (json['last_reviewed_at'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DeckStatsToJson(DeckStats instance) => <String, dynamic>{
  'cards_count': instance.cardsCount,
  'facts_count': instance.factsCount,
  'unseen_cards': instance.unseenCards,
  'reviewed_cards': instance.reviewedCards,
  'due_cards': instance.dueCards,
  'hidden_cards': instance.hiddenCards,
  'new_cards_today': instance.newCardsToday,
  'last_reviewed_at': instance.lastReviewedAt,
};

Deck _$DeckFromJson(Map<String, dynamic> json) => Deck(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  stats: json['stats'] == null
      ? _emptyDeckStats
      : DeckStats.fromJson(json['stats'] as Map<String, dynamic>),
  rate: (json['rate'] as num?)?.toInt() ?? 0,
  owner: json['owner'] == null
      ? const DeckOwner(username: 'unknown', email: '')
      : _ownerFromJson(json['owner']),
  fields:
      (json['fields'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  minInterval: (json['min_interval'] as num?)?.toInt() ?? 0,
  defInterval: (json['def_interval'] as num?)?.toInt() ?? 0,
  maxInterval: (json['max_interval'] as num?)?.toInt() ?? 0,
  sourceDeckId: json['source_deck_id'] as String? ?? '',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$DeckToJson(Deck instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'stats': instance.stats.toJson(),
  'rate': instance.rate,
  'owner': _ownerToJson(instance.owner),
  'fields': instance.fields,
  'min_interval': instance.minInterval,
  'def_interval': instance.defInterval,
  'max_interval': instance.maxInterval,
  'source_deck_id': instance.sourceDeckId,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
