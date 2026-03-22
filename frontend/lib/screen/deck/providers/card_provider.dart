import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:retentio/providers/loading_state_provider.dart';
import 'package:retentio/screen/deck/widgets/flash_card/flash_card_controller.dart';
import 'package:retentio/utils/log.dart';

import '../../../models/card.dart';
import '../../../models/deck.dart';
import '../../../services/apis/card_service.dart';
import '../../../services/apis/deck_service.dart';

final cardProvider = NotifierProvider.autoDispose<CardNotifier, CardState>(
  CardNotifier.new,
  dependencies: [deckProvider],
);
final deckProvider = Provider.autoDispose<Deck>(
  (ref) => throw UnimplementedError(
    'deckProvider must be overridden in CardNotifier',
  ),
);

/// Hidden cards must not be shown in review (defense in depth vs GET /card).
@visibleForTesting
bool shouldIgnoreCardDetailForReview(CardDetail? response) =>
    response != null && (response.card?.hidden??false);

class CardNotifier extends Notifier<CardState> {
  late Deck deck;

  /// 本次学习会话的总卡片数
  int get totalCardsInSession => deck.stats.cardsCount;

  final FlashCardController flashCardController = FlashCardController();
  late List<double> scope;

  void calculateScope() {
    if (state.cardDetail == null) {
      return;
    }
    final dueDate = state.cardDetail!.card!.dueDate;
    final lastReview = state.cardDetail!.card!.lastReview;
    final currentInterval = dueDate - lastReview;
    final urgency =
        (DateTime.now().microsecondsSinceEpoch ~/ 1000 - lastReview) /
        (dueDate - lastReview);
    final minInterval = urgency >= 1
        ? currentInterval * 0.5
        : currentInterval * ((0.5 - 1) * urgency + 1);
    final maxInterval = urgency >= 1
        ? currentInterval * 4.0
        : currentInterval * ((4.0 - 1) * urgency + 1);
    scope = [minInterval, maxInterval];
    // 设置初始间隔为范围的中间值
    final midInterval = (minInterval + maxInterval) / 2;
    state = state.copyWith(selectedInterval: midInterval);
    logger.d('scope:$currentInterval $scope, midInterval: $midInterval');
  }

  @override
  CardState build() {
    deck = ref.watch(deckProvider);
    scope = [0, 0];
    getCardDetail();
    ref.onDispose(flashCardController.dispose);
    return CardState(isLoading: true, selectedInterval: 0);
  }

  void selectInterval(double interval) {
    state = state.copyWith(selectedInterval: interval);
  }

  void showAnswer() {
    state = state.copyWith(showAnswer: true, loadingState: LoadingState.loaded);
  }

  void toggleShowAnswer() {
    state = state.copyWith(
      showAnswer: !state.showAnswer,
      loadingState: LoadingState.loaded,
    );
  }

  Future<void> nextCard({bool isHide = false}) async {
    state = state.copyWith(loadingState: LoadingState.initial, isHide: isHide);
    await reviewCard(isHide: isHide);
    if (!ref.mounted) return;
    await getCardDetail();
    if (!ref.mounted) return;
    state = state.copyWith(cardsStudied: state.cardsStudied + 1);
  }

  Future<void> reviewAgain() async {
    state = state.copyWith(
      loadingState: LoadingState.initial,
      isHide: false,
      showAnswer: true,
      cardsStudied: 0,
      isLoading: true,
      cardDetail: null,
      clearRefreshedCardsCount: true,
    );
    await getCardDetail();
  }

  Future<void> reviewCard({bool isHide = false}) async {
    await CardService.updateCard(deck.id, {
      if (isHide)
        'hidden': state.isHide
      else
        'interval': state.selectedInterval,
      if (!isHide) 'last_review': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'card_id': state.cardDetail?.card!.id,
    });
  }

  /// Permanently deletes the current card (`DELETE .../cards/{cardId}`), then refreshes.
  Future<bool> deleteCurrentCard() async {
    final cardId = state.cardDetail?.card!.id;
    if (cardId == null) return false;
    final res = await CardService.deleteCard(deck.id, cardId);
    if (!ref.mounted) return false;
    if (res?.isSuccess != true) return false;
    await getCardDetail();
    if (!ref.mounted) return false;
    flashCardController.showFront();
    showAnswer();
    return true;
  }

  Future<void> getCardDetail() async {
    var response = await CardService.getNextDueCard(deck.id);

    if (!ref.mounted) return;

    // Next-card API should skip hidden cards; never surface a hidden card in review.
    if (shouldIgnoreCardDetailForReview(response)) {
      logger.w('Ignoring hidden card in getCardDetail: ${response!.card!.id}');
      response = null;
    }

    if (response != null) {
      state = state.copyWith(
        cardDetail: response,
        isLoading: false,
        isHide: false,
        clearRefreshedCardsCount: true,
      );
      calculateScope();
    } else {
      int? refreshedCount;
      try {
        final d = await DeckService.of.getDeckDetail(deck.id);
        refreshedCount = d.stats.cardsCount;
      } catch (_) {
        /* keep stale deck stats */
      }
      if (!ref.mounted) return;
      state = state.copyWith(
        cardDetail: null,
        isLoading: false,
        isHide: false,
        refreshedCardsCount: refreshedCount,
      );
    }
  }
}

/// Sentinel for [CardState.copyWith] when [cardDetail] should be left unchanged.
const _cardDetailUnset = Object();

class CardState {
  final CardDetail? cardDetail;
  final bool isLoading;

  /// 已经学过的卡片数
  final int cardsStudied;

  final bool showAnswer;

  final LoadingState loadingState;

  final double selectedInterval;

  final bool isHide;

  /// Set when GET `/card` returns no card; [DeckService.getDeckDetail] updates count.
  final int? refreshedCardsCount;

  CardState({
    this.cardDetail,
    this.isLoading = false,
    this.cardsStudied = 0,
    this.showAnswer = true,
    this.loadingState = LoadingState.loaded,
    this.selectedInterval = 0,
    this.isHide = false,
    this.refreshedCardsCount,
  });

  CardState copyWith({
    Object? cardDetail = _cardDetailUnset,
    bool? isLoading,
    int? cardsStudied,
    bool? showAnswer,
    LoadingState? loadingState,
    double? selectedInterval,
    bool? isHide,
    int? refreshedCardsCount,
    bool clearRefreshedCardsCount = false,
  }) {
    return CardState(
      cardDetail: identical(cardDetail, _cardDetailUnset)
          ? this.cardDetail
          : cardDetail as CardDetail?,
      isLoading: isLoading ?? this.isLoading,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      showAnswer: showAnswer ?? this.showAnswer,
      loadingState: loadingState ?? this.loadingState,
      selectedInterval: selectedInterval ?? this.selectedInterval,
      isHide: isHide ?? this.isHide,
      refreshedCardsCount: clearRefreshedCardsCount
          ? null
          : (refreshedCardsCount ?? this.refreshedCardsCount),
    );
  }
}
