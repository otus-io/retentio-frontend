import 'package:equatable/equatable.dart';

/// One segment in front/back: at most one of text, audio, image; optional field.
class FrontBackSegment extends Equatable {
  final String? field;
  final String? text;
  final String? audio;
  final String? image;

  const FrontBackSegment({this.field, this.text, this.audio, this.image});

  static FrontBackSegment? fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return FrontBackSegment(
      field: raw['field']?.toString(),
      text: raw['text']?.toString(),
      audio: raw['audio']?.toString(),
      image: raw['image']?.toString(),
    );
  }

  static List<FrontBackSegment> listFromJson(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => FrontBackSegment.fromJson(e))
        .whereType<FrontBackSegment>()
        .toList();
  }

  @override
  List<Object?> get props => [field, text, audio, image];
}

class CardDetail extends Equatable {
  final Card card;
  final double urgency;

  const CardDetail({required this.card, required this.urgency});

  factory CardDetail.fromJson(Map<String, dynamic> json) {
    final cardJson = json['card'];
    final card = cardJson is Map<String, dynamic>
        ? Card.fromJson(cardJson)
        : Card(
            id: '',
            factId: '',
            template: [
              [0],
              [1],
            ],
            lastReview: 0,
            dueDate: 0,
            hidden: false,
            createdAt: 0,
          );
    final urgency = (json['urgency'] is num)
        ? (json['urgency'] as num).toDouble()
        : 0.0;
    return CardDetail(card: card, urgency: urgency);
  }

  Map<String, dynamic> toJson() => {"card": card.toJson(), "urgency": urgency};

  CardDetail? copyWith({Fact? fact}) {
    return CardDetail(
      card: card.copyWith(fact: fact),
      urgency: urgency,
    );
  }

  @override
  List<Object?> get props => [card, urgency];
}

class Card extends Equatable {
  final int createdAt;
  final int dueDate;
  final String factId;
  final bool hidden;
  final String id;
  final int lastReview;
  final List<List<int>> template;
  final Fact? fact;
  final List<FrontBackSegment>? frontSegments;
  final List<FrontBackSegment>? backSegments;

  const Card({
    required this.createdAt,
    required this.dueDate,
    required this.factId,
    required this.hidden,
    required this.id,
    required this.lastReview,
    required this.template,
    this.fact,
    this.frontSegments,
    this.backSegments,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    List<List<int>> t = [];
    final raw = json['template'];
    if (raw is List) {
      for (final row in raw) {
        if (row is List) {
          t.add([for (final x in row) (x as num).toInt()]);
        }
      }
    }
    if (t.length != 2) {
      t = [
        [0],
        [1],
      ];
    }
    final frontRaw = json['front'];
    final backRaw = json['back'];
    return Card(
      createdAt: json["created_at"] as int? ?? 0,
      dueDate: json["due_date"] as int? ?? 0,
      factId: json["fact_id"] as String? ?? '',
      hidden: json["hidden"] as bool? ?? false,
      id: json["id"] as String? ?? '',
      lastReview: json["last_review"] as int? ?? 0,
      template: t,
      frontSegments: frontRaw != null
          ? FrontBackSegment.listFromJson(frontRaw)
          : null,
      backSegments: backRaw != null
          ? FrontBackSegment.listFromJson(backRaw)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "created_at": createdAt,
    "due_date": dueDate,
    "fact_id": factId,
    "hidden": hidden,
    "id": id,
    "last_review": lastReview,
    "template": template,
    "fact": fact?.toJson(),
  };

  /// 是否需要复习（到期时间小于当前时间）
  bool get isDue {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return dueDate <= now && !hidden;
  }

  /// 是否是新卡片（从未复习过）
  bool get isNew => lastReview == 0;

  /// 获取卡片正面内容（优先使用 API 返回的 front 段，否则用 fact）
  String get front {
    if (frontSegments != null && frontSegments!.isNotEmpty) {
      final texts = frontSegments!
          .map((s) => s.text)
          .whereType<String>()
          .toList();
      return texts.isNotEmpty ? texts.join(' ') : '';
    }
    if (fact != null && fact!.fields.isNotEmpty) return fact!.fields[0];
    return '';
  }

  /// 获取卡片背面内容（优先使用 API 返回的 back 段，否则用 fact）
  String get back {
    if (backSegments != null && backSegments!.isNotEmpty) {
      final texts = backSegments!
          .map((s) => s.text)
          .whereType<String>()
          .toList();
      return texts.isNotEmpty ? texts.join(' ') : '';
    }
    if (fact != null && fact!.fields.length > 1) return fact!.fields[1];
    return '';
  }

  /// 是否被隐藏
  bool get isHidden => hidden;

  Card copyWith({Fact? fact}) {
    return Card(
      createdAt: createdAt,
      dueDate: dueDate,
      factId: factId,
      hidden: hidden,
      id: id,
      lastReview: lastReview,
      template: template,
      fact: fact ?? this.fact,
      frontSegments: frontSegments,
      backSegments: backSegments,
    );
  }

  @override
  List<Object?> get props => [id, factId, fact, frontSegments, backSegments];
}

class Fact extends Equatable {
  final List<String> fields;
  final String id;

  const Fact({required this.fields, required this.id});

  factory Fact.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'] ?? json['fields'];
    final list = raw is List
        ? List<String>.from(raw.map((x) => x?.toString() ?? ''))
        : <String>[];
    return Fact(id: json['id']?.toString() ?? '', fields: list);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'entries': List<dynamic>.from(fields),
  };

  @override
  List<Object?> get props => [fields, id];
}

/// Response shape for GET /api/decks/{id}/cards (card statistics).
class CardStats {
  final int totalCards;
  final int hiddenCount;
  final List<Fact> hiddenFacts;

  const CardStats({
    required this.totalCards,
    required this.hiddenCount,
    required this.hiddenFacts,
  });

  factory CardStats.fromJson(Map<String, dynamic> json) {
    final rawFacts = json['hidden_facts'];
    final list = rawFacts is List
        ? (rawFacts)
              .map((e) => e is Map<String, dynamic> ? Fact.fromJson(e) : null)
              .whereType<Fact>()
              .toList()
        : <Fact>[];
    return CardStats(
      totalCards: (json['total_cards'] as num?)?.toInt() ?? 0,
      hiddenCount: (json['hidden_count'] as num?)?.toInt() ?? 0,
      hiddenFacts: list,
    );
  }
}
