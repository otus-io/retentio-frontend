import 'package:equatable/equatable.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/models/tag.dart';

enum DeckStudyLoadingPhase { initial, loading, loaded, error }

class DeckStudyState extends Equatable {
  const DeckStudyState({
    required this.deckId,
    this.deckTags = const [],
    this.activeTagId,
    this.cardDetail,
    this.isLoading = false,
    this.cardsStudied = 0,
    this.loadingPhase = DeckStudyLoadingPhase.initial,
    this.selectedInterval = 0,
    this.isHide = false,
    this.refreshedCardsCount,
    this.refreshedDueCardsCount,
    this.sessionDueTarget,
    this.minInterval = 0,
    this.maxInterval = 0,
    this.errorMessage,
  });

  final String deckId;
  final List<Tag> deckTags;
  final String? activeTagId;
  final CardDetail? cardDetail;
  final bool isLoading;
  final int cardsStudied;
  final DeckStudyLoadingPhase loadingPhase;
  final double selectedInterval;
  final bool isHide;
  final int? refreshedCardsCount;

  /// Live due count (deck-wide or tag-scoped).
  final int? refreshedDueCardsCount;

  /// Frozen due count at session/filter start for progress-bar target (option A).
  final int? sessionDueTarget;
  final double minInterval;
  final double maxInterval;
  final String? errorMessage;

  bool get hasCard => cardDetail != null;

  DeckStudyState copyWith({
    List<Tag>? deckTags,
    String? activeTagId,
    bool clearActiveTagId = false,
    CardDetail? cardDetail,
    bool resetCardDetail = false,
    bool? isLoading,
    int? cardsStudied,
    DeckStudyLoadingPhase? loadingPhase,
    double? selectedInterval,
    bool? isHide,
    int? refreshedCardsCount,
    bool clearRefreshedCardsCount = false,
    int? refreshedDueCardsCount,
    bool clearRefreshedDueCardsCount = false,
    int? sessionDueTarget,
    bool clearSessionDueTarget = false,
    double? minInterval,
    double? maxInterval,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return DeckStudyState(
      deckId: deckId,
      deckTags: deckTags ?? this.deckTags,
      activeTagId: clearActiveTagId ? null : (activeTagId ?? this.activeTagId),
      cardDetail: resetCardDetail ? null : (cardDetail ?? this.cardDetail),
      isLoading: isLoading ?? this.isLoading,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      loadingPhase: loadingPhase ?? this.loadingPhase,
      selectedInterval: selectedInterval ?? this.selectedInterval,
      isHide: isHide ?? this.isHide,
      refreshedCardsCount: clearRefreshedCardsCount
          ? null
          : (refreshedCardsCount ?? this.refreshedCardsCount),
      refreshedDueCardsCount: clearRefreshedDueCardsCount
          ? null
          : (refreshedDueCardsCount ?? this.refreshedDueCardsCount),
      sessionDueTarget: clearSessionDueTarget
          ? null
          : (sessionDueTarget ?? this.sessionDueTarget),
      minInterval: minInterval ?? this.minInterval,
      maxInterval: maxInterval ?? this.maxInterval,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    deckId,
    deckTags,
    activeTagId,
    cardDetail,
    isLoading,
    cardsStudied,
    loadingPhase,
    selectedInterval,
    isHide,
    refreshedCardsCount,
    refreshedDueCardsCount,
    sessionDueTarget,
    minInterval,
    maxInterval,
    errorMessage,
  ];
}
