enum StudySyncType { review, hide }

enum StudySyncStatus { pending, failed }

/// One queued `PATCH /api/decks/{id}/card`, flushed FIFO by [sequence].
class StudySyncOperation {
  const StudySyncOperation({
    required this.operationId,
    required this.sequence,
    required this.deckId,
    required this.cardId,
    required this.type,
    required this.createdAt,
    this.interval,
    this.lastReview,
    this.hidden,
    this.attempts = 0,
    this.httpAttempts = 0,
    this.nextRetryAt = 0,
    this.status = StudySyncStatus.pending,
    this.lastError,
  });

  final String operationId;
  final int sequence;
  final String deckId;
  final String cardId;
  final StudySyncType type;
  final int createdAt;
  final int? interval;
  final int? lastReview;
  final bool? hidden;
  final int attempts;

  /// Attempts answered with a non-2xx HTTP status; network errors excluded.
  final int httpAttempts;
  final int nextRetryAt;
  final StudySyncStatus status;
  final String? lastError;

  /// Body for `PATCH /api/decks/{id}/card`; review and hide never mix.
  Map<String, dynamic> toPatchBody() => type == StudySyncType.review
      ? {'card_id': cardId, 'interval': interval, 'last_review': lastReview}
      : {'card_id': cardId, 'hidden': hidden ?? true};

  StudySyncOperation copyWith({
    int? attempts,
    int? httpAttempts,
    int? nextRetryAt,
    StudySyncStatus? status,
    String? lastError,
  }) => StudySyncOperation(
    operationId: operationId,
    sequence: sequence,
    deckId: deckId,
    cardId: cardId,
    type: type,
    createdAt: createdAt,
    interval: interval,
    lastReview: lastReview,
    hidden: hidden,
    attempts: attempts ?? this.attempts,
    httpAttempts: httpAttempts ?? this.httpAttempts,
    nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    status: status ?? this.status,
    lastError: lastError ?? this.lastError,
  );

  factory StudySyncOperation.fromJson(Map<String, dynamic> json) =>
      StudySyncOperation(
        operationId: '${json['operation_id'] ?? ''}',
        sequence: (json['sequence'] as num?)?.toInt() ?? 0,
        deckId: '${json['deck_id'] ?? ''}',
        cardId: '${json['card_id'] ?? ''}',
        type: json['type'] == 'hide'
            ? StudySyncType.hide
            : StudySyncType.review,
        createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
        interval: (json['interval'] as num?)?.toInt(),
        lastReview: (json['last_review'] as num?)?.toInt(),
        hidden: json['hidden'] as bool?,
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        httpAttempts: (json['http_attempts'] as num?)?.toInt() ?? 0,
        nextRetryAt: (json['next_retry_at'] as num?)?.toInt() ?? 0,
        status: json['status'] == 'failed'
            ? StudySyncStatus.failed
            : StudySyncStatus.pending,
        lastError: json['last_error'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'operation_id': operationId,
    'sequence': sequence,
    'deck_id': deckId,
    'card_id': cardId,
    'type': type.name,
    'created_at': createdAt,
    'interval': interval,
    'last_review': lastReview,
    'hidden': hidden,
    'attempts': attempts,
    'http_attempts': httpAttempts,
    'next_retry_at': nextRetryAt,
    'status': status.name,
    'last_error': lastError,
  };
}
