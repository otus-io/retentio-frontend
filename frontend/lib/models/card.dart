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

  factory CardDetail.fromJson(Map<String, dynamic> json) =>
      CardDetail(card: Card.fromJson(json["card"]), urgency: json["urgency"]);

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
  List<Back> back;
  int createdAt;
  int dueDate;
  String factId;
  List<Back> front;
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
    List<Back>? back,
    int? createdAt,
    int? dueDate,
    String? factId,
    List<Back>? front,
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

  factory Card.fromJson(Map<String, dynamic> json) => Card(
    back: List<Back>.from(json["back"].map((x) => Back.fromJson(x))),
    createdAt: json["created_at"],
    dueDate: json["due_date"],
    factId: json["fact_id"],
    front: List<Back>.from(json["front"].map((x) => Back.fromJson(x))),
    hidden: json["hidden"],
    id: json["id"],
    lastReview: json["last_review"],
    template: List<List<int>>.from(
      json["template"].map((x) => List<int>.from(x.map((x) => x))),
    ),
  );

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

class Back {
  String field;
  List<Item> items;

  Back({required this.field, required this.items});

  Back copyWith({String? field, List<Item>? items}) =>
      Back(field: field ?? this.field, items: items ?? this.items);

  /// Parses next-card face slots: legacy `{ field, items: [{type,value}] }` or
  /// `{ field?, text?, audio?, image?, video? }` (synthesizes items in text→audio→image→video order).
  factory Back.fromJson(Map<String, dynamic> json) {
    final field = (json["field"] as String?) ?? "Text";
    List<Item> items;
    if (json["items"] is List) {
      items = List<Item>.from(
        (json["items"] as List).map(
          (x) => Item.fromJson(Map<String, dynamic>.from(x as Map)),
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
      addIf("image", json["image"]);
      addIf("video", json["video"]);
    }
    if (items.isEmpty) {
      items.add(Item(type: "text", value: ""));
    }
    return Back(field: field, items: items);
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

  factory Item.fromJson(Map<String, dynamic> json) =>
      Item(type: json["type"], value: json["value"]);

  Map<String, dynamic> toJson() => {"type": type, "value": value};
}
