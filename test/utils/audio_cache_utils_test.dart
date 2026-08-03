import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/card.dart';
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

  group('audioUrlsOnCard', () {
    test('collects distinct non-empty audio URLs from front and back', () {
      final card = Card(
        id: 'c1',
        factId: 'f1',
        hidden: false,
        createdAt: 1,
        dueDate: 2,
        lastReview: 1,
        template: const [
          [0],
          [1],
        ],
        front: [
          CardSlot(
            field: 'A',
            items: [
              Item(type: 'text', value: 'hi'),
              Item(type: 'audio', value: 'https://cdn/a.m4a'),
              Item(type: 'audio', value: '  '),
            ],
          ),
        ],
        back: [
          CardSlot(
            field: 'B',
            items: [
              Item(type: 'audio', value: 'https://cdn/b.m4a'),
              Item(type: 'audio', value: 'https://cdn/a.m4a'),
            ],
          ),
        ],
      );

      expect(audioUrlsOnCard(card), ['https://cdn/a.m4a', 'https://cdn/b.m4a']);
    });
  });

  group('ensureAudioCached', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('retentio_ensure_audio_');
    });

    tearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    test('skips download when a playable cache file exists', () async {
      var downloads = 0;
      final path = '${dir.path}/clip.m4a';
      await File(
        path,
      ).writeAsBytes(List<int>.filled(kMinAudioFileBytesForPlayback, 1));

      final out = await ensureAudioCached(
        'https://cdn/clip.m4a',
        cachePath: (_) async => path,
        download: (url, p) async {
          downloads += 1;
          return p;
        },
      );

      expect(out, path);
      expect(downloads, 0);
    });

    test('re-downloads a cache file too small to play', () async {
      var downloads = 0;
      final path = '${dir.path}/truncated.m4a';
      await File(path).writeAsBytes([1, 2, 3]);

      final out = await ensureAudioCached(
        'https://cdn/truncated.m4a',
        cachePath: (_) async => path,
        download: (url, p) async {
          downloads += 1;
          await File(
            p,
          ).writeAsBytes(List<int>.filled(kMinAudioFileBytesForPlayback, 2));
          return p;
        },
      );

      expect(out, path);
      expect(downloads, 1);
    });

    test('concurrent callers share a single download', () async {
      var downloads = 0;
      final path = '${dir.path}/shared.m4a';
      final gate = Completer<void>();

      final first = ensureAudioCached(
        'https://cdn/shared.m4a',
        cachePath: (_) async => path,
        download: (url, p) async {
          downloads += 1;
          await gate.future;
          await File(
            p,
          ).writeAsBytes(List<int>.filled(kMinAudioFileBytesForPlayback, 3));
          return p;
        },
      );
      final second = ensureAudioCached(
        'https://cdn/shared.m4a',
        cachePath: (_) async => path,
        download: (url, p) async {
          downloads += 1;
          return p;
        },
      );
      gate.complete();

      expect(await Future.wait([first, second]), [path, path]);
      expect(downloads, 1);
    });

    test('downloads when cache is missing', () async {
      var downloads = 0;
      final path = '${dir.path}/new.m4a';

      final out = await ensureAudioCached(
        'https://cdn/new.m4a',
        cachePath: (_) async => path,
        download: (url, p) async {
          downloads += 1;
          await File(p).writeAsBytes([9, 9, 9]);
          return p;
        },
      );

      expect(out, path);
      expect(downloads, 1);
      expect(File(path).existsSync(), isTrue);
    });

    test('returns null when download fails', () async {
      final path = '${dir.path}/missing.m4a';
      final out = await ensureAudioCached(
        'https://cdn/missing.m4a',
        cachePath: (_) async => path,
        download: (url, p) async => null,
      );
      expect(out, isNull);
    });
  });

  group('prefetchCardAudio', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('retentio_prefetch_audio_');
    });

    tearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    test('downloads each audio URL on the card', () async {
      final downloaded = <String>[];
      final card = Card(
        id: 'c1',
        factId: 'f1',
        hidden: false,
        createdAt: 1,
        dueDate: 2,
        lastReview: 1,
        template: const [
          [0],
          [1],
        ],
        front: [
          CardSlot(
            field: 'A',
            items: [Item(type: 'audio', value: 'https://cdn/a.m4a')],
          ),
        ],
        back: [
          CardSlot(
            field: 'B',
            items: [Item(type: 'audio', value: 'https://cdn/b.m4a')],
          ),
        ],
      );

      await prefetchCardAudio(
        card,
        cachePath: (url) async =>
            '${dir.path}/${cacheFileNameForAudioUrl(url)}',
        download: (url, path) async {
          downloaded.add(url);
          await File(path).writeAsBytes([1]);
          return path;
        },
      );

      expect(downloaded, ['https://cdn/a.m4a', 'https://cdn/b.m4a']);
    });
  });
}
