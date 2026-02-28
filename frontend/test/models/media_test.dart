import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/models/media.dart';

void main() {
  group('MediaItem', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'm1',
        'owner': 'user1',
        'filename': 'audio.mp3',
        'mime': 'audio/mpeg',
        'size': 1024,
        'checksum': 'sha256:abc',
        'created_at': 1704067200,
      };
      final m = MediaItem.fromJson(json);
      expect(m.id, 'm1');
      expect(m.owner, 'user1');
      expect(m.filename, 'audio.mp3');
      expect(m.mime, 'audio/mpeg');
      expect(m.size, 1024);
      expect(m.checksum, 'sha256:abc');
      expect(m.createdAt, 1704067200);
    });

    test('fromJson handles missing fields', () {
      final m = MediaItem.fromJson({});
      expect(m.id, '');
      expect(m.owner, '');
      expect(m.filename, '');
      expect(m.mime, '');
      expect(m.size, 0);
      expect(m.checksum, '');
      expect(m.createdAt, 0);
    });

    test('toJson round-trip', () {
      const m = MediaItem(
        id: 'x',
        owner: 'u',
        filename: 'f',
        mime: 'image/png',
        size: 100,
        checksum: 'c',
        createdAt: 1,
      );
      expect(MediaItem.fromJson(m.toJson()).id, m.id);
      expect(MediaItem.fromJson(m.toJson()).size, m.size);
    });

    test(
      'audio mime: isAudio, placeholderPrefix, fieldNameSuffix, entryPlaceholder',
      () {
        const m = MediaItem(
          id: 'aid1',
          owner: 'u',
          filename: 'f.mp3',
          mime: 'audio/mpeg',
          size: 0,
          checksum: '',
          createdAt: 0,
        );
        expect(m.isAudio, true);
        expect(m.isImage, false);
        expect(m.placeholderPrefix, 'audio');
        expect(m.fieldNameSuffix, 'audio');
        expect(m.entryPlaceholder, '[audio:aid1]');
      },
    );

    test(
      'image mime: isImage, placeholderPrefix, fieldNameSuffix, entryPlaceholder',
      () {
        const m = MediaItem(
          id: 'iid1',
          owner: 'u',
          filename: 'f.png',
          mime: 'image/png',
          size: 0,
          checksum: '',
          createdAt: 0,
        );
        expect(m.isAudio, false);
        expect(m.isImage, true);
        expect(m.placeholderPrefix, 'image');
        expect(m.fieldNameSuffix, 'img');
        expect(m.entryPlaceholder, '[image:iid1]');
      },
    );

    test('static mime helpers', () {
      expect(MediaItem.isAudioMime('audio/mpeg'), true);
      expect(MediaItem.isAudioMime('AUDIO/wav'), true);
      expect(MediaItem.isAudioMime('image/png'), false);
      expect(MediaItem.isImageMime('image/png'), true);
      expect(MediaItem.isImageMime('IMAGE/jpeg'), true);
      expect(MediaItem.isImageMime('audio/mpeg'), false);
      expect(MediaItem.placeholderPrefixForMime('audio/ogg'), 'audio');
      expect(MediaItem.placeholderPrefixForMime('image/gif'), 'image');
      expect(MediaItem.fieldNameSuffixForMime('audio/mpeg'), 'audio');
      expect(MediaItem.fieldNameSuffixForMime('image/webp'), 'img');
    });

    test('unknown or empty mime defaults to image/img', () {
      const m = MediaItem(
        id: 'x',
        owner: 'u',
        filename: 'f',
        mime: '',
        size: 0,
        checksum: '',
        createdAt: 0,
      );
      expect(m.placeholderPrefix, 'image');
      expect(m.fieldNameSuffix, 'img');
    });
  });
}
