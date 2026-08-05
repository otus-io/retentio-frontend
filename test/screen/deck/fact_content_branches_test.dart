import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/card_widgets/card_audio.dart';
import 'package:retentio/screen/deck/card_widgets/card_image.dart';
import 'package:retentio/screen/deck/card_widgets/card_text.dart';
import 'package:retentio/screen/deck/card_widgets/card_video.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_content.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../helpers/test_video_player_platform.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });
  tearDownAll(tearDownTestEnvironment);

  late VideoPlayerPlatform previousVideoPlatform;

  setUp(() {
    previousVideoPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = TestVideoPlayerPlatform();
  });

  tearDown(() {
    VideoPlayerPlatform.instance = previousVideoPlatform;
  });

  Future<void> pumpFactContent(
    WidgetTester tester, {
    required List<Item> items,
    bool inline = false,
  }) async {
    await tester.pumpWidget(
      buildTestableWidgetWithOverrides(
        Scaffold(
          body: SizedBox(
            height: 400,
            width: 300,
            child: FactContent(
              items: items,
              color: Colors.black,
              inline: inline,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// [TabBarView] builds pages lazily, so media pages only exist once their
  /// tab is selected.
  Future<void> openTab(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Unmounts media widgets and drains their timers so the test binding does
  /// not fail on pending timers/tickers from image retries or video controls.
  Future<void> disposeMedia(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    await tester.pump(const Duration(seconds: 4));
  }

  group('FactContent single-pane (no tab bar)', () {
    testWidgets('audio-only field still renders the play control', (
      tester,
    ) async {
      await pumpFactContent(
        tester,
        items: [Item(type: 'audio', value: 'https://cdn.example.com/a.m4a')],
      );

      expect(find.byType(TabBarView), findsNothing);
      expect(find.byType(CardAudio), findsOneWidget);
    });

    testWidgets('every audio item on a text field gets its own control', (
      tester,
    ) async {
      await pumpFactContent(
        tester,
        items: [
          Item(type: 'text', value: 'Hello'),
          Item(type: 'audio', value: 'https://cdn.example.com/a.m4a'),
          Item(type: 'audio', value: 'https://cdn.example.com/b.m4a'),
        ],
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(TabBarView), findsNothing);
      expect(find.byType(CardAudio), findsNWidgets(2));
      // Two audio items → no shared scope above, each control owns its player.
      for (final audio in tester.widgetList<CardAudio>(
        find.byType(CardAudio),
      )) {
        expect(audio.useExternalScope, isFalse);
      }
    });

    testWidgets('single audio item shares the scope opened by FactContent', (
      tester,
    ) async {
      await pumpFactContent(
        tester,
        items: [
          Item(type: 'text', value: 'Hello'),
          Item(type: 'audio', value: 'https://cdn.example.com/a.m4a'),
        ],
      );

      final audio = tester.widget<CardAudio>(find.byType(CardAudio));
      expect(audio.useExternalScope, isTrue);
      expect(audio.compact, isTrue);
    });

    testWidgets('json items are ignored', (tester) async {
      await pumpFactContent(
        tester,
        items: [
          Item(type: 'text', value: 'Hello'),
          Item(type: 'json', value: '{"a":1}'),
        ],
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('{"a":1}'), findsNothing);
      expect(find.byType(CardAudio), findsNothing);
      expect(find.byType(TabBarView), findsNothing);
    });

    testWidgets('no items renders an empty CardText', (tester) async {
      await pumpFactContent(tester, items: const []);

      expect(find.byType(CardText), findsOneWidget);
      expect(tester.widget<CardText>(find.byType(CardText)).text, '');
      expect(find.byType(TabBarView), findsNothing);
    });
  });

  group('FactContent tabbed (multiple content types)', () {
    testWidgets('text plus image renders a tab bar with an image tab', (
      tester,
    ) async {
      await pumpFactContent(
        tester,
        items: [
          Item(type: 'text', value: 'Hello'),
          Item(type: 'image', value: 'https://cdn.example.com/a.png'),
        ],
      );

      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.byIcon(LucideIcons.image), findsOneWidget);
      expect(find.byIcon(LucideIcons.fileText), findsOneWidget);

      await openTab(tester, LucideIcons.image);
      expect(find.byType(CardImage), findsOneWidget);

      await disposeMedia(tester);
    });

    testWidgets('text plus video renders a video tab', (tester) async {
      await pumpFactContent(
        tester,
        items: [
          Item(type: 'text', value: 'Hello'),
          Item(type: 'video', value: 'https://cdn.example.com/a.mp4'),
        ],
      );

      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.byIcon(LucideIcons.video), findsOneWidget);

      await openTab(tester, LucideIcons.video);
      expect(find.byType(CardVideo), findsOneWidget);

      await disposeMedia(tester);
    });

    testWidgets('audio control sits on the tab bar next to the text tab', (
      tester,
    ) async {
      await pumpFactContent(
        tester,
        items: [
          Item(type: 'text', value: 'Hello'),
          Item(type: 'audio', value: 'https://cdn.example.com/a.m4a'),
          Item(type: 'image', value: 'https://cdn.example.com/a.png'),
        ],
      );

      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.byType(CardAudio), findsOneWidget);
      // Single audio item → shared scope provided above the tab tree.
      expect(
        tester.widget<CardAudio>(find.byType(CardAudio)).useExternalScope,
        isTrue,
      );

      // Audio stays reachable on the tab bar while the image tab is open.
      await openTab(tester, LucideIcons.image);
      expect(find.byType(CardImage), findsOneWidget);
      expect(find.byType(CardAudio), findsOneWidget);

      await disposeMedia(tester);
    });

    testWidgets('two audio items with media keep independent scopes', (
      tester,
    ) async {
      await pumpFactContent(
        tester,
        items: [
          Item(type: 'text', value: 'Hello'),
          Item(type: 'audio', value: 'https://cdn.example.com/a.m4a'),
          Item(type: 'audio', value: 'https://cdn.example.com/b.m4a'),
          Item(type: 'image', value: 'https://cdn.example.com/a.png'),
        ],
      );

      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.byType(CardAudio), findsNWidgets(2));
      for (final audio in tester.widgetList<CardAudio>(
        find.byType(CardAudio),
      )) {
        expect(audio.useExternalScope, isFalse);
      }

      await disposeMedia(tester);
    });
  });

  group('FactContent inline', () {
    testWidgets('inline text plus audio renders the play control', (
      tester,
    ) async {
      await pumpFactContent(
        tester,
        inline: true,
        items: [
          Item(type: 'text', value: 'Hello'),
          Item(type: 'audio', value: 'https://cdn.example.com/a.m4a'),
        ],
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(TabBarView), findsNothing);
      final audio = tester.widget<CardAudio>(find.byType(CardAudio));
      expect(audio.useExternalScope, isTrue);
    });

    testWidgets('inline renders a control per audio item', (tester) async {
      await pumpFactContent(
        tester,
        inline: true,
        items: [
          Item(type: 'audio', value: 'https://cdn.example.com/a.m4a'),
          Item(type: 'audio', value: 'https://cdn.example.com/b.m4a'),
        ],
      );

      expect(find.byType(CardAudio), findsNWidgets(2));
      for (final audio in tester.widgetList<CardAudio>(
        find.byType(CardAudio),
      )) {
        expect(audio.useExternalScope, isFalse);
      }
    });

    testWidgets('inline renders media below the text', (tester) async {
      await pumpFactContent(
        tester,
        inline: true,
        items: [
          Item(type: 'text', value: 'Hello'),
          Item(type: 'image', value: 'https://cdn.example.com/a.png'),
        ],
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(CardImage), findsOneWidget);
      expect(find.byType(TabBarView), findsNothing);

      await disposeMedia(tester);
    });
  });
}
