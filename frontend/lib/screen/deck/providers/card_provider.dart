import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordupx/providers/loading_state_provider.dart';
import 'package:wordupx/screen/deck/widgets/flash_card/flash_card_controller.dart';
import 'package:wordupx/utils/log.dart';

import '../../../models/card.dart';
import '../../../models/deck.dart';
import '../../../services/apis/card_service.dart';

final cardProvider = NotifierProvider.autoDispose
    .family<CardNotifier, CardState, Deck>(CardNotifier.new);

class CardNotifier extends Notifier<CardState> {
  final Deck deck;

  /// 本次学习会话的总卡片数
  int get totalCardsInSession => deck.stats.unseenCards + deck.reviewCards;

  final FlashCardController flashCardController = FlashCardController();

  CardNotifier(this.deck);

  @override
  CardState build() {
    getRecommendedFact();
    ref.onDispose(() {
      logger.e('CardNotifier onDispose');
      flashCardController.dispose();
    });
    return CardState(isLoading: true);
  }

  ///获取推荐的Fact
  Future<void> getRecommendedFact() async {
    await getAllFacts();
    getCardDetail();
  }

  void toggleShowAnswer() {
    state = state.copyWith(
      showAnswer: !state.showAnswer,
      loadingState: LoadingState.loaded,
    );
  }

  Future<void> nextCard() async {
    state = state.copyWith(loadingState: LoadingState.initial);
    await reviewCard();
    await getCardDetail();
    state = state.copyWith(cardsStudied: state.cardsStudied + 1);
  }

  Future<void> reviewCard() async {
    await CardService.updateCard(deck.id, {
      'card_id': state.cardDetail?.card.id,
      'interval': 150,
      'last_review': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<void> getCardDetail() async {
    final response = await CardService.getNextDueCard(deck.id);

    if (response != null) {
      final facts = state.facts;
      final factId = response.card.factId;
      var fact = facts.firstWhereOrNull((element) => element.id == factId);
      fact ??= await CardService.getFact(deck.id, factId);
      final cardDetail = response.copyWith(fact: fact);
      state = state.copyWith(cardDetail: cardDetail, isLoading: false);
    }
  }

  Future<void> getAllFacts() async {
    final response = await CardService.getDeckCards(deck.id);
    state = CardState(facts: response);
  }
}

class CardState {
  final CardDetail? cardDetail;
  final List<Fact> facts;
  final bool isLoading;

  /// 已经学过的卡片数
  final int cardsStudied;

  final bool showAnswer;

  final LoadingState loadingState;

  CardState({
    this.cardDetail,
    this.facts = const [],
    this.isLoading = false,
    this.cardsStudied = 0,
    this.showAnswer = true,
    this.loadingState = LoadingState.loaded,
  });

  CardState copyWith({
    CardDetail? cardDetail,
    List<Fact>? facts,
    bool? isLoading,
    int? cardsStudied,
    bool? showAnswer,
    LoadingState? loadingState,
  }) {
    return CardState(
      cardDetail: cardDetail ?? this.cardDetail,
      facts: facts ?? this.facts,
      isLoading: isLoading ?? this.isLoading,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      showAnswer: showAnswer ?? this.showAnswer,
      loadingState: loadingState ?? this.loadingState,
    );
  }
}
