import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/media_handling_coordinator.dart';
import 'package:retentio/services/apis/media_service.dart';

import '../../helpers/path_provider_mock.dart';

class _FakeRecorder extends Fake implements AudioRecorder {
  _FakeRecorder(this.outputPath, {this.onPermission});

  final String outputPath;
  final VoidCallback? onPermission;

  @override
  Future<bool> hasPermission({bool request = true}) async {
    onPermission?.call();
    return true;
  }

  @override
  Future<void> start(RecordConfig config, {required String path}) async {}

  @override
  Future<String?> stop() async => outputPath;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

class _RecordingHarness extends StatefulWidget {
  const _RecordingHarness({required this.recorder});

  final AudioRecorder recorder;

  @override
  State<_RecordingHarness> createState() => _RecordingHarnessState();
}

class _RecordingHarnessState extends State<_RecordingHarness>
    with MediaHandlingCoordinator<_RecordingHarness> {
  final _keys = <GlobalKey>[GlobalKey(), GlobalKey(), GlobalKey()];
  final focusNodes = <FocusNode>[FocusNode(), FocusNode(), FocusNode()];
  final attachedRows = <int>[];
  var _recording = false;

  @override
  AudioRecorder get voiceRecorder => widget.recorder;

  @override
  bool get isRecordingVoice => _recording;

  @override
  set isRecordingVoice(bool value) => _recording = value;

  @override
  List<GlobalKey> get mediaTargetHostKeys => _keys;

  @override
  void showComposerSnack(String message) {}

  @override
  void attachPathOnTargetRow(MediaSlotKind kind, String path) {
    attachedRows.add(targetRowIndexForMedia());
  }

  @override
  bool get targetRowHasAttachment => false;

  @override
  void clearTargetRowAttachment() {}

  /// Mirrors the hosts' focus listener.
  void focusRow(int index) {
    focusNodes[index].requestFocus();
  }

  @override
  void dispose() {
    for (final node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _keys.length; i++)
          SizedBox(
            key: _keys[i],
            height: 1,
            child: Focus(focusNode: focusNodes[i], child: const SizedBox()),
          ),
      ],
    );
  }
}

Future<_RecordingHarnessState> _pump(
  WidgetTester tester,
  AudioRecorder recorder,
) async {
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
        home: _RecordingHarness(recorder: recorder),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_RecordingHarnessState>(find.byType(_RecordingHarness));
}

Future<void> _focusAndSync(
  WidgetTester tester,
  _RecordingHarnessState state,
  int row,
) async {
  state.focusRow(row);
  await tester.pump();
  state.refreshMediaTargetFromFocus();
}

void main() {
  late Directory tempDir;
  late String clipPath;

  setUp(() {
    PathProviderMock.setup();
    tempDir = Directory.systemTemp.createTempSync('coordinator_recording');
    clipPath = '${tempDir.path}/clip.m4a';
    File(clipPath).writeAsBytesSync(List<int>.filled(16, 1));
  });

  tearDown(() {
    PathProviderMock.teardown();
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('recording target stays locked when focus moves mid-record', (
    tester,
  ) async {
    final state = await _pump(tester, _FakeRecorder(clipPath));

    await _focusAndSync(tester, state, 1);
    await tester.runAsync(state.toggleVoiceRecording);
    expect(state.isRecordingVoice, isTrue);

    // User taps another field while recording.
    await _focusAndSync(tester, state, 2);
    expect(state.targetRowIndexForMedia(), 1);

    await tester.runAsync(state.toggleVoiceRecording);
    expect(state.isRecordingVoice, isFalse);
    expect(state.attachedRows, [1]);

    // Lock released: the target follows focus again.
    expect(state.targetRowIndexForMedia(), 2);
  });

  testWidgets('recording target is captured before the permission await', (
    tester,
  ) async {
    late _RecordingHarnessState state;
    final recorder = _FakeRecorder(
      clipPath,
      // Focus moves while the permission prompt is up.
      onPermission: () => state.focusRow(2),
    );
    state = await _pump(tester, recorder);

    await _focusAndSync(tester, state, 1);
    await tester.runAsync(state.toggleVoiceRecording);
    await tester.pump();

    expect(state.isRecordingVoice, isTrue);
    expect(state.targetRowIndexForMedia(), 1);
  });

  testWidgets('cancelling a recording releases the locked target', (
    tester,
  ) async {
    final state = await _pump(tester, _FakeRecorder(clipPath));

    await _focusAndSync(tester, state, 0);
    await tester.runAsync(state.toggleVoiceRecording);
    await _focusAndSync(tester, state, 2);
    expect(state.targetRowIndexForMedia(), 0);

    await tester.runAsync(state.cancelVoiceRecording);
    expect(state.isRecordingVoice, isFalse);
    expect(state.attachedRows, isEmpty);
    expect(state.targetRowIndexForMedia(), 2);
  });
}
