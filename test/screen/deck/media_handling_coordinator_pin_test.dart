import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:retentio/screen/deck/fact_add_composer/media_handling_coordinator.dart';
import 'package:retentio/services/apis/media_service.dart';

class _PinHarness extends StatefulWidget {
  const _PinHarness();

  @override
  State<_PinHarness> createState() => _PinHarnessState();
}

class _PinHarnessState extends State<_PinHarness>
    with MediaHandlingCoordinator<_PinHarness> {
  final _keys = <GlobalKey>[GlobalKey(), GlobalKey(), GlobalKey()];
  final _recorder = AudioRecorder();
  var _recording = false;

  @override
  AudioRecorder get voiceRecorder => _recorder;

  @override
  bool get isRecordingVoice => _recording;

  @override
  set isRecordingVoice(bool value) => _recording = value;

  @override
  List<GlobalKey> get mediaTargetHostKeys => _keys;

  @override
  void showComposerSnack(String message) {}

  @override
  void attachPathOnTargetRow(MediaSlotKind kind, String path) {}

  @override
  bool get targetRowHasAttachment => false;

  @override
  void clearTargetRowAttachment() {}

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [for (final key in _keys) SizedBox(key: key, height: 1)],
    );
  }
}

void main() {
  testWidgets('pinMediaTargetRow sticks when no row has focus', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _PinHarness()));
    final state = tester.state<_PinHarnessState>(find.byType(_PinHarness));

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    state.pinMediaTargetRow(2);
    expect(state.targetRowIndexForMedia(), 2);

    state.pinMediaTargetRow(99);
    expect(state.targetRowIndexForMedia(), 2);

    state.pinMediaTargetRow(-1);
    expect(state.targetRowIndexForMedia(), 0);
  });

  testWidgets('pinMediaTargetRow with no host keys resets to 0', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _EmptyPinHarness()));
    final state = tester.state<_EmptyPinHarnessState>(
      find.byType(_EmptyPinHarness),
    );

    state.pinMediaTargetRow(3);
    expect(state.targetRowIndexForMedia(), 0);
  });
}

class _EmptyPinHarness extends StatefulWidget {
  const _EmptyPinHarness();

  @override
  State<_EmptyPinHarness> createState() => _EmptyPinHarnessState();
}

class _EmptyPinHarnessState extends State<_EmptyPinHarness>
    with MediaHandlingCoordinator<_EmptyPinHarness> {
  final _recorder = AudioRecorder();
  var _recording = false;

  @override
  AudioRecorder get voiceRecorder => _recorder;

  @override
  bool get isRecordingVoice => _recording;

  @override
  set isRecordingVoice(bool value) => _recording = value;

  @override
  List<GlobalKey> get mediaTargetHostKeys => const [];

  @override
  void showComposerSnack(String message) {}

  @override
  void attachPathOnTargetRow(MediaSlotKind kind, String path) {}

  @override
  bool get targetRowHasAttachment => false;

  @override
  void clearTargetRowAttachment() {}

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
