import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/features/deck_study/presentation/bloc/deck_study_event.dart';
import 'package:retentio/features/deck_study/presentation/bloc/deck_study_state.dart';

import '../../../helpers/card_test_samples.dart';
import '../../../helpers/fake_deck_study_bloc.dart';

void main() {
  group('DeckStudyBloc lookahead', () {
    test('shows the prefetched card without a loading phase', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        loadResults: [
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-a'),
            nextCardDetail: sampleCardDetail(id: 'card-b'),
          ),
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-b'),
            nextCardDetail: sampleCardDetail(id: 'card-c'),
          ),
        ],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail?.card.id, 'card-a');
      expect(harness.bloc.state.prefetchedCard?.card.id, 'card-b');

      final observed = <DeckStudyState>[];
      final subscription = harness.bloc.stream.listen(observed.add);
      addTearDown(subscription.cancel);

      harness.bloc.add(const DeckStudyNextCardRequested());
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail?.card.id, 'card-b');
      expect(harness.bloc.state.cardsStudied, 1);
      expect(observed, isNotEmpty);
      expect(observed.every((state) => !state.isLoading), isTrue);
      expect(harness.repository.reviewSubmitCalls, 1);
      // Background refill replenishes the lookahead for the next review.
      expect(harness.repository.loadCalls, 2);
      expect(harness.bloc.state.prefetchedCard?.card.id, 'card-c');
    });

    test('falls back to a blocking load when nothing is prefetched', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        loadResults: [
          DeckStudyLoadResult(cardDetail: sampleCardDetail(id: 'card-a')),
          DeckStudyLoadResult(cardDetail: sampleCardDetail(id: 'card-b')),
        ],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      expect(harness.bloc.state.prefetchedCard, isNull);

      final observed = <DeckStudyState>[];
      final subscription = harness.bloc.stream.listen(observed.add);
      addTearDown(subscription.cancel);

      harness.bloc.add(const DeckStudyNextCardRequested());
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail?.card.id, 'card-b');
      expect(observed.any((state) => state.isLoading), isTrue);
      expect(harness.repository.loadCalls, 2);
    });

    test('keeps the visible card when the server re-ranks the queue', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        loadResults: [
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-a'),
            nextCardDetail: sampleCardDetail(id: 'card-b'),
          ),
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-x'),
            nextCardDetail: sampleCardDetail(id: 'card-y'),
          ),
        ],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      harness.bloc.add(const DeckStudyNextCardRequested());
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail?.card.id, 'card-b');
      expect(harness.bloc.state.prefetchedCard?.card.id, 'card-x');
    });

    test('drops the prefetched card when the tag filter changes', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        loadResults: [
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-a'),
            nextCardDetail: sampleCardDetail(id: 'card-b'),
          ),
          DeckStudyLoadResult(cardDetail: sampleCardDetail(id: 'card-tagged')),
        ],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      harness.bloc.add(const DeckStudyTagFilterChanged('tag-1'));
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail?.card.id, 'card-tagged');
      expect(harness.bloc.state.prefetchedCard, isNull);
    });

    test('stays empty for a deck with no cards', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        loadResults: const [DeckStudyLoadResult(cardDetail: null)],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail, isNull);
      expect(harness.bloc.state.prefetchedCard, isNull);
      expect(harness.bloc.state.loadingPhase, DeckStudyLoadingPhase.loaded);

      harness.bloc.add(const DeckStudyNextCardRequested());
      await pumpEventQueue();

      expect(harness.repository.reviewSubmitCalls, 0);
      expect(harness.bloc.state.cardDetail, isNull);
      expect(harness.bloc.state.prefetchedCard, isNull);
    });

    test('reloads the only card of a single-card deck on advance', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        loadResults: [
          DeckStudyLoadResult(cardDetail: sampleCardDetail(id: 'card-a')),
          DeckStudyLoadResult(cardDetail: sampleCardDetail(id: 'card-a')),
        ],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      expect(harness.bloc.state.prefetchedCard, isNull);

      harness.bloc.add(const DeckStudyNextCardRequested());
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail?.card.id, 'card-a');
      expect(harness.bloc.state.prefetchedCard, isNull);
      expect(harness.repository.reviewSubmitCalls, 1);
      expect(harness.repository.loadCalls, 2);
    });

    test('alternates between the two cards of a two-card deck', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        loadResults: [
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-a'),
            nextCardDetail: sampleCardDetail(id: 'card-b'),
          ),
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-b'),
            nextCardDetail: sampleCardDetail(id: 'card-a'),
          ),
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-a'),
            nextCardDetail: sampleCardDetail(id: 'card-b'),
          ),
        ],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      harness.bloc.add(const DeckStudyNextCardRequested());
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail?.card.id, 'card-b');
      expect(harness.bloc.state.prefetchedCard?.card.id, 'card-a');

      harness.bloc.add(const DeckStudyNextCardRequested());
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail?.card.id, 'card-a');
      expect(harness.bloc.state.prefetchedCard?.card.id, 'card-b');
      expect(harness.bloc.state.cardsStudied, 2);
    });

    test('clears the lookahead when hiding leaves one card left', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        loadResults: [
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-a'),
            nextCardDetail: sampleCardDetail(id: 'card-b'),
          ),
          DeckStudyLoadResult(cardDetail: sampleCardDetail(id: 'card-b')),
        ],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      harness.bloc.add(const DeckStudyNextCardRequested(hideCurrentCard: true));
      await pumpEventQueue();

      expect(harness.repository.hideSubmitCalls, 1);
      expect(harness.bloc.state.cardDetail?.card.id, 'card-b');
      expect(harness.bloc.state.prefetchedCard, isNull);
    });

    test('keeps the promoted card and counts when the refill fails', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        loadResults: [
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-a'),
            nextCardDetail: sampleCardDetail(id: 'card-b'),
            refreshedDueCardsCount: 4,
          ),
          const DeckStudyLoadResult(cardDetail: null),
        ],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      harness.bloc.add(const DeckStudyNextCardRequested());
      await pumpEventQueue();

      expect(harness.bloc.state.cardDetail?.card.id, 'card-b');
      expect(harness.bloc.state.refreshedDueCardsCount, 4);
      expect(harness.bloc.state.prefetchedCard, isNull);
    });

    test('keeps the card and its lookahead when the submit fails', () async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: 'deck-1',
        submitShouldSucceed: false,
        loadResults: [
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(id: 'card-a'),
            nextCardDetail: sampleCardDetail(id: 'card-b'),
          ),
        ],
      );
      addTearDown(harness.dispose);
      await pumpEventQueue();

      harness.bloc.add(const DeckStudyNextCardRequested());
      await pumpEventQueue();

      expect(harness.bloc.state.loadingPhase, DeckStudyLoadingPhase.error);
      expect(harness.bloc.state.cardDetail?.card.id, 'card-a');
      expect(harness.bloc.state.prefetchedCard?.card.id, 'card-b');
    });
  });
}
