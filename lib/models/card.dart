// To parse this JSON data, do
//
//     final cardDetail = cardDetailFromJson(jsonString);

import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'card.g.dart';

CardDetail cardDetailFromJson(String str) =>
    CardDetail.fromJson(json.decode(str));

String cardDetailToJson(CardDetail data) => json.encode(data.toJson());

@JsonSerializable(explicitToJson: true)
class CardDetail {
  CardDetail({
    @JsonKey(fromJson: _cardFromJson, toJson: _cardToJson) required this.card,
    @JsonKey(defaultValue: 0, fromJson: _numFromJson) required this.urgency,
  });

  final Card card;
  final num urgency;

  CardDetail copyWith({Card? card, double? urgency}) =>
      CardDetail(card: card ?? this.card, urgency: urgency ?? this.urgency);

  factory CardDetail.fromJson(Map<String, dynamic> json) {
    final cardRaw = json['card'];
    if (cardRaw is! Map) {
      throw ArgumentError.value(
        cardRaw,
        'card',
        'CardDetail.fromJson requires card to be a JSON object',
      );
    }
    return _$CardDetailFromJson(Map<String, dynamic>.from(json));
  }

  /// Parses GET `/decks/:id/card` style payloads. Returns null when the API
  /// sends `"card": []` (no due card) or `card` is not a JSON object.
  static CardDetail? tryFromApiData(dynamic data) {
    if (data == null) return null;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    if (map.isEmpty) return null;
    final cardRaw = map['card'];
    if (cardRaw is List) return null;
    if (cardRaw is! Map) return null;
    map['card'] = Map<String, dynamic>.from(cardRaw);
    map['urgency'] ??= 0;
    return CardDetail.fromJson(map);
  }

  Map<String, dynamic> toJson() => _$CardDetailToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Card {
  Card({
    @JsonKey(defaultValue: <CardSlot>[]) required this.back,
    @JsonKey(defaultValue: 0) required this.createdAt,
    @JsonKey(defaultValue: 0) required this.dueDate,
    @JsonKey(defaultValue: '') required this.factId,
    @JsonKey(defaultValue: <CardSlot>[]) required this.front,
    @JsonKey(defaultValue: false) required this.hidden,
    @JsonKey(defaultValue: '') required this.id,
    @JsonKey(defaultValue: 0) required this.lastReview,
    @JsonKey(defaultValue: <List<int>>[]) required this.template,
  });

  final List<CardSlot> back;
  final int createdAt;
  final int dueDate;
  final String factId;
  final List<CardSlot> front;
  final bool hidden;
  final String id;
  final int lastReview;
  final List<List<int>> template;

  Card copyWith({
    List<CardSlot>? back,
    int? createdAt,
    int? dueDate,
    String? factId,
    List<CardSlot>? front,
    bool? hidden,
    String? id,
    int? lastReview,
    List<List<int>>? template,
  }) => Card(
    back: back ?? this.back,
    createdAt: createdAt ?? this.createdAt,
    dueDate: dueDate ?? this.dueDate,
    factId: factId ?? this.factId,
    front: front ?? this.front,
    hidden: hidden ?? this.hidden,
    id: id ?? this.id,
    lastReview: lastReview ?? this.lastReview,
    template: template ?? this.template,
  );

  factory Card.fromJson(Map<String, dynamic> json) =>
      _$CardFromJson(_normalizeCardJson(json));

  Map<String, dynamic> toJson() => _$CardToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CardSlot {
  CardSlot({
    @JsonKey(defaultValue: 'Text') required this.field,
    @JsonKey(defaultValue: <Item>[]) required this.items,
  });

  final String field;
  final List<Item> items;

  CardSlot copyWith({String? field, List<Item>? items}) =>
      CardSlot(field: field ?? this.field, items: items ?? this.items);

  /// Parses next-card face slots: legacy `{ field, items: [{type,value}] }` or
  /// `{ field?, text?, audio?, json?, image?, video? }` (synthesizes items in text→audio→json→image→video order).
  factory CardSlot.fromJson(Map<String, dynamic> json) =>
      _$CardSlotFromJson(_normalizeCardSlotJson(json));

  Map<String, dynamic> toJson() => _$CardSlotToJson(this);
}

@JsonSerializable()
class Item {
  Item({
    @JsonKey(defaultValue: '') required this.type,
    @JsonKey(defaultValue: '') required this.value,
  });

  final String type;
  final String value;

  Item copyWith({String? type, String? value}) =>
      Item(type: type ?? this.type, value: value ?? this.value);

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

num _numFromJson(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

Card _cardFromJson(dynamic value) {
  if (value is Card) return value;
  if (value is Map<String, dynamic>) {
    return Card.fromJson(value);
  }
  if (value is Map) {
    return Card.fromJson(Map<String, dynamic>.from(value));
  }
  throw ArgumentError.value(
    value,
    'card',
    'CardDetail.fromJson requires card to be a JSON object',
  );
}

Map<String, dynamic> _cardToJson(Card value) => value.toJson();

int _intFromJson(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

String _stringFromJson(dynamic v) => v is String ? v : (v?.toString() ?? '');

Map<String, dynamic> _normalizeCardJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);

  final backJson = out['back'];
  if (backJson is List) {
    out['back'] = backJson
        .whereType<Map>()
        .map((x) => _normalizeCardSlotJson(Map<String, dynamic>.from(x)))
        .toList();
  } else {
    out['back'] = <Map<String, dynamic>>[];
  }

  final frontJson = out['front'];
  if (frontJson is List) {
    out['front'] = frontJson
        .whereType<Map>()
        .map((x) => _normalizeCardSlotJson(Map<String, dynamic>.from(x)))
        .toList();
  } else {
    out['front'] = <Map<String, dynamic>>[];
  }

  final templateJson = out['template'];
  if (templateJson is List) {
    out['template'] = templateJson
        .map((x) => x is List ? x.map(_intFromJson).toList() : <int>[])
        .toList();
  } else {
    out['template'] = <List<int>>[];
  }

  out['created_at'] = _intFromJson(out['created_at']);
  out['due_date'] = _intFromJson(out['due_date']);
  out['last_review'] = _intFromJson(out['last_review']);
  out['fact_id'] = _stringFromJson(out['fact_id']);
  out['id'] = _stringFromJson(out['id']);
  out['hidden'] = out['hidden'] == true;

  return out;
}

Map<String, dynamic> _normalizeCardSlotJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);

  final field = out['field'];
  out['field'] = field is String ? field : 'Text';

  final rawItems = out['items'];
  if (rawItems is List) {
    final normalizedItems = rawItems
        .whereType<Map>()
        .map((x) => Map<String, dynamic>.from(x))
        .toList();
    out['items'] = normalizedItems.isEmpty
        ? <Map<String, dynamic>>[
            <String, dynamic>{'type': 'text', 'value': ''},
          ]
        : normalizedItems;
    return out;
  }

  final items = <Map<String, dynamic>>[];

  void addIf(String type, dynamic v) {
    if (v is String && v.isNotEmpty) {
      items.add(<String, dynamic>{'type': type, 'value': v});
    }
  }

  addIf('text', out['text']);
  addIf('audio', out['audio']);
  addIf('json', out['json']);
  addIf('image', out['image']);
  addIf('video', out['video']);

  out['items'] = items.isEmpty
      ? <Map<String, dynamic>>[
          <String, dynamic>{'type': 'text', 'value': ''},
        ]
      : items;
  return out;
}
