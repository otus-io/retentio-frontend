import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/providers/card_provider.dart';

import 'card_test_samples.dart';

/// No network in [build]; supplies a card so [CardSideContent] can render the menu.
class CardWithMenuNotifier extends CardNotifier {
  CardWithMenuNotifier([CardDetail? detail])
    : _detail = detail ?? sampleCardDetail();

  final CardDetail _detail;

  @override
  CardState build() {
    deck = ref.watch(deckProvider);
    ref.onDispose(flipCardController.dispose);
    return CardState(isLoading: false, cardDetail: _detail, showAnswer: true);
  }
}

/// Records [nextCard] hide flag (does not call the API).
class SpyHideCardNotifier extends CardNotifier {
  SpyHideCardNotifier() {
    active = this;
  }

  /// Latest notifier instance (Riverpod must not reuse the same [Notifier] instance).
  static SpyHideCardNotifier? active;

  bool? lastHideFlag;

  @override
  CardState build() {
    deck = ref.watch(deckProvider);
    ref.onDispose(flipCardController.dispose);
    return CardState(
      isLoading: false,
      cardDetail: sampleCardDetail(),
      showAnswer: true,
    );
  }

  @override
  Future<void> nextCard({bool isHide = false}) async {
    lastHideFlag = isHide;
  }
}

/// Counts [deleteCurrentCard] invocations (does not call the API).
class CountingDeleteCardNotifier extends CardNotifier {
  CountingDeleteCardNotifier() {
    active = this;
  }

  static CountingDeleteCardNotifier? active;

  int deleteCalls = 0;

  @override
  CardState build() {
    deck = ref.watch(deckProvider);
    ref.onDispose(flipCardController.dispose);
    return CardState(
      isLoading: false,
      cardDetail: sampleCardDetail(),
      showAnswer: true,
    );
  }

  @override
  Future<bool> deleteCurrentCard() async {
    deleteCalls++;
    return true;
  }
}

/// Session complete: [cardsStudied] equals deck card count; tracks [getCardDetail] calls.
class ReviewAgainHarnessNotifier extends CardNotifier {
  ReviewAgainHarnessNotifier({required this.deckCardCount}) {
    active = this;
  }

  static ReviewAgainHarnessNotifier? active;

  final int deckCardCount;
  int getCardDetailCalls = 0;

  @override
  CardState build() {
    deck = ref.watch(deckProvider);
    ref.onDispose(flipCardController.dispose);
    return CardState(
      isLoading: false,
      cardDetail: sampleCardDetail(),
      cardsStudied: deckCardCount,
      showAnswer: false,
    );
  }

  @override
  Future<void> getCardDetail() async {
    getCardDetailCalls++;
    if (!ref.mounted) return;
    state = state.copyWith(
      isLoading: false,
      cardDetail: null,
      refreshedCardsCount: 0,
    );
  }
}

/// [getCardDetail] is a no-op for [EditFactWidget] save tests.
class NoOpGetCardNotifier extends CardNotifier {
  @override
  CardState build() {
    deck = ref.watch(deckProvider);
    ref.onDispose(flipCardController.dispose);
    return CardState(isLoading: false);
  }

  @override
  Future<void> getCardDetail() async {}
}

/// Exercises real [reviewAgain] without HTTP: [getCardDetail] is stubbed.
class ReviewAgainStateNotifier extends CardNotifier {
  @override
  CardState build() {
    deck = ref.watch(deckProvider);
    ref.onDispose(flipCardController.dispose);
    return CardState(
      isLoading: false,
      cardDetail: sampleCardDetail(),
      cardsStudied: 3,
      showAnswer: false,
    );
  }

  @override
  Future<void> getCardDetail() async {
    if (!ref.mounted) return;
    state = state.copyWith(
      isLoading: false,
      cardDetail: null,
      refreshedCardsCount: 0,
    );
  }
}
