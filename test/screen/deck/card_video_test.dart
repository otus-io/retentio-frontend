import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/card_widgets/card_video.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/providers/deck_scope.dart';
import 'package:retentio/video_player/src/custom_video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_deck_study_bloc.dart';
import '../../helpers/test_video_player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDeck = Deck.fromJson({
    'id': 'deck-card-video-test',
    'name': 'Test',
    'stats': {
      'cards_count': 1,
      'unseen_cards': 0,
      'due_cards': 1,
      'facts_count': 1,
    },
    'rate': 10,
    'owner': {'username': 'u', 'email': 'u@t.com'},
    'fields': ['front'],
  });

  group('CardVideo', () {
    late VideoPlayerPlatform previousPlatform;

    setUp(() {
      previousPlatform = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = TestVideoPlayerPlatform();
    });

    tearDown(() {
      VideoPlayerPlatform.instance = previousPlatform;
    });

    testWidgets('disposing before init completes does not throw', (
      tester,
    ) async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: testDeck.id,
        loadResults: [DeckStudyLoadResult(cardDetail: sampleCardDetail())],
      );
      addTearDown(() async => harness.dispose());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeckProvider.overrideWithValue(testDeck),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
          child: MaterialApp(
            home: DefaultTabController(
              length: 1,
              child: BlocProvider.value(
                value: harness.bloc,
                child: Scaffold(
                  body: CardVideo(url: 'https://example.com/dispose-early.mp4'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump();
      // [AllControlsOverlay] uses Future.delayed(durationAfterControlsFadeOut) (3s);
      // flush timers so the test binding does not fail on dispose.
      await tester.pump(const Duration(seconds: 4));

      expect(tester.takeException(), isNull);
    });

    testWidgets('after init completes, shows CustomVideoPlayer', (
      tester,
    ) async {
      final harness = FakeDeckStudyBlocHarness(
        deckId: testDeck.id,
        loadResults: [DeckStudyLoadResult(cardDetail: sampleCardDetail())],
      );
      addTearDown(() async => harness.dispose());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeckProvider.overrideWithValue(testDeck),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
          child: MaterialApp(
            home: DefaultTabController(
              length: 1,
              child: BlocProvider.value(
                value: harness.bloc,
                child: Scaffold(
                  body: CardVideo(url: 'https://example.com/ok.mp4'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(CustomVideoPlayer).evaluate().isNotEmpty) break;
      }

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomVideoPlayer), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
