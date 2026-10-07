import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/fact_add_composer/media_play_url.dart';

void main() {
  group('attachmentAudioPlayUrl', () {
    test('returns null for empty input', () {
      expect(attachmentAudioPlayUrl(null), isNull);
      expect(attachmentAudioPlayUrl(''), isNull);
      expect(attachmentAudioPlayUrl('   '), isNull);
    });

    test('passes through absolute and api URLs', () {
      expect(
        attachmentAudioPlayUrl('https://cdn.example.com/a.m4a'),
        'https://cdn.example.com/a.m4a',
      );
      expect(
        attachmentAudioPlayUrl('/api/media/abc123?v=2'),
        '/api/media/abc123?v=2',
      );
    });

    test('returns local file path when file exists', () {
      final file = File(
        '${Directory.systemTemp.path}/retentio_play_url_${DateTime.now().microsecondsSinceEpoch}.m4a',
      );
      file.writeAsStringSync('x');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      expect(attachmentAudioPlayUrl(file.path), file.absolute.path);
    });

    test('maps bare media id to owned media URL', () {
      expect(attachmentAudioPlayUrl('media01'), '/api/media/media01');
    });

    test('appends snapshot pin for pinned media id', () {
      expect(
        attachmentAudioPlayUrl('media01', mediaVersions: const {'media01': 1}),
        '/api/media/media01?v=1',
      );
    });

    test('encodes reserved characters in a pinned media id', () {
      expect(
        attachmentAudioPlayUrl('a/b?c', mediaVersions: const {'a/b?c': 2}),
        '/api/media/a%2Fb%3Fc?v=2',
      );
    });

    test('omits v for ids without a positive pin', () {
      expect(
        attachmentAudioPlayUrl('media02', mediaVersions: const {'media01': 1}),
        '/api/media/media02',
      );
      expect(
        attachmentAudioPlayUrl('media01', mediaVersions: const {'media01': 0}),
        '/api/media/media01',
      );
    });
  });
}
