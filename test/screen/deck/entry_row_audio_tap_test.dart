import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/card_widgets/card_audio.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/screen/deck/providers/audio_player.dart';
import 'package:retentio/services/apis/media_service.dart';

Widget _harness(
  AddFactRowModel row, {
  ValueChanged<MediaSlotKind>? onClearSlot,
  List<Override> overrides = const [],
  Map<String, int> mediaVersions = const {},
}) {
  final theme = ThemeData.light();
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AddFactEntryRow(
            row: row,
            loc: lookupAppLocalizations(const Locale('en')),
            theme: theme,
            outlineColor: Colors.grey,
            onClearSlot: onClearSlot ?? (_) {},
            mediaVersions: mediaVersions,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'text field with audio attachment accepts a single tap for focus',
    (tester) async {
      final row = AddFactRowModel(initialFieldName: 'JP');
      addTearDown(row.dispose);
      row.content.text = 'headword';
      row.audioPath = 'aud001';

      await tester.pumpWidget(_harness(row));
      await tester.pumpAndSettle();

      final editable = find.byType(EditableText);
      expect(editable, findsOneWidget);

      // Tap the body text — must not be stolen by the audio chip hit target.
      await tester.tap(editable);
      await tester.pump();

      final focused = tester.widget<EditableText>(editable);
      expect(focused.focusNode.hasFocus, isTrue);
    },
  );

  testWidgets('audio attachment shows a compact player above the text field', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'headword';
    row.audioPath = 'aud001';

    await tester.pumpWidget(_harness(row));
    await tester.pumpAndSettle();

    final audio = tester.widget<CardAudio>(find.byType(CardAudio));
    expect(audio.compact, isTrue);

    final audioTop = tester.getTopLeft(find.byType(CardAudio)).dy;
    final textTop = tester.getTopLeft(find.byType(EditableText)).dy;
    expect(audioTop, lessThan(textTop));
  });

  testWidgets('pinned audio id plays the snapshot version', (tester) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'headword';
    row.audioPath = 'aud001';

    await tester.pumpWidget(_harness(row, mediaVersions: const {'aud001': 1}));
    await tester.pumpAndSettle();

    final audio = tester.widget<CardAudio>(find.byType(CardAudio));
    expect(audio.audioUrl, '/api/media/aud001?v=1');
    expect(row.audioPath, 'aud001');
  });

  testWidgets('tapping a ready play button plays without focusing text', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'headword';
    row.audioPath = 'aud001';
    final fake = _ReadyAudioPlayer();

    await tester.pumpWidget(
      _harness(row, overrides: [audioPlayerProvider.overrideWith(() => fake)]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.volume2));
    await tester.pumpAndSettle();

    expect(fake.playPauseCalls, 1);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isFalse);
  });

  testWidgets('tapping clear removes audio without focusing text', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'headword';
    row.audioPath = 'aud001';
    final cleared = <MediaSlotKind>[];

    await tester.pumpWidget(_harness(row, onClearSlot: cleared.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(cleared, [MediaSlotKind.audio]);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isFalse);
  });

  testWidgets('tapping empty space beside audio focuses the text end', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'headword';
    row.audioPath = 'aud001';

    await tester.pumpWidget(_harness(row));
    await tester.pumpAndSettle();

    final audioRect = tester.getRect(find.byType(CardAudio));
    // Empty strip to the right of play + clear, still inside the content box.
    await tester.tapAt(Offset(audioRect.right + 48, audioRect.center.dy));
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    expect(
      editable.controller.selection,
      const TextSelection.collapsed(offset: 8),
    );
  });

  testWidgets('requestContentFocus moves caret to the end of the text', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'headword';
    row.audioPath = 'aud001';

    await tester.pumpWidget(_harness(row));
    await tester.pumpAndSettle();

    expect(row.requestContentFocus, isNotNull);
    row.requestContentFocus!();
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    expect(
      editable.controller.selection,
      const TextSelection.collapsed(offset: 8),
    );
  });

  testWidgets('unplayable audio path still shows an icon and clear button', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'headword';
    row.audioPath = '   ';
    final cleared = <MediaSlotKind>[];

    await tester.pumpWidget(_harness(row, onClearSlot: cleared.add));
    await tester.pumpAndSettle();

    expect(find.byType(CardAudio), findsNothing);
    expect(find.byIcon(LucideIcons.audioLines), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x));
    expect(cleared, [MediaSlotKind.audio]);
  });

  testWidgets('recording target shows hint and highlight on the chosen row', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'headword';

    final theme = ThemeData.light();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme,
          home: Scaffold(
            body: AddFactEntryRow(
              row: row,
              loc: lookupAppLocalizations(const Locale('en')),
              theme: theme,
              outlineColor: Colors.grey,
              isRecordingTarget: true,
              isMediaTarget: true,
              onClearSlot: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recording for this field…'), findsOneWidget);
    expect(find.byIcon(LucideIcons.mic), findsOneWidget);
  });

  testWidgets('media target highlight shows without recording hint', (
    tester,
  ) async {
    final row = AddFactRowModel(initialFieldName: 'JP');
    addTearDown(row.dispose);
    row.content.text = 'headword';

    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme,
          home: Scaffold(
            body: AddFactEntryRow(
              row: row,
              loc: lookupAppLocalizations(const Locale('en')),
              theme: theme,
              outlineColor: Colors.grey,
              isMediaTarget: true,
              onClearSlot: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recording for this field…'), findsNothing);
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(AddFactEntryRow),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null,
        ),
      ),
    );
    final decoration = box.decoration! as BoxDecoration;
    expect((decoration.border! as Border).top.color, theme.colorScheme.primary);
  });

  testWidgets(
    'becoming media target keeps the text field mounted (no reparent)',
    (tester) async {
      final row = AddFactRowModel(initialFieldName: 'JP');
      addTearDown(row.dispose);
      row.content.text = 'hello world';
      row.content.selection = const TextSelection.collapsed(offset: 11);

      await tester.pumpWidget(_MediaTargetToggleHarness(row: row));
      await tester.pumpAndSettle();

      final before = tester.state<EditableTextState>(find.byType(EditableText));

      final harness = tester.state<_MediaTargetToggleHarnessState>(
        find.byType(_MediaTargetToggleHarness),
      );
      harness.setMediaTarget(true);
      await tester.pump();

      final after = tester.state<EditableTextState>(find.byType(EditableText));
      // Same State instance ⇒ the editor was not remounted, so an in-flight
      // tap selection would survive the highlight toggle.
      expect(identical(before, after), isTrue);
      expect(row.content.selection.baseOffset, 11);
    },
  );
}

class _ReadyAudioPlayer extends AudioPlayerNotifier {
  var playPauseCalls = 0;

  @override
  AudioPlayerState build() => AudioPlayerState(isReady: true);

  @override
  Future<void> playPause() async => playPauseCalls++;
}

class _MediaTargetToggleHarness extends StatefulWidget {
  const _MediaTargetToggleHarness({required this.row});

  final AddFactRowModel row;

  @override
  State<_MediaTargetToggleHarness> createState() =>
      _MediaTargetToggleHarnessState();
}

class _MediaTargetToggleHarnessState extends State<_MediaTargetToggleHarness> {
  bool _mediaTarget = false;

  void setMediaTarget(bool value) => setState(() => _mediaTarget = value);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.light();
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme,
        home: Scaffold(
          body: AddFactEntryRow(
            row: widget.row,
            loc: lookupAppLocalizations(const Locale('en')),
            theme: theme,
            outlineColor: Colors.grey,
            isMediaTarget: _mediaTarget,
            onClearSlot: (_) {},
          ),
        ),
      ),
    );
  }
}
