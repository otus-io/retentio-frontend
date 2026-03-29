// To parse this JSON data, do
//
//     final cardDetail = cardDetailFromJson(jsonString);

import 'dart:convert';

CardDetail cardDetailFromJson(String str) =>
    CardDetail.fromJson(json.decode(str));

String cardDetailToJson(CardDetail data) => json.encode(data.toJson());

class CardDetail {
  Card card;
  num urgency;

  CardDetail({required this.card, required this.urgency});

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
    return CardDetail(
      card: Card.fromJson(Map<String, dynamic>.from(cardRaw)),
      urgency: json['urgency'] as num? ?? 0,
    );
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

  Map<String, dynamic> toJson() => {"card": card.toJson(), "urgency": urgency};
}

class Card {
  List<CardSlot> back;
  int createdAt;
  int dueDate;
  String factId;
  List<CardSlot> front;
  bool hidden;
  String id;
  int lastReview;
  List<List<int>> template;

  Card({
    required this.back,
    required this.createdAt,
    required this.dueDate,
    required this.factId,
    required this.front,
    required this.hidden,
    required this.id,
    required this.lastReview,
    required this.template,
  });

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

  factory Card.fromJson(Map<String, dynamic> json) {
    int jsonInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    String jsonStr(dynamic v) => v is String ? v : (v?.toString() ?? '');

    final backJson = json['back'];
    final frontJson = json['front'];
    final templateJson = json['template'];

    return Card(
      back: backJson is List
          ? List<CardSlot>.from(
              backJson.map(
                (x) => CardSlot.fromJson(
                  Map<String, dynamic>.from(x as Map<dynamic, dynamic>),
                ),
              ),
            )
          : <CardSlot>[],
      createdAt: jsonInt(json['created_at']),
      dueDate: jsonInt(json['due_date']),
      factId: jsonStr(json['fact_id']),
      front: frontJson is List
          ? List<CardSlot>.from(
              frontJson.map(
                (x) => CardSlot.fromJson(
                  Map<String, dynamic>.from(x as Map<dynamic, dynamic>),
                ),
              ),
            )
          : <CardSlot>[],
      hidden: json['hidden'] as bool? ?? false,
      id: jsonStr(json['id']),
      lastReview: jsonInt(json['last_review']),
      template: templateJson is List
          ? List<List<int>>.from(
              templateJson.map(
                (x) => x is List
                    ? List<int>.from(x.map((e) => jsonInt(e)))
                    : <int>[],
              ),
            )
          : <List<int>>[],
    );
  }

  Map<String, dynamic> toJson() => {
    "back": List<dynamic>.from(back.map((x) => x.toJson())),
    "created_at": createdAt,
    "due_date": dueDate,
    "fact_id": factId,
    "front": List<dynamic>.from(front.map((x) => x.toJson())),
    "hidden": hidden,
    "id": id,
    "last_review": lastReview,
    "template": List<dynamic>.from(
      template.map((x) => List<dynamic>.from(x.map((x) => x))),
    ),
  };
}

class CardSlot {
  String field;
  List<Item> items;

  CardSlot({required this.field, required this.items});

  CardSlot copyWith({String? field, List<Item>? items}) =>
      CardSlot(field: field ?? this.field, items: items ?? this.items);

  /// Parses next-card face slots: legacy `{ field, items: [{type,value}] }` or
  /// `{ field?, text?, audio?, json?, image?, video? }` (synthesizes items in text→audio→json→image→video order).
  factory CardSlot.fromJson(Map<String, dynamic> json) {
    final field = (json["field"] as String?) ?? "Text";
    List<Item> items;
    if (json["items"] is List) {
      items = List<Item>.from(
        (json["items"] as List).map(
          (x) => Item.fromJson(
            Map<String, dynamic>.from(x as Map<dynamic, dynamic>),
          ),
        ),
      );
    } else {
      items = [];
      void addIf(String type, dynamic v) {
        if (v is String && v.isNotEmpty) {
          items.add(Item(type: type, value: v));
        }
      }

      addIf("text", json["text"]);
      addIf("audio", json["audio"]);
      addIf("json", json["json"]);
      addIf("image", json["image"]);
      addIf("video", json["video"]);
    }
    if (items.isEmpty) {
      items.add(Item(type: "text", value: ""));
    }
    return CardSlot(field: field, items: items);
  }

  Map<String, dynamic> toJson() => {
    "field": field,
    "items": List<dynamic>.from(items.map((x) => x.toJson())),
  };
}

class Item {
  String type;
  String value;

  Item({required this.type, required this.value});

  Item copyWith({String? type, String? value}) =>
      Item(type: type ?? this.type, value: value ?? this.value);

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    type: json['type'] as String? ?? '',
    value: json['value'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {"type": type, "value": value};
}
