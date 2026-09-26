import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _focusNodes = <FocusNode>[FocusNode(), FocusNode(), FocusNode()];
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
    for (final node in _focusNodes) {
      node.dispose();
    }
    _recorder.dispose();
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
            child: Focus(focusNode: _focusNodes[i], child: const SizedBox()),
          ),
      ],
    );
  }
}

void main() {
  testWidgets('pinMediaTargetRow sticks when no row has focus', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _PinHarness())),
    );
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

  testWidgets('refreshMediaTargetFromFocus persists the focused row', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _PinHarness())),
    );
    final state = tester.state<_PinHarnessState>(find.byType(_PinHarness));

    // Focus row 1 and sync sticky from focus.
    state._focusNodes[1].requestFocus();
    await tester.pump();
    expect(state.targetRowIndexForMedia(), 1);
    state.refreshMediaTargetFromFocus();

    // With focus cleared, the sticky target remembers row 1.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(state.targetRowIndexForMedia(), 1);
  });

  testWidgets(
    'refreshMediaTargetFromFocus is a no-op when nothing is focused',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: _PinHarness())),
      );
      final state = tester.state<_PinHarnessState>(find.byType(_PinHarness));

      state.pinMediaTargetRow(2);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      state.refreshMediaTargetFromFocus();
      expect(state.targetRowIndexForMedia(), 2);
    },
  );

  testWidgets('pinMediaTargetRow wins over an already-focused row', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _PinHarness())),
    );
    final state = tester.state<_PinHarnessState>(find.byType(_PinHarness));

    state._focusNodes[0].requestFocus();
    await tester.pump();
    state.refreshMediaTargetFromFocus();
    expect(state.targetRowIndexForMedia(), 0);

    // Clearing audio on another row must move the media target immediately,
    // even while the caret is still on row 0.
    state.pinMediaTargetRow(2);
    expect(state.targetRowIndexForMedia(), 2);
  });

  testWidgets(
    'refreshMediaTargetFromFocus drops pin when focus moves elsewhere',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: _PinHarness())),
      );
      final state = tester.state<_PinHarnessState>(find.byType(_PinHarness));

      state._focusNodes[0].requestFocus();
      await tester.pump();
      state.refreshMediaTargetFromFocus();

      state.pinMediaTargetRow(2);
      expect(state.targetRowIndexForMedia(), 2);

      // User taps another field — follow focus and clear the pin.
      state._focusNodes[1].requestFocus();
      await tester.pump();
      state.refreshMediaTargetFromFocus();
      expect(state.targetRowIndexForMedia(), 1);
    },
  );

  testWidgets(
    'refreshMediaTargetFromFocus keeps pin when focus is on the pinned row',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: _PinHarness())),
      );
      final state = tester.state<_PinHarnessState>(find.byType(_PinHarness));

      state.pinMediaTargetRow(2);
      state._focusNodes[2].requestFocus();
      await tester.pump();
      state.refreshMediaTargetFromFocus();
      expect(state.targetRowIndexForMedia(), 2);

      // Pin still holds if focus leaves the hosts entirely.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(state.targetRowIndexForMedia(), 2);
    },
  );

  testWidgets('targetRowIndexForMedia read does not persist the focused row', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _PinHarness())),
    );
    final state = tester.state<_PinHarnessState>(find.byType(_PinHarness));

    // Establish sticky row 0 via focus sync (not pin — pin forces the target).
    state._focusNodes[0].requestFocus();
    await tester.pump();
    state.refreshMediaTargetFromFocus();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(state.targetRowIndexForMedia(), 0);

    // Focus row 2 and only READ — the read must not mutate sticky.
    state._focusNodes[2].requestFocus();
    await tester.pump();
    expect(state.targetRowIndexForMedia(), 2);

    // Clearing focus falls back to the still-unchanged sticky (0), proving the
    // read had no write side-effect.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(state.targetRowIndexForMedia(), 0);
  });

  testWidgets('pinMediaTargetRow with no host keys resets to 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _EmptyPinHarness())),
    );
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
