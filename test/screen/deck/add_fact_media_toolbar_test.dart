import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/toolbars.dart';

void main() {
  group('AddFactMediaToolbar', () {
    Future<void> pumpToolbar(
      WidgetTester tester, {
      required Widget Function(BuildContext context) body,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('zh')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Builder(builder: body),
        ),
      );
    }

    AddFactMediaToolbar toolbar(
      BuildContext context, {
      required RecorderController voiceRecorder,
      bool hasMediaOnTargetRow = false,
      VoidCallback? onPickFiles,
      VoidCallback? onPickGallery,
      VoidCallback? onClearTargetAttachment,
      bool mediaPicksLocked = false,
      bool showVoiceRecord = false,
      bool isRecordingVoice = false,
      VoidCallback? onVoiceRecordTap,
      VoidCallback? onVoiceRecordLongPress,
    }) {
      return AddFactMediaToolbar(
        loc: AppLocalizations.of(context)!,
        theme: Theme.of(context),
        hasMediaOnTargetRow: hasMediaOnTargetRow,
        onPickFiles: onPickFiles ?? () {},
        onPickGallery: onPickGallery ?? () {},
        onClearTargetAttachment: onClearTargetAttachment ?? () {},
        voiceRecorder: voiceRecorder,
        mediaPicksLocked: mediaPicksLocked,
        showVoiceRecord: showVoiceRecord,
        isRecordingVoice: isRecordingVoice,
        onVoiceRecordTap: onVoiceRecordTap,
        onVoiceRecordLongPress: onVoiceRecordLongPress,
      );
    }

    testWidgets('shows two icon buttons when voice record is off', (
      tester,
    ) async {
      final rc = RecorderController();
      addTearDown(rc.dispose);

      await pumpToolbar(
        tester,
        body: (context) {
          return Scaffold(
            body: toolbar(context, voiceRecorder: rc, showVoiceRecord: false),
          );
        },
      );

      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('hides mic when showVoiceRecord but no onVoiceRecordTap', (
      tester,
    ) async {
      final rc = RecorderController();
      addTearDown(rc.dispose);

      await pumpToolbar(
        tester,
        body: (context) {
          return Scaffold(
            body: toolbar(
              context,
              voiceRecorder: rc,
              showVoiceRecord: true,
              onVoiceRecordTap: null,
            ),
          );
        },
      );

      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('shows mic when showVoiceRecord and onVoiceRecordTap set', (
      tester,
    ) async {
      final rc = RecorderController();
      addTearDown(rc.dispose);

      await pumpToolbar(
        tester,
        body: (context) {
          return Scaffold(
            body: toolbar(
              context,
              voiceRecorder: rc,
              showVoiceRecord: true,
              onVoiceRecordTap: () {},
            ),
          );
        },
      );

      expect(find.byType(IconButton), findsNWidgets(3));
    });

    testWidgets('does not invoke file or gallery when mediaPicksLocked', (
      tester,
    ) async {
      final rc = RecorderController();
      addTearDown(rc.dispose);
      var files = 0;
      var gallery = 0;
      var voice = 0;

      await pumpToolbar(
        tester,
        body: (context) {
          return Scaffold(
            body: toolbar(
              context,
              voiceRecorder: rc,
              mediaPicksLocked: true,
              showVoiceRecord: true,
              onPickFiles: () => files++,
              onPickGallery: () => gallery++,
              onVoiceRecordTap: () => voice++,
            ),
          );
        },
      );

      await tester.tap(find.byType(IconButton).at(0));
      await tester.tap(find.byType(IconButton).at(1));
      await tester.pump();
      expect(files, 0);
      expect(gallery, 0);

      await tester.tap(find.byType(IconButton).at(2));
      await tester.pump();
      expect(voice, 1);
    });

    testWidgets('invokes file and gallery when not locked', (tester) async {
      final rc = RecorderController();
      addTearDown(rc.dispose);
      var files = 0;
      var gallery = 0;

      await pumpToolbar(
        tester,
        body: (context) {
          return Scaffold(
            body: toolbar(
              context,
              voiceRecorder: rc,
              mediaPicksLocked: false,
              showVoiceRecord: false,
              onPickFiles: () => files++,
              onPickGallery: () => gallery++,
            ),
          );
        },
      );

      await tester.tap(find.byType(IconButton).at(0));
      await tester.tap(find.byType(IconButton).at(1));
      await tester.pump();
      expect(files, 1);
      expect(gallery, 1);
    });
  });
}
