import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/fact_add_composer/media_handling_coordinator.dart';
import 'package:retentio/screen/deck/fact_add_composer/pick_extensions.dart';
import 'package:retentio/services/apis/media_service.dart';

base class _PickedFile extends PlatformFile {
  _PickedFile(this.uri, {required this.name});

  @override
  final String name;

  @override
  final Uri uri;

  @override
  XFile get xFile => XFile(path ?? name);

  @override
  int? lengthSync() => null;

  @override
  Future<int?> length() async => 0;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() => const Stream.empty();
}

class _FakeFilePicker extends FilePickerPlatform {
  _FakeFilePicker(this.result);

  final PlatformFile? result;
  FileType? seenType;
  List<String>? seenExtensions;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    seenType = type;
    seenExtensions = allowedExtensions;
    return result;
  }
}

class _PickHarness extends StatefulWidget {
  const _PickHarness();

  @override
  State<_PickHarness> createState() => _PickHarnessState();
}

class _SilentRecorder extends Fake implements AudioRecorder {
  @override
  Future<void> dispose() async {}
}

class _PickHarnessState extends State<_PickHarness>
    with MediaHandlingCoordinator<_PickHarness> {
  final _keys = <GlobalKey>[GlobalKey()];
  final _recorder = _SilentRecorder();
  final snacks = <String>[];
  final attached = <(MediaSlotKind, String)>[];

  @override
  AudioRecorder get voiceRecorder => _recorder;

  @override
  bool get isRecordingVoice => false;

  @override
  set isRecordingVoice(bool value) {}

  @override
  List<GlobalKey> get mediaTargetHostKeys => _keys;

  @override
  void showComposerSnack(String message) => snacks.add(message);

  @override
  void attachPathOnTargetRow(MediaSlotKind kind, String path) {
    attached.add((kind, path));
  }

  @override
  bool get targetRowHasAttachment => false;

  @override
  void clearTargetRowAttachment() {}

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: _keys.single, height: 1);
  }
}

void main() {
  late FilePickerPlatform originalPicker;

  setUp(() {
    originalPicker = FilePickerPlatform.instance;
  });

  tearDown(() {
    FilePickerPlatform.instance = originalPicker;
  });

  Future<_PickHarnessState> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: _PickHarness(),
        ),
      ),
    );
    await tester.pump();
    return tester.state<_PickHarnessState>(find.byType(_PickHarness));
  }

  testWidgets('pickMediaForTargetRow ignores a canceled picker', (
    tester,
  ) async {
    final picker = _FakeFilePicker(null);
    FilePickerPlatform.instance = picker;
    final state = await pump(tester);

    await state.pickMediaForTargetRow();

    expect(picker.seenType, FileType.custom);
    expect(picker.seenExtensions, AddFactPickExtensions.all);
    expect(state.snacks, isEmpty);
    expect(state.attached, isEmpty);
  });

  testWidgets('pickMediaForTargetRow snacks when the picked file has no path', (
    tester,
  ) async {
    FilePickerPlatform.instance = _FakeFilePicker(
      _PickedFile(Uri.parse('content://picker/1'), name: 'photo.jpg'),
    );
    final state = await pump(tester);

    await state.pickMediaForTargetRow();

    expect(state.snacks, ['Upload failed. Try again.']);
    expect(state.attached, isEmpty);
  });

  testWidgets('pickMediaForTargetRow attaches a picked local file', (
    tester,
  ) async {
    final file = File(
      '${Directory.systemTemp.path}/coordinator_pick_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    file.writeAsBytesSync([1, 2, 3]);
    addTearDown(() async {
      if (file.existsSync()) file.deleteSync();
    });
    FilePickerPlatform.instance = _FakeFilePicker(
      _PickedFile(file.uri, name: 'photo.png'),
    );
    final state = await pump(tester);

    await tester.runAsync(() => state.pickMediaForTargetRow());

    expect(state.snacks, isEmpty);
    expect(state.attached, [(MediaSlotKind.image, file.path)]);
  });
}
