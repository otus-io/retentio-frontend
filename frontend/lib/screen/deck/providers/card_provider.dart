import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  final icons = {
    'text': LucideIcons.fileText,
    'image': LucideIcons.fileImage,
    'audio': LucideIcons.fileSignal,
  };

  /// 本次学习会话的总卡片数
  int get totalCardsInSession => deck.stats.unseenCards + deck.reviewCards;

  final FlashCardController flashCardController = FlashCardController();
  late List<double> scope;

  CardNotifier(this.deck);

  void calculateScope() {
    if (state.cardDetail == null) {
      return;
    }
    final dueDate = state.cardDetail!.card.dueDate;
    final lastReview = state.cardDetail!.card.lastReview;
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
    scope = [0, 0];
    getCardDetail();
    ref.onDispose(() {
      logger.w('CardNotifier onDispose');
      flashCardController.dispose();
    });
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
    await getCardDetail();
    state = state.copyWith(cardsStudied: state.cardsStudied + 1);
  }

  Future<void> reviewCard({bool isHide = false}) async {
    await CardService.updateCard(deck.id, {
      if (isHide)
        'hidden': state.isHide
      else
        'interval': state.selectedInterval,
      if (!isHide) 'last_review': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'card_id': state.cardDetail?.card.id,
    });
  }

  Future<void> getCardDetail() async {
    final response = await CardService.getNextDueCard(deck.id);

    if (response != null) {
      state = state.copyWith(
        cardDetail: response,
        isLoading: false,
        isHide: false,
      );
      calculateScope();
    }
  }
}

class CardState {
  final CardDetail? cardDetail;
  final bool isLoading;

  /// 已经学过的卡片数
  final int cardsStudied;

  final bool showAnswer;

  final LoadingState loadingState;

  final double selectedInterval;

  final bool isHide;

  CardState({
    this.cardDetail,
    this.isLoading = false,
    this.cardsStudied = 0,
    this.showAnswer = true,
    this.loadingState = LoadingState.loaded,
    this.selectedInterval = 0,
    this.isHide = false,
  });

  CardState copyWith({
    CardDetail? cardDetail,
    bool? isLoading,
    int? cardsStudied,
    bool? showAnswer,
    LoadingState? loadingState,
    double? selectedInterval,
    bool? isHide,
  }) {
    return CardState(
      cardDetail: cardDetail ?? this.cardDetail,
      isLoading: isLoading ?? this.isLoading,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      showAnswer: showAnswer ?? this.showAnswer,
      loadingState: loadingState ?? this.loadingState,
      selectedInterval: selectedInterval ?? this.selectedInterval,
      isHide: isHide ?? this.isHide,
    );
  }
}
