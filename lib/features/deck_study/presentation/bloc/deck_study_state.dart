import 'package:equatable/equatable.dart';
import 'package:retentio/models/card.dart';

enum DeckStudyLoadingPhase { initial, loading, loaded, error }

class DeckStudyState extends Equatable {
  const DeckStudyState({
    required this.deckId,
    this.cardDetail,
    this.isLoading = false,
    this.cardsStudied = 0,
    this.showAnswer = true,
    this.loadingPhase = DeckStudyLoadingPhase.initial,
    this.selectedInterval = 0,
    this.isHide = false,
    this.refreshedCardsCount,
    this.minInterval = 0,
    this.maxInterval = 0,
    this.errorMessage,
  });

  final String deckId;
  final CardDetail? cardDetail;
  final bool isLoading;
  final int cardsStudied;
  final bool showAnswer;
  final DeckStudyLoadingPhase loadingPhase;
  final double selectedInterval;
  final bool isHide;
  final int? refreshedCardsCount;
  final double minInterval;
  final double maxInterval;
  final String? errorMessage;

  bool get hasCard => cardDetail != null;

  DeckStudyState copyWith({
    CardDetail? cardDetail,
    bool resetCardDetail = false,
    bool? isLoading,
    int? cardsStudied,
    bool? showAnswer,
    DeckStudyLoadingPhase? loadingPhase,
    double? selectedInterval,
    bool? isHide,
    int? refreshedCardsCount,
    bool clearRefreshedCardsCount = false,
    double? minInterval,
    double? maxInterval,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return DeckStudyState(
      deckId: deckId,
      cardDetail: resetCardDetail ? null : (cardDetail ?? this.cardDetail),
      isLoading: isLoading ?? this.isLoading,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      showAnswer: showAnswer ?? this.showAnswer,
      loadingPhase: loadingPhase ?? this.loadingPhase,
      selectedInterval: selectedInterval ?? this.selectedInterval,
      isHide: isHide ?? this.isHide,
      refreshedCardsCount: clearRefreshedCardsCount
          ? null
          : (refreshedCardsCount ?? this.refreshedCardsCount),
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
    cardDetail,
    isLoading,
    cardsStudied,
    showAnswer,
    loadingPhase,
    selectedInterval,
    isHide,
    refreshedCardsCount,
    minInterval,
    maxInterval,
    errorMessage,
  ];
}
