import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/services/apis/media_service.dart';

void main() {
  group('MediaService.classifyFile', () {
    test('recognizes voice-related extensions', () {
      expect(MediaService.classifyFile('/tmp/x.m4a'), MediaSlotKind.audio);
      expect(
        MediaService.classifyFile(r'C:\rec\clip.AAC'),
        MediaSlotKind.audio,
      );
      expect(MediaService.classifyFile('/a/b/note.mp3'), MediaSlotKind.audio);
      expect(MediaService.classifyFile('/a/b/x.wav'), MediaSlotKind.audio);
    });

    test('recognizes image, video, and json', () {
      expect(MediaService.classifyFile('/i/photo.JPG'), MediaSlotKind.image);
      expect(MediaService.classifyFile('/v/m.mp4'), MediaSlotKind.video);
      expect(MediaService.classifyFile('/t/sync.JSON'), MediaSlotKind.json);
    });

    test('returns null for unknown extension', () {
      expect(MediaService.classifyFile('/a/bin.dat'), isNull);
      expect(MediaService.classifyFile('/noext'), isNull);
    });
  });

  group('MediaService.maxBytesFor', () {
    test('image cap is 5 MB', () {
      expect(MediaService.maxBytesFor(MediaSlotKind.image), 5 * 1024 * 1024);
    });

    test('audio and video cap is 200 MB', () {
      final n = 200 * 1024 * 1024;
      expect(MediaService.maxBytesFor(MediaSlotKind.audio), n);
      expect(MediaService.maxBytesFor(MediaSlotKind.video), n);
    });

    test('json cap is 2 MB', () {
      expect(MediaService.maxBytesFor(MediaSlotKind.json), 2 * 1024 * 1024);
    });
  });

  group('MediaService.precheckSlot', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('retentio_media_test_');
    });

    tearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    test('ok for small audio file on audio slot', () async {
      final f = File('${dir.path}/v.m4a');
      await f.writeAsBytes([0, 1, 2, 3]);
      expect(
        await MediaService.precheckSlot(MediaSlotKind.audio, f.path),
        MediaPrecheck.ok,
      );
    });

    test('fileNotFound when path missing', () async {
      expect(
        await MediaService.precheckSlot(
          MediaSlotKind.audio,
          '${dir.path}/nope.m4a',
        ),
        MediaPrecheck.fileNotFound,
      );
    });

    test('wrongType when slot does not match extension', () async {
      final f = File('${dir.path}/x.m4a');
      await f.writeAsBytes([0]);
      expect(
        await MediaService.precheckSlot(MediaSlotKind.image, f.path),
        MediaPrecheck.wrongType,
      );
    });

    test('fileTooLarge for image over 5 MB', () async {
      final f = File('${dir.path}/huge.jpg');
      final raf = await f.open(mode: FileMode.write);
      await raf.setPosition(MediaService.maxImageBytes);
      await raf.writeByte(1);
      await raf.close();
      expect(await f.length(), MediaService.maxImageBytes + 1);
      expect(
        await MediaService.precheckSlot(MediaSlotKind.image, f.path),
        MediaPrecheck.fileTooLarge,
      );
    });

    test('fileTooLarge for json over 2 MB', () async {
      final f = File('${dir.path}/huge.json');
      final raf = await f.open(mode: FileMode.write);
      await raf.setPosition(MediaService.maxJsonBytes);
      await raf.writeByte(1);
      await raf.close();
      expect(await f.length(), MediaService.maxJsonBytes + 1);
      expect(
        await MediaService.precheckSlot(MediaSlotKind.json, f.path),
        MediaPrecheck.fileTooLarge,
      );
    });
  });
}
