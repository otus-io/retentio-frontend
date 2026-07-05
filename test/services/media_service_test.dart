import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/services/apis/media_service.dart';

class _FakeMediaUploadAdapter implements HttpClientAdapter {
  String? capturedDeckId;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isMediaUpload =
        options.method == 'POST' && options.path.endsWith('/api/media');
    if (!isMediaUpload) {
      return _jsonResponse({'code': -1, 'msg': 'not found', 'data': null}, 404);
    }

    final form = options.data;
    if (form is FormData) {
      for (final field in form.fields) {
        if (field.key == 'deck_id') {
          capturedDeckId = field.value;
        }
      }
    }

    return _jsonResponse({
      'code': 0,
      'msg': 'media uploaded',
      'data': {'id': 'media123'},
    }, 201);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

    test('recognizes image and video', () {
      expect(MediaService.classifyFile('/i/photo.JPG'), MediaSlotKind.image);
      expect(MediaService.classifyFile('/v/m.mp4'), MediaSlotKind.video);
    });

    test('json extension is not a supported attachment type', () {
      expect(MediaService.classifyFile('/t/sync.JSON'), isNull);
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
  });

  group('MediaService.upload', () {
    late Directory dir;
    late _FakeMediaUploadAdapter adapter;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('retentio_media_upload_test_');
      adapter = _FakeMediaUploadAdapter();
      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      networkDioClient.dio.httpClientAdapter = adapter;
    });

    tearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    test('includes deck_id in multipart form', () async {
      final f = File('${dir.path}/clip.m4a');
      await f.writeAsBytes([0, 1, 2]);

      final id = await MediaService.upload(
        deckId: 'deck-abc',
        filePath: f.path,
        slotKind: MediaSlotKind.audio,
      );

      expect(id, 'media123');
      expect(adapter.capturedDeckId, 'deck-abc');
    });
  });
}
