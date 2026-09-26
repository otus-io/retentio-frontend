import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/card_widgets/card_audio.dart';
import 'package:retentio/screen/deck/fact_add_composer/entry_row.dart';
import 'package:retentio/screen/deck/fact_add_composer/row_model.dart';
import 'package:retentio/services/apis/media_service.dart';

Widget _harness(
  AddFactRowModel row, {
  ValueChanged<MediaSlotKind>? onClearSlot,
}) {
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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AddFactEntryRow(
            row: row,
            loc: lookupAppLocalizations(const Locale('en')),
            theme: theme,
            outlineColor: Colors.grey,
            onClearSlot: onClearSlot ?? (_) {},
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
