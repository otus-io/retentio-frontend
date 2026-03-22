class DeckOwner {
  final String username;
  final String email;

  DeckOwner({required this.username, required this.email});

  factory DeckOwner.fromJson(Map<String, dynamic> json) {
    return DeckOwner(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'username': username, 'email': email};
  }
}

class DeckStats {
  final int cardsCount;
  final int factsCount;
  final int unseenCards;
  final int reviewedCards;
  final int dueCards;
  final int hiddenCards;
  final int newCardsToday;
  final int lastReviewedAt;

  DeckStats({
    required this.cardsCount,
    required this.factsCount,
    required this.unseenCards,
    required this.reviewedCards,
    required this.dueCards,
    required this.hiddenCards,
    required this.newCardsToday,
    required this.lastReviewedAt,
  });

  factory DeckStats.fromJson(Map<String, dynamic> json) {
    return DeckStats(
      cardsCount: json['cards_count'] as int? ?? 0,
      factsCount: json['facts_count'] as int? ?? 0,
      unseenCards: json['unseen_cards'] as int? ?? 0,
      reviewedCards: json['reviewed_cards'] as int? ?? 0,
      dueCards: json['due_cards'] as int? ?? 0,
      hiddenCards: json['hidden_cards'] as int? ?? 0,
      newCardsToday: json['new_cards_today'] as int? ?? 0,
      lastReviewedAt: (json['last_reviewed_at'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cards_count': cardsCount,
      'facts_count': factsCount,
      'unseen_cards': unseenCards,
      'reviewed_cards': reviewedCards,
      'due_cards': dueCards,
      'hidden_cards': hiddenCards,
      'new_cards_today': newCardsToday,
      'last_reviewed_at': lastReviewedAt,
    };
  }
}

class Deck {
  final String id;
  final String name;
  final DeckStats stats;
  final int rate;
  final DeckOwner owner;
  final List<String> fields;
  final int minInterval;
  final int defInterval;
  final int maxInterval;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Deck({
    required this.id,
    required this.name,
    required this.stats,
    required this.rate,
    required this.owner,
    required this.fields,
    required this.minInterval,
    required this.defInterval,
    required this.maxInterval,
    this.createdAt,
    this.updatedAt,
  });

  ///copyWith
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

  /// 从 JSON 创建 Deck 对象
  factory Deck.fromJson(Map<String, dynamic> json) {
    // 兼容处理 owner, API可能返回 "username" 或 { "username": "...", "email": "..." }
    DeckOwner parsedOwner;
    if (json['owner'] is String) {
      parsedOwner = DeckOwner(
        username: json['owner'] as String? ?? '',
        email: '',
      );
    } else if (json['owner'] is Map) {
      parsedOwner = DeckOwner.fromJson(
        json['owner'] as Map<String, dynamic>? ?? {},
      );
    } else {
      parsedOwner = DeckOwner(username: 'unknown', email: '');
    }

    // 兼容处理 field/fields
    final fieldsData = json['fields'] ?? json['field'];
    return Deck(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      stats: DeckStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      rate: json['rate'] as int? ?? 0,
      owner: parsedOwner,
      fields:
          (fieldsData as List<dynamic>?)
              ?.map((e) => e as String? ?? '')
              .toList() ??
          [],
      minInterval: json['min_interval'] as int? ?? 0,
      defInterval: json['def_interval'] as int? ?? 0,
      maxInterval: json['max_interval'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stats': stats.toJson(),
      'rate': rate,
      'owner': owner.toJson(),
      'fields': fields,
      'min_interval': minInterval,
      'def_interval': defInterval,
      'max_interval': maxInterval,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// 学习进度百分比
  double get progress {
    if (stats.cardsCount == 0) return 0.0;
    final learned = stats.cardsCount - stats.unseenCards;
    return (learned / stats.cardsCount * 100).clamp(0.0, 100.0);
  }

  /// 总卡片数
  int get totalCards => stats.cardsCount;

  /// 已学习卡片数
  int get learnedCards => stats.cardsCount - stats.unseenCards;

  /// 待复习卡片数
  int get reviewCards => stats.dueCards;
}
