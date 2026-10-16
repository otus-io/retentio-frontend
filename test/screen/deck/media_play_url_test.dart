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

    test('treats an absolute path as a local file without a disk check', () {
      final missing = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}retentio_play_url_missing_${DateTime.now().microsecondsSinceEpoch}.m4a',
      );
      expect(missing.existsSync(), isFalse);
      expect(attachmentAudioPlayUrl(missing.path), missing.absolute.path);
    });

    test('absoluteAttachmentExists ignores media ids', () async {
      expect(await absoluteAttachmentExists('aud1'), isFalse);
    });

    test(
      'absoluteAttachmentExists reports whether an absolute file exists',
      () async {
        final missing = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}retentio_attach_missing_${DateTime.now().microsecondsSinceEpoch}.m4a',
        );
        final present = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}retentio_attach_present_${DateTime.now().microsecondsSinceEpoch}.m4a',
        );
        present.writeAsStringSync('x');
        addTearDown(() {
          if (present.existsSync()) present.deleteSync();
        });

        expect(await absoluteAttachmentExists(missing.path), isFalse);
        expect(await absoluteAttachmentExists(present.path), isTrue);
      },
    );

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
