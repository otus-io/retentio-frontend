// To parse this JSON data, do
//
//     final cardDetail = cardDetailFromJson(jsonString);

import 'dart:convert';

CardDetail cardDetailFromJson(String str) =>
    CardDetail.fromJson(json.decode(str));

String cardDetailToJson(CardDetail data) => json.encode(data.toJson());

class CardDetail {
  Card card;

  CardDetail({required this.card});

  factory CardDetail.fromJson(Map<String, dynamic> json) =>
      CardDetail(card: Card.fromJson(json["card"]));

  Map<String, dynamic> toJson() => {"card": card.toJson()};
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
  String type;
  String value;

  Back({required this.field, required this.type, required this.value});

  factory Back.fromJson(Map<String, dynamic> json) =>
      Back(field: json["field"], type: json["type"], value: json["value"]);

  Map<String, dynamic> toJson() => {
    "field": field,
    "type": type,
    "value": value,
  };
}
