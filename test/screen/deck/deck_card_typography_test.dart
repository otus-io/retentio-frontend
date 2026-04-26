import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retentio/models/transcript_sync.dart';
import 'package:retentio/screen/deck/card_widgets/card_text.dart';
import 'package:retentio/screen/deck/card_widgets/card_transcript_text.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_font_sheet.dart';
import 'package:retentio/screen/deck/providers/deck_card_typography.dart';

import '../../helpers/test_wrapper.dart';
import '../../helpers/transcript_test_overrides.dart';

String _formatTypo(DeckCardTypography t) =>
    '${t.baseFontSize.toStringAsFixed(1)}|${t.rubyFontSize.toStringAsFixed(1)}';

String _formatSides(DeckCardSidesTypography s) =>
    '${_formatTypo(s.front)}|${_formatTypo(s.back)}';

class _TypographySidesLabel extends ConsumerWidget {
  const _TypographySidesLabel({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(deckSidesTypographyProvider(deckId));
    return Text(_formatSides(s), textDirection: TextDirection.ltr);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupTestEnvironment();
    deckCardTypographyUsePlainTextStyleInTests = true;
  });

  tearDownAll(() async {
    deckCardTypographyUsePlainTextStyleInTests = false;
    tearDownTestEnvironment();
  });

  group('DeckCardTypography model', () {
    test('clamped enforces min and max for base and ruby', () {
      const t = DeckCardTypography(baseFontSize: 4, rubyFontSize: 40);
      final c = t.clamped();
      expect(c.baseFontSize, DeckCardTypography.minBase);
      expect(c.rubyFontSize, DeckCardTypography.maxRuby);
    });

    test('copyWith preserves unspecified fields', () {
      const t = DeckCardTypography(baseFontSize: 18, rubyFontSize: 10);
      expect(t.copyWith(baseFontSize: 20).rubyFontSize, 10);
      expect(t.copyWith(rubyFontSize: 8).baseFontSize, 18);
    });
  });

  group('DeckCardSidesTypography', () {
    test('forSide selects front or back', () {
      const s = DeckCardSidesTypography(
        front: DeckCardTypography(baseFontSize: 10, rubyFontSize: 5),
        back: DeckCardTypography(baseFontSize: 20, rubyFontSize: 8),
      );
      expect(s.forSide(true).baseFontSize, 10);
      expect(s.forSide(false).baseFontSize, 20);
    });

    test('copyWith overrides one side only', () {
      const s = DeckCardSidesTypography.defaults;
      final next = s.copyWith(
        front: const DeckCardTypography(baseFontSize: 22, rubyFontSize: 11),
      );
      expect(next.front.baseFontSize, 22);
      expect(next.back.baseFontSize, 18);
      final next2 = s.copyWith(
        back: const DeckCardTypography(baseFontSize: 30, rubyFontSize: 12),
      );
      expect(next2.front.baseFontSize, 18);
      expect(next2.back.baseFontSize, 30);
    });
  });

