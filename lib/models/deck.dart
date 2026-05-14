import 'package:json_annotation/json_annotation.dart';

part 'deck.g.dart';

const DeckStats _emptyDeckStats = DeckStats(
  cardsCount: 0,
  factsCount: 0,
  unseenCards: 0,
  reviewedCards: 0,
  dueCards: 0,
  hiddenCards: 0,
  newCardsToday: 0,
  lastReviewedAt: 0,
);

@JsonSerializable()
class DeckOwner {
  const DeckOwner({
    @JsonKey(defaultValue: '') required this.username,
    @JsonKey(defaultValue: '') required this.email,
  });

  final String username;
  final String email;

  factory DeckOwner.fromJson(Map<String, dynamic> json) =>
      _$DeckOwnerFromJson(json);

  Map<String, dynamic> toJson() => _$DeckOwnerToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DeckStats {
  const DeckStats({
    @JsonKey(defaultValue: 0) required this.cardsCount,
    @JsonKey(defaultValue: 0) required this.factsCount,
    @JsonKey(defaultValue: 0) required this.unseenCards,
    @JsonKey(defaultValue: 0) required this.reviewedCards,
    @JsonKey(defaultValue: 0) required this.dueCards,
    @JsonKey(defaultValue: 0) required this.hiddenCards,
    @JsonKey(defaultValue: 0) required this.newCardsToday,
    @JsonKey(defaultValue: 0, fromJson: _intFromJson)
    required this.lastReviewedAt,
  });

  final int cardsCount;
  final int factsCount;
  final int unseenCards;
  final int reviewedCards;
  final int dueCards;
  final int hiddenCards;
  final int newCardsToday;
  final int lastReviewedAt;

  factory DeckStats.fromJson(Map<String, dynamic> json) =>
      _$DeckStatsFromJson(json);

  Map<String, dynamic> toJson() => _$DeckStatsToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Deck {
  const Deck({
    @JsonKey(defaultValue: '') required this.id,
    @JsonKey(defaultValue: '') required this.name,
    this.stats = _emptyDeckStats,
    @JsonKey(defaultValue: 0) required this.rate,
    this.owner = const DeckOwner(username: 'unknown', email: ''),
    @JsonKey(defaultValue: <String>[]) required this.fields,
    @JsonKey(defaultValue: 0) required this.minInterval,
    @JsonKey(defaultValue: 0) required this.defInterval,
    @JsonKey(defaultValue: 0) required this.maxInterval,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final DeckStats stats;
  final int rate;
  @JsonKey(fromJson: _ownerFromJson, toJson: _ownerToJson)
  final DeckOwner owner;
  final List<String> fields;
  final int minInterval;
  final int defInterval;
  final int maxInterval;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Deck copyWith({required String name}) => Deck(
    id: id,
    name: name,
    stats: stats,
    rate: rate,
    owner: owner,
    fields: fields,
    minInterval: minInterval,
    defInterval: defInterval,
    maxInterval: maxInterval,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory Deck.fromJson(Map<String, dynamic> json) =>
      _$DeckFromJson(_normalizeDeckJson(json));

  Map<String, dynamic> toJson() => _$DeckToJson(this);

  double get progress {
    if (stats.cardsCount == 0) return 0.0;
    final learned = stats.cardsCount - stats.unseenCards;
    return (learned / stats.cardsCount * 100).clamp(0.0, 100.0);
  }

  int get totalCards => stats.cardsCount;

  int get learnedCards => stats.cardsCount - stats.unseenCards;

  int get reviewCards => stats.dueCards;
}

int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DeckOwner _ownerFromJson(dynamic owner) {
  if (owner is DeckOwner) {
    return owner;
  }
  if (owner is String) {
    return DeckOwner(username: owner, email: '');
  }
  if (owner is Map<String, dynamic>) {
    return DeckOwner.fromJson(owner);
  }
  if (owner is Map) {
    return DeckOwner.fromJson(Map<String, dynamic>.from(owner));
  }
  return const DeckOwner(username: 'unknown', email: '');
}

Map<String, dynamic> _ownerToJson(DeckOwner owner) => owner.toJson();

Map<String, dynamic> _normalizeDeckJson(Map<String, dynamic> raw) {
  final json = Map<String, dynamic>.from(raw);

  final fieldsData = json['fields'] ?? json['field'];
  if (fieldsData is List) {
    json['fields'] = fieldsData.map((e) => e?.toString() ?? '').toList();
  } else {
    json['fields'] = <String>[];
  }

  final stats = json['stats'];
  if (stats is Map<String, dynamic>) {
    json['stats'] = stats;
  } else if (stats is Map) {
    json['stats'] = Map<String, dynamic>.from(stats);
  } else {
    json['stats'] = <String, dynamic>{};
  }

  return json;
}
