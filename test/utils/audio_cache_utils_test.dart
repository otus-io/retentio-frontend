import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/utils/audio_cache_utils.dart';

void main() {
  group('cacheFileNameForAudioUrl', () {
    test('keeps known audio extensions from path basename', () {
      expect(
        cacheFileNameForAudioUrl('https://cdn.example.com/a/b/clip.m4a?x=1'),
        'clip.m4a',
      );
      expect(cacheFileNameForAudioUrl('/files/x.AAC'), 'x.AAC');
    });

    test('appends .mp3 when basename has no audio extension', () {
      expect(
        cacheFileNameForAudioUrl('https://api.example.com/media/abc123'),
        'abc123.mp3',
      );
    });

    test('uses hash-based name when path basename is empty', () {
      final name = cacheFileNameForAudioUrl('https://host/');
      expect(name, startsWith('audio_'));
      expect(name, endsWith('.mp3'));
    });
  });

  group('bytesLookLikeIsoBmffFtyp', () {
    test('false when too short', () {
      expect(bytesLookLikeIsoBmffFtyp([0, 1, 2, 3, 4, 5, 6]), isFalse);
      expect(bytesLookLikeIsoBmffFtyp([]), isFalse);
    });

    test('true when ftyp at bytes 4–7', () {
      expect(
        bytesLookLikeIsoBmffFtyp([0, 0, 0, 0, 0x66, 0x74, 0x79, 0x70]),
        isTrue,
      );
    });

    test('false when brand is not ftyp', () {
      expect(
        bytesLookLikeIsoBmffFtyp([0, 0, 0, 0, 0x00, 0x74, 0x79, 0x70]),
        isFalse,
      );
    });
  });

  group('renameMp3CacheToM4aIfFtyp', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('retentio_audio_cache_test_');
    });

    tearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    test('renames .mp3 to .m4a when header is ISO BMFF ftyp', () async {
      final mp3Path = '${dir.path}/cache.mp3';
      // Minimal header: box size + "ftyp" at offset 4
      await File(
        mp3Path,
      ).writeAsBytes([0, 0, 0, 0, 0x66, 0x74, 0x79, 0x70, 0, 0, 0, 0]);
      final out = await renameMp3CacheToM4aIfFtyp(mp3Path);
      expect(out, '${dir.path}/cache.m4a');
      expect(File(out).existsSync(), isTrue);
      expect(File(mp3Path).existsSync(), isFalse);
    });

    test('leaves non-ftyp .mp3 unchanged', () async {
      final path = '${dir.path}/real.mp3';
      await File(path).writeAsBytes(List<int>.filled(32, 0xab));
      final out = await renameMp3CacheToM4aIfFtyp(path);
      expect(out, path);
      expect(File(path).existsSync(), isTrue);
    });

    test('ignores non-mp3 paths', () async {
      final path = '${dir.path}/x.m4a';
      await File(path).writeAsBytes([0, 0, 0, 0, 0x66, 0x74, 0x79, 0x70]);
      expect(await renameMp3CacheToM4aIfFtyp(path), path);
    });
  });
}
