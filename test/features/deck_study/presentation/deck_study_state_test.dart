import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/deck_study/presentation/bloc/deck_study_state.dart';

void main() {
  group('DeckStudyState', () {
    test('defaults match study screen initial expectations', () {
      const s = DeckStudyState(deckId: 'deck-1');
      expect(s.isLoading, false);
      expect(s.cardsStudied, 0);
      expect(s.showAnswer, true);
      expect(s.loadingPhase, DeckStudyLoadingPhase.initial);
      expect(s.selectedInterval, 0);
      expect(s.isHide, false);
      expect(s.cardDetail, isNull);
      expect(s.refreshedCardsCount, isNull);
    });

    test('copyWith updates selected interval and showAnswer', () {
      const s = DeckStudyState(
        deckId: 'deck-1',
        showAnswer: true,
        selectedInterval: 100,
      );
      final next = s.copyWith(showAnswer: false, selectedInterval: 200.0);
      expect(next.showAnswer, false);
      expect(next.selectedInterval, 200.0);
      expect(next.cardsStudied, 0);
    });

    test('copyWith preserves cardDetail when omitted', () {
      const s = DeckStudyState(deckId: 'deck-1', isLoading: true);
      final next = s.copyWith(isLoading: false);
      expect(next.isLoading, false);
      expect(next.cardDetail, isNull);
    });
  });
}
