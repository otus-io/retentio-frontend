import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/providers/loading_state_provider.dart';
import 'package:retentio/screen/deck/providers/card_review.dart';

void main() {
  group('CardState', () {
    test('defaults match study screen initial expectations', () {
      final s = CardState();
      expect(s.isLoading, false);
      expect(s.cardsStudied, 0);
      expect(s.showAnswer, true);
      expect(s.loadingState, LoadingState.loaded);
      expect(s.selectedInterval, 0);
      expect(s.isHide, false);
      expect(s.cardDetail, isNull);
    });

    test('copyWith updates selected interval and showAnswer', () {
      final s = CardState(showAnswer: true, selectedInterval: 100);
      final next = s.copyWith(showAnswer: false, selectedInterval: 200.0);
      expect(next.showAnswer, false);
      expect(next.selectedInterval, 200.0);
      expect(next.cardsStudied, 0);
    });

    test('copyWith preserves cardDetail when omitted', () {
      final s = CardState(isLoading: true);
      final next = s.copyWith(isLoading: false);
      expect(next.isLoading, false);
      expect(next.cardDetail, isNull);
    });
  });
}
