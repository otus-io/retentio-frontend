import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/card_widgets/card_video.dart';
import 'package:retentio/screen/deck/providers/card_review.dart';
import 'package:retentio/video_player/src/custom_video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../helpers/immediate_empty_card_notifier.dart';
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deckProvider.overrideWithValue(testDeck),
            cardProvider.overrideWith(ImmediateEmptyCardNotifier.new),
          ],
          child: MaterialApp(
            home: DefaultTabController(
              length: 1,
              child: Scaffold(
                body: CardVideo(url: 'https://example.com/dispose-early.mp4'),
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deckProvider.overrideWithValue(testDeck),
            cardProvider.overrideWith(ImmediateEmptyCardNotifier.new),
          ],
          child: MaterialApp(
            home: DefaultTabController(
              length: 1,
              child: Scaffold(
                body: CardVideo(url: 'https://example.com/ok.mp4'),
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
