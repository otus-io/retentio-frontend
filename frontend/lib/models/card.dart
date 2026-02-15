class CardDetail {
  final String factId;
  final int templateIndex;
  final int lastReview;
  final int dueDate;
  final bool hidden;
  final int minCalculation;
  final int maxCalculation;

  CardDetail({
    required this.factId,
    required this.templateIndex,
    required this.lastReview,
    required this.dueDate,
    required this.hidden,
    required this.minCalculation,
    required this.maxCalculation,
  });

  factory CardDetail.fromJson(Map<String, dynamic> json) {
    return CardDetail(
      factId: json['fact_id'] as String? ?? '',
      templateIndex: json['template_index'] as int? ?? 0,
      lastReview: json['last_review'] as int? ?? 0,
      dueDate: json['due_date'] as int? ?? 0,
      hidden: json['hidden'] as bool? ?? false,
      minCalculation: json['min_calculation'] as int? ?? 0,
      maxCalculation: json['max_calculation'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fact_id': factId,
      'template_index': templateIndex,
      'last_review': lastReview,
      'due_date': dueDate,
      'hidden': hidden,
      'min_calculation': minCalculation,
      'max_calculation': maxCalculation,
    };
  }

  /// 是否需要复习（到期时间小于当前时间）
  bool get isDue {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return dueDate <= now && !hidden;
  }

  /// 是否是新卡片（从未复习过）
  bool get isNew => lastReview == 0;
}

/// Parse fact from response: handles both new format {"id":"...","fields":["a","b"]}
/// and legacy format ["a","b"]
List<String> _parseFactFields(dynamic factData) {
  if (factData == null) return [];
  if (factData is Map) {
    final fields = factData['fields'] as List<dynamic>?;
    return fields?.map((e) => e.toString()).toList() ?? [];
  }
  if (factData is List) {
    return factData.map((e) => e.toString()).toList();
  }
  return [];
}

class Card {
  final CardDetail card;
  final int cardIndex;
  final int defInterval;
  final List<String> fact;
  final int hiddenCards;
  final int maxInterval;
  final int minInterval;
  final List<int> template;
  final double urgency;

  Card({
    required this.card,
    required this.cardIndex,
    required this.defInterval,
    required this.fact,
    required this.hiddenCards,
    required this.maxInterval,
    required this.minInterval,
    required this.template,
    required this.urgency,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    // 检查是否是简化版（直接包含 CardDetail 字段）还是完整版（嵌套 card 对象）
    final bool isSimplified =
        json.containsKey('fact_id') && !json.containsKey('card');

    if (isSimplified) {
      // 简化版：直接使用顶层的 CardDetail 字段
      return Card(
        card: CardDetail.fromJson(json),
        cardIndex: json['card_index'] as int? ?? 0,
        defInterval: json['def_interval'] as int? ?? 0,
        fact: _parseFactFields(json['fact']),
        hiddenCards: json['hidden_cards'] as int? ?? 0,
        maxInterval: json['max_interval'] as int? ?? 0,
        minInterval: json['min_interval'] as int? ?? 0,
        template:
            (json['template'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        urgency: (json['urgency'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      // 完整版：使用嵌套的 card 对象
      return Card(
        card: CardDetail.fromJson(json['card'] as Map<String, dynamic>),
        cardIndex: json['card_index'] as int? ?? 0,
        defInterval: json['def_interval'] as int? ?? 0,
        fact: _parseFactFields(json['fact']),
        hiddenCards: json['hidden_cards'] as int? ?? 0,
        maxInterval: json['max_interval'] as int? ?? 0,
        minInterval: json['min_interval'] as int? ?? 0,
        template:
            (json['template'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        urgency: (json['urgency'] as num?)?.toDouble() ?? 0.0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'card': card.toJson(),
      'card_index': cardIndex,
      'def_interval': defInterval,
      'fact': fact,
      'hidden_cards': hiddenCards,
      'max_interval': maxInterval,
      'min_interval': minInterval,
      'template': template,
      'urgency': urgency,
    };
  }

  /// 获取卡片正面内容（通常是第一个 fact）
  String get front => fact.isNotEmpty ? fact[0] : '';

  /// 获取卡片背面内容（通常是第二个 fact）
  String get back => fact.length > 1 ? fact[1] : '';

  /// 是否需要复习
  bool get isDue => card.isDue;

  /// 是否是新卡片
  bool get isNew => card.isNew;

  /// 是否被隐藏
  bool get isHidden => card.hidden;
}
