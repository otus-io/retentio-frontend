import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/providers/card_review.dart';

import '../helpers/card_test_samples.dart';
import '../helpers/test_card_notifiers.dart';

void main() {
  group('shouldIgnoreCardDetailForReview', () {
    test('false for null', () {
      expect(shouldIgnoreCardDetailForReview(null), false);
    });

    test('false when card is not hidden', () {
      expect(
        shouldIgnoreCardDetailForReview(sampleCardDetail(hidden: false)),
        false,
      );
    });

    test('true when card is hidden', () {
      expect(
        shouldIgnoreCardDetailForReview(sampleCardDetail(hidden: true)),
        true,
      );
    });
  });

  group('CardNotifier.reviewAgain', () {
    test(
      'resets studied count, showAnswer, and clears card after stub fetch',
      () async {
        final container = ProviderContainer(
          overrides: [
            deckProvider.overrideWithValue(sampleDeck()),
            cardProvider.overrideWith(ReviewAgainStateNotifier.new),
          ],
        );
        addTearDown(container.dispose);

        await container.read(cardProvider.notifier).reviewAgain();

        final s = container.read(cardProvider);
        expect(s.cardsStudied, 0);
        expect(s.showAnswer, true);
        expect(s.cardDetail, isNull);
        expect(s.isLoading, false);
      },
    );
  });
}
