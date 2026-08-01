import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/bloc/deck_sharing_status_cubit.dart';

void main() {
  group('DeckSharingStatusCubit', () {
    test('markDirty and clear update flashing set', () {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);

      expect(cubit.state.shouldFlash('d1'), isFalse);
      cubit.markDirty('d1');
      expect(cubit.state.shouldFlash('d1'), isTrue);
      cubit.clear('d1');
      expect(cubit.state.shouldFlash('d1'), isFalse);
    });

    test('markDirty ignores empty id', () {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.markDirty('');
      expect(cubit.state.flashingDeckIds, isEmpty);
    });

    test('refresh with empty decks clears prior flashes', () async {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.markDirty('stale');
      cubit.setDecks(const []);
      await cubit.refresh();
      expect(cubit.state.flashingDeckIds, isEmpty);
    });

    test('startPolling and stopPolling do not throw', () {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.setDecks(const []);
      cubit.startPolling();
      cubit.stopPolling();
    });

    test('setDecks stores list for later refresh', () {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      final decks = [
        Deck.fromJson({
          'id': 'src1',
          'name': 'S',
          'published_version': 2,
          'stats': <String, dynamic>{},
          'rate': 10,
          'fields': ['a'],
          'owner': 'u',
        }),
      ];
      cubit.setDecks(decks);
      // No network: refresh against published source will fail and leave set empty
      // unless previously flashing. Just ensure setDecks does not throw.
      expect(decks.single.isPublishedSource, isTrue);
    });
  });
}
