import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/transcript_sync.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/card_widgets/card_audio.dart';
import 'package:retentio/screen/deck/card_widgets/card_transcript_text.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_content.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/screen/deck/providers/audio_player.dart';

import '../../helpers/test_wrapper.dart';
import '../../helpers/transcript_test_overrides.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });
  tearDownAll(tearDownTestEnvironment);

  const transcriptUrl = 'https://example.com/tr.json';
  const audioUrl = 'https://example.com/a.mp3';

  final sampleSync = TranscriptSync(
    words: const [
      TranscriptWord(word: '一', start: 0, end: 0.4),
      TranscriptWord(word: '二', start: 1, end: 1.4),
    ],
  );

  testWidgets('shows fallback when transcript async data is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidgetWithOverrides(
        SizedBox(
          height: 400,
          child: SingleChildScrollView(
            child: CardTranscriptText(
              transcriptUrl: transcriptUrl,
              fallbackText: 'FB_ONLY',
              color: Colors.black,
            ),
          ),
        ),
        overrides: transcriptAudioTestOverrides(
          transcriptUrl: transcriptUrl,
          audioUrl: audioUrl,
          transcriptAsync: const AsyncData<TranscriptSync?>(null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FB_ONLY'), findsOneWidget);
  });

  testWidgets('renders transcript words in a Wrap', (tester) async {
    await tester.pumpWidget(
      buildTestableWidgetWithOverrides(
        SizedBox(
          height: 400,
          child: SingleChildScrollView(
            child: CardTranscriptText(
              transcriptUrl: transcriptUrl,
              fallbackText: 'FB',
              color: Colors.black,
            ),
          ),
        ),
        overrides: transcriptAudioTestOverrides(
          transcriptUrl: transcriptUrl,
          audioUrl: audioUrl,
          transcriptAsync: AsyncData<TranscriptSync?>(sampleSync),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('一'), findsOneWidget);
    expect(find.text('二'), findsOneWidget);
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('annotated transcript shows ruby when text aligns with words', (
    tester,
  ) async {
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
    await tester.pumpAndSettle();
    expect(find.text('みな'), findsOneWidget);
    expect(find.text('皆'), findsOneWidget);
    expect(find.text('さん'), findsOneWidget);
    expect(find.text('は'), findsOneWidget);
  });

  testWidgets('tap word seeks to its start in ms', (tester) async {
    final container = ProviderContainer(
      overrides: transcriptAudioTestOverrides(
        transcriptUrl: transcriptUrl,
        audioUrl: audioUrl,
        transcriptAsync: AsyncData<TranscriptSync?>(sampleSync),
        positionMs: 0,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('zh')],
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SingleChildScrollView(
                child: CardTranscriptText(
                  transcriptUrl: transcriptUrl,
                  fallbackText: 'FB',
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('二'));
    await tester.pump();

    expect(container.read(audioPlayerProvider).positionMs, 1000);
  });

  group('FactContent + transcript', () {
    testWidgets('combined field shows synced words for single audio+json', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: SizedBox(
              height: 520,
              child: FactContent(
                color: Colors.blue,
                items: [
                  Item(type: 'text', value: 'note'),
                  Item(type: 'audio', value: audioUrl),
                  Item(type: 'json', value: transcriptUrl),
                ],
              ),
            ),
          ),
          overrides: transcriptAudioTestOverrides(
            transcriptUrl: transcriptUrl,
            audioUrl: audioUrl,
            transcriptAsync: AsyncData<TranscriptSync?>(sampleSync),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('一'), findsOneWidget);
      expect(find.text('二'), findsOneWidget);
    });
  });

  group('CardAudio compact word navigation', () {
    testWidgets('forward icon seeks to next word start from transcript', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          audioUrlProvider.overrideWithValue(audioUrl),
          audioPlayerProvider.overrideWithBuild((ref, _) {
            ref.watch(audioUrlProvider);
            return AudioPlayerState(
              audioUrl: ref.watch(audioUrlProvider),
              isReady: true,
              positionMs: 0,
              maxDurationMs: 120_000,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Center(
              child: CardAudio(
                audioUrl: audioUrl,
                compact: true,
                useExternalScope: true,
                transcriptForWordNav: sampleSync,
                transcriptJsonUrl: 'https://example.com/sync.json',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.rotateCw));
      await tester.pump();

      expect(container.read(audioPlayerProvider).positionMs, 1000);
    });

    testWidgets('back icon seeks to previous word using transcript', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          audioUrlProvider.overrideWithValue(audioUrl),
          audioPlayerProvider.overrideWithBuild((ref, _) {
            ref.watch(audioUrlProvider);
            return AudioPlayerState(
              audioUrl: ref.watch(audioUrlProvider),
              isReady: true,
              positionMs: 1000,
              maxDurationMs: 120_000,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Center(
              child: CardAudio(
                audioUrl: audioUrl,
                compact: true,
                useExternalScope: true,
                transcriptForWordNav: sampleSync,
                transcriptJsonUrl: 'https://example.com/sync.json',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.rotateCcw));
      await tester.pump();

      expect(container.read(audioPlayerProvider).positionMs, 0);
    });
  });
}
