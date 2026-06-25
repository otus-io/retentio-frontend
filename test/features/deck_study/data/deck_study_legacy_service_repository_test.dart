import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/deck_study/data/repositories/deck_study_legacy_service_repository.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/tag.dart';

void main() {
  group('DeckStudyLegacyServiceRepository', () {
    test(
      'loadNextDueCard skips deck refresh when tag filter has no cards',
      () async {
        var deckDetailCalls = 0;
        final repository = DeckStudyLegacyServiceRepository(
          getDeckDetailFn: (_) async {
            deckDetailCalls += 1;
            throw StateError('getDeckDetail should not be called');
          },
          loadNextDueCardFn: (_, {tagId}) async => null,
        );

        final result = await repository.loadNextDueCard(
          deckId: 'deck-1',
          tagId: 'tag-1',
        );

        expect(result.cardDetail, isNull);
        expect(result.refreshedCardsCount, isNull);
        expect(deckDetailCalls, 0);
      },
    );

    test(
      'loadNextDueCard refreshes deck count when no tag filter is active',
      () async {
        var deckDetailCalls = 0;
        final repository = DeckStudyLegacyServiceRepository(
          getDeckDetailFn: (_) async {
            deckDetailCalls += 1;
            return Deck.fromJson({
              'id': 'deck-1',
              'name': 'Deck',
              'stats': {'cards_count': 42},
              'rate': 30,
              'owner': {'username': 'u', 'email': 'u@t.com'},
              'fields': ['a'],
            });
          },
          loadNextDueCardFn: (_, {tagId}) async => null,
        );

        final result = await repository.loadNextDueCard(deckId: 'deck-1');

        expect(result.cardDetail, isNull);
        expect(result.refreshedCardsCount, 42);
        expect(deckDetailCalls, 1);
      },
    );

    test('loadDeckTags uses injected loader', () async {
      const tags = [Tag(id: 'tag-1', name: 'Grammar', description: '')];
      final repository = DeckStudyLegacyServiceRepository(
        loadDeckTagsFn: ({required deckId}) async {
          expect(deckId, 'deck-1');
          return tags;
        },
      );

      final result = await repository.loadDeckTags(deckId: 'deck-1');

      expect(result, tags);
    });
  });
}