  group('deckSidesTypographyProvider', () {
    testWidgets('hydrates front and back from SharedPreferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'deck_typography_base_front_v1_d-hydrate': 20.0,
        'deck_typography_ruby_front_v1_d-hydrate': 10.0,
        'deck_typography_base_back_v1_d-hydrate': 26.0,
        'deck_typography_ruby_back_v1_d-hydrate': 15.0,
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: _TypographySidesLabel(deckId: 'd-hydrate')),
          ),
        ),
      );

      expect(
        find.text(_formatSides(DeckCardSidesTypography.defaults)),
        findsOneWidget,
      );

      await tester.pump();
      expect(find.text('20.0|10.0|26.0|15.0'), findsOneWidget);
    });

    testWidgets('migrates legacy single prefs to both sides', (tester) async {
      SharedPreferences.setMockInitialValues({
        'deck_typography_base_v1_d-legacy': 21.0,
        'deck_typography_ruby_v1_d-legacy': 11.0,
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: _TypographySidesLabel(deckId: 'd-legacy')),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('21.0|11.0|21.0|11.0'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('deck_typography_base_front_v1_d-legacy'), 21.0);
      expect(prefs.getDouble('deck_typography_base_back_v1_d-legacy'), 21.0);
    });

    testWidgets('persistCurrent writes clamped values for both sides', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return TextButton(
                    onPressed: () async {
                      final n = ref.read(
                        deckSidesTypographyProvider('d-persist').notifier,
                      );
                      n
                        ..setBaseFontSize(true, 40)
                        ..setRubyFontSize(true, 3)
                        ..setBaseFontSize(false, 5)
                        ..setRubyFontSize(false, 50);
                      await n.persistCurrent();
                    },
                    child: const Text('persist'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('persist'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getDouble('deck_typography_base_front_v1_d-persist'),
        DeckCardTypography.maxBase,
      );
      expect(
        prefs.getDouble('deck_typography_ruby_front_v1_d-persist'),
        DeckCardTypography.minRuby,
      );
      expect(
        prefs.getDouble('deck_typography_base_back_v1_d-persist'),
        DeckCardTypography.minBase,
      );
      expect(
        prefs.getDouble('deck_typography_ruby_back_v1_d-persist'),
        DeckCardTypography.maxRuby,
      );
    });

    testWidgets('hydrates when only front base is stored (other keys absent)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'deck_typography_base_front_v1_d-partial': 22.0,
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: _TypographySidesLabel(deckId: 'd-partial')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('22.0|9.9|18.0|9.9'), findsOneWidget);
    });

    testWidgets('setBaseFontSize updates only the requested side', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Column(
                    children: [
                      _TypographySidesLabel(deckId: 'd-isolate'),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(
                                deckSidesTypographyProvider(
                                  'd-isolate',
                                ).notifier,
                              )
                              .setBaseFontSize(true, 24);
                        },
                        child: const Text('front24'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(
                                deckSidesTypographyProvider(
                                  'd-isolate',
                                ).notifier,
                              )
                              .setBaseFontSize(false, 30);
                        },
                        child: const Text('back30'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('front24'));
      await tester.pump();
      expect(find.text('24.0|9.9|18.0|9.9'), findsOneWidget);

      await tester.tap(find.text('back30'));
      await tester.pump();
      expect(find.text('24.0|9.9|30.0|9.9'), findsOneWidget);
    });
  });

  group('CardText with typographyDeckId', () {
    testWidgets('uses front sizes by default after legacy hydrate', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'deck_typography_base_v1_d-card': 24.0,
        'deck_typography_ruby_v1_d-card': 14.0,
      });

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: Center(
              child: CardText(
                text: '[[皆|みな]]',
                color: Colors.black,
                scrollable: false,
                typographyDeckId: 'd-card',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final kanji = tester.widget<Text>(find.text('皆'));
      final yomi = tester.widget<Text>(find.text('みな'));
      expect(kanji.style!.fontSize, closeTo(24.0, 0.01));
      expect(yomi.style!.fontSize, closeTo(14.0, 0.01));
    });

    testWidgets('uses back sizes when typographyIsFront is false', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'deck_typography_base_front_v1_d-back': 18.0,
        'deck_typography_ruby_front_v1_d-back': 9.9,
        'deck_typography_base_back_v1_d-back': 28.0,
        'deck_typography_ruby_back_v1_d-back': 16.0,
      });

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: Center(
              child: CardText(
                text: '[[皆|みな]]',
                color: Colors.black,
                scrollable: false,
                typographyDeckId: 'd-back',
                typographyIsFront: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final kanji = tester.widget<Text>(find.text('皆'));
      final yomi = tester.widget<Text>(find.text('みな'));
      expect(kanji.style!.fontSize, closeTo(28.0, 0.01));
      expect(yomi.style!.fontSize, closeTo(16.0, 0.01));
    });

    testWidgets('plain text uses deck base size when markup absent', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'deck_typography_base_front_v1_d-plain': 20.0,
        'deck_typography_ruby_front_v1_d-plain': 10.0,
      });

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: Center(
              child: CardText(
                text: 'No ruby',
                color: Colors.black,
                scrollable: false,
                typographyDeckId: 'd-plain',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final plain = tester.widget<Text>(find.text('No ruby'));
      expect(plain.style!.fontSize, closeTo(20.0, 0.01));
    });
  });

  group('CardTranscriptText typography', () {
    const transcriptUrl = 'https://example.com/tr-typo.json';
    const audioUrl = 'https://example.com/a-typo.mp3';

    testWidgets(
      'annotated transcript uses back typography when typographyIsFront is false',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'deck_typography_base_front_v1_d-tr': 18.0,
          'deck_typography_ruby_front_v1_d-tr': 9.9,
          'deck_typography_base_back_v1_d-tr': 26.0,
          'deck_typography_ruby_back_v1_d-tr': 14.0,
        });

        final rubySync = TranscriptSync(
          words: const [
            TranscriptWord(word: '皆さん', start: 0, end: 0.3),
            TranscriptWord(word: 'は', start: 0.3, end: 0.5),
          ],
          annotatedSourceText: '[[皆|みな]]さんは',
        );

        await tester.pumpWidget(
          buildTestableWidgetWithOverrides(
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                child: CardTranscriptText(
                  transcriptUrl: transcriptUrl,
                  fallbackText: 'FB',
                  color: Colors.black,
                  typographyDeckId: 'd-tr',
                  typographyIsFront: false,
                ),
              ),
            ),
            overrides: transcriptAudioTestOverrides(
              transcriptUrl: transcriptUrl,
              audioUrl: audioUrl,
              transcriptAsync: AsyncData<TranscriptSync?>(rubySync),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final kanji = tester.widget<Text>(find.text('皆'));
        final yomi = tester.widget<Text>(find.text('みな'));
        expect(kanji.style!.fontSize, closeTo(26.0, 0.01));
        expect(yomi.style!.fontSize, closeTo(14.0, 0.01));
      },
    );
  });

  group('DeckFontSheet', () {
    testWidgets('shows Japanese preview and front/back switcher', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: SingleChildScrollView(
              child: DeckFontSheet(deckId: 'd-sheet'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('例'), findsOneWidget);
      expect(find.text('れい'), findsOneWidget);
      expect(find.text('漢字'), findsOneWidget);
      expect(find.text('かんじ'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
      expect(find.byType(SegmentedButton<bool>), findsOneWidget);
    });

    testWidgets('dragging main slider persists front base size', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: SingleChildScrollView(
              child: DeckFontSheet(deckId: 'd-slider'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      expect(tester.widget<Slider>(sliders.first).value, 18.0);

      await tester.drag(sliders.first, const Offset(240, 0));
      await tester.pumpAndSettle();

      expect(tester.widget<Slider>(sliders.first).value, greaterThan(18.0));

      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble('deck_typography_base_front_v1_d-slider');
      expect(stored, isNotNull);
      expect(stored, greaterThan(18.0));
    });

    testWidgets('Back tab slider persists back base without changing front', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: SingleChildScrollView(
              child: DeckFontSheet(deckId: 'd-backtab'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      await tester.drag(sliders.first, const Offset(260, 0));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('deck_typography_base_front_v1_d-backtab'), 18.0);
      final backBase = prefs.getDouble(
        'deck_typography_base_back_v1_d-backtab',
      );
      expect(backBase, isNotNull);
      expect(backBase, greaterThan(18.0));
    });
  });
}
