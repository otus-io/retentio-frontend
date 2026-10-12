import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/data/remote_offline_package_data_source.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStore implements OfflineLearningStore {
  final decks = <String, OfflineDeck>{};
  final cards = <String, OfflineCard>{};
  final facts = <String, OfflineFact>{};
  final media = <String, String>{};
  bool failGetMediaPath = false;

  @override
  Future<OfflineDeck?> getDeck(String deckId) async => decks[deckId];
  @override
  Future<void> putDeck(OfflineDeck deck) async => decks[deck.id] = deck;
  @override
  Future<List<OfflineCard>> getCards(String deckId) async =>
      cards.values.where((c) => c.deckId == deckId).toList();
  @override
  Future<void> putCards(List<OfflineCard> list) async {
    for (final c in list) {
      cards[c.id] = c;
    }
  }

  @override
  Future<List<OfflineFact>> getFacts(String deckId) async =>
      facts.values.where((f) => f.deckId == deckId).toList();
  @override
  Future<void> putFacts(List<OfflineFact> list) async {
    for (final f in list) {
      facts[f.id] = f;
    }
  }

  @override
  Future<String?> getMediaPath(String mediaId) async {
    if (failGetMediaPath) throw StateError('store broken');
    return media[mediaId];
  }

  @override
  Future<void> putMediaPath(String mediaId, String localPath) async =>
      media[mediaId] = localPath;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _deck = Deck(
  id: 'd1',
  name: 'Deck',
  rate: 20,
  fields: ['Front', 'Back'],
  minInterval: 0,
  defInterval: 0,
  maxInterval: 0,
  sourceDeckId: 'src',
  sourceVersion: 3,
  stats: DeckStats(
    cardsCount: 0,
    factsCount: 0,
    unseenCards: 0,
    reviewedCards: 0,
    dueCards: 0,
    hiddenCards: 0,
    newCardsToday: 0,
    totalReviews: 9,
    totalReviewsToday: 2,
    lastReviewedAt: 0,
  ),
);

OfflineFact _fact(String id, {List<FactEntry> entries = const []}) =>
    OfflineFact(deckId: 'd1', id: id, entries: entries);

OfflineCard _card(String id, {int lastReview = 0, int dueDate = 0}) =>
    OfflineCard(
      deckId: 'd1',
      id: id,
      factId: 'f1',
      template: const [
        [0],
        [1],
      ],
      lastReview: lastReview,
      dueDate: dueDate,
    );

void main() {
  late _FakeStore store;
  late Directory tmp;
  late List<int> factOffsets;
  late List<String> downloadedUrls;

  setUp(() async {
    store = _FakeStore();
    tmp = await Directory.systemTemp.createTemp('offline_dl_test');
    factOffsets = [];
    downloadedUrls = [];
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<String?> writeMedia(String url, String path) async {
    downloadedUrls.add(url);
    await File(path).create(recursive: true);
    return path;
  }

  OfflinePackageDownloader build({
    FetchDeckFn? fetchDeck,
    List<List<OfflineFact>> pages = const [[]],
    Object? factsError,
    List<OfflineCard> remoteCards = const [],
    Object? cardsError,
    DownloadMediaFn? downloadMedia,
  }) => OfflinePackageDownloader(
    store: store,
    mediaRootDir: tmp.path,
    fetchDeck: fetchDeck ?? (_) async => _deck,
    fetchFactsPage: (deckId, limit, offset) async {
      if (factsError != null) throw factsError;
      final index = factOffsets.length;
      factOffsets.add(offset);
      expect(limit, OfflinePackageDownloader.factsPageSize);
      return OfflineFactsPage(
        facts: pages[index],
        hasMore: index < pages.length - 1,
      );
    },
    fetchCards: (_) async {
      if (cardsError != null) throw cardsError;
      return remoteCards;
    },
    downloadMedia: downloadMedia ?? writeMedia,
    nowSec: () => 1000,
  );

  test('fetches all fact pages and marks the deck ready', () async {
    final ok = await build(
      pages: [
        List.generate(200, (i) => _fact('a$i')),
        [_fact('b0')],
      ],
    ).download('d1');

    expect(ok, isTrue);
    expect(factOffsets, [0, 200]);
    expect(store.facts, hasLength(201));
    final deck = store.decks['d1']!;
    expect(deck.downloadedAt, 1000);
    expect(deck.name, 'Deck');
    expect(deck.fields, ['Front', 'Back']);
    expect(deck.rate, 20);
    expect(deck.sourceDeckId, 'src');
    expect(deck.sourceVersion, 3);
    expect(deck.totalReviews, 9);
    expect(deck.totalReviewsToday, 2);
  });

  test('stops paging on an empty page even if hasMore is set', () async {
    final downloader = OfflinePackageDownloader(
      store: store,
      mediaRootDir: tmp.path,
      fetchDeck: (_) async => _deck,
      fetchFactsPage: (_, _, offset) async {
        factOffsets.add(offset);
        return const OfflineFactsPage(facts: [], hasMore: true);
      },
      fetchCards: (_) async => [],
      nowSec: () => 1,
    );

    expect(await downloader.download('d1'), isTrue);
    expect(factOffsets, [0]);
  });

  test('first seed inserts all cards', () async {
    await build(remoteCards: [_card('c1'), _card('c2')]).download('d1');

    expect(store.cards.keys, unorderedEquals(['c1', 'c2']));
  });

  test(
    're-download keeps local schedule and deck state, adds new cards',
    () async {
      store.decks['d1'] = const OfflineDeck(
        id: 'd1',
        name: 'Old',
        fields: [],
        totalReviews: 50,
        totalReviewsToday: 5,
        downloadedAt: 10,
        lastSyncedAt: 20,
        tags: [Tag(id: 't1', name: 'N5', description: '')],
      );
      store.cards['c1'] = _card(
        'c1',
        lastReview: 77,
        dueDate: 88,
      ).copyWith(hidden: true);

      await build(
        remoteCards: [_card('c1', lastReview: 1, dueDate: 2), _card('c2')],
      ).download('d1');

      final kept = store.cards['c1']!;
      expect([kept.lastReview, kept.dueDate, kept.hidden], [77, 88, true]);
      expect(store.cards.keys, unorderedEquals(['c1', 'c2']));
      final deck = store.decks['d1']!;
      expect(deck.name, 'Deck');
      expect(deck.downloadedAt, 10);
      expect(deck.lastSyncedAt, 20);
      expect(deck.totalReviews, 50);
      expect(deck.totalReviewsToday, 5);
      expect(deck.tags.single.id, 't1');
    },
  );

  test(
    'downloads audio and image, skips video, json and cached media',
    () async {
      final cachedPath = '${tmp.path}/old/cached';
      File(cachedPath).createSync(recursive: true);
      store.media['cached'] = cachedPath;
      final ok = await build(
        pages: [
          [
            _fact(
              'f1',
              entries: const [
                FactEntry(text: 'a', audio: 'aud', video: 'vid', json: 'js'),
                FactEntry(image: 'img'),
                FactEntry(audio: 'cached'),
                FactEntry(audio: 'aud'),
              ],
            ),
          ],
        ],
      ).download('d1');

      expect(ok, isTrue);
      expect(downloadedUrls, ['/api/media/aud', '/api/media/img']);
      final audPath = '${tmp.path}/d1/aud';
      expect(store.media['aud'], audPath);
      expect(store.media['img'], '${tmp.path}/d1/img');
      expect(store.media['cached'], cachedPath);
      expect(File(audPath).existsSync(), isTrue);
      expect(File('$audPath.part').existsSync(), isFalse);
    },
  );

  test('re-downloads media whose cached file is gone', () async {
    store.media['aud'] = '${tmp.path}/gone/aud';

    await build(
      pages: [
        [
          _fact('f1', entries: const [FactEntry(audio: 'aud')]),
        ],
      ],
    ).download('d1');

    expect(downloadedUrls, ['/api/media/aud']);
    expect(store.media['aud'], '${tmp.path}/d1/aud');
  });

  test('names media files by their sniffed format', () async {
    final heads = <String, List<int>>{
      '.png': [0x89, 0x50, 0x4E, 0x47],
      '.jpg': [0xFF, 0xD8, 0xFF, 0xE0],
      '.gif': [0x47, 0x49, 0x46, 0x38],
      '.webp': [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50],
      '.wav': [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x41, 0x56, 0x45],
      '.mp3': [0x49, 0x44, 0x33, 4],
      '.ogg': [0x4F, 0x67, 0x67, 0x53],
      '.webm': [0x1A, 0x45, 0xDF, 0xA3],
      '.m4a': [0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70],
      '': [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 1, 2, 3, 4],
    };
    for (final MapEntry(key: ext, value: bytes) in heads.entries) {
      final path = '${tmp.path}/sniff$ext.bin';
      File(path).writeAsBytesSync(bytes);
      expect(await mediaFileExtension(path), ext);
    }
    final frameSync = '${tmp.path}/frame.bin';
    File(frameSync).writeAsBytesSync([0xFF, 0xFB, 0x90]);
    expect(await mediaFileExtension(frameSync), '.mp3');
  });

  test('media failures still return true', () async {
    final pages = [
      [
        _fact(
          'f1',
          entries: const [
            FactEntry(audio: 'empty'),
            FactEntry(image: 'null'),
            FactEntry(audio: 'boom'),
          ],
        ),
      ],
    ];
    final ok = await build(
      pages: pages,
      downloadMedia: (url, path) async {
        if (url.endsWith('boom')) throw Exception('network');
        return url.endsWith('empty') ? '' : null;
      },
    ).download('d1');

    expect(ok, isTrue);
    expect(store.media, isEmpty);
    expect(store.decks['d1']!.isReady, isTrue);
  });

  test('store media lookup failure does not fail download', () async {
    store.failGetMediaPath = true;
    final ok = await build(
      pages: [
        [
          _fact('f1', entries: const [FactEntry(audio: 'aud')]),
        ],
      ],
    ).download('d1');

    expect(ok, isTrue);
  });

  test('deck failure returns false and does not mark ready', () async {
    final ok = await build(
      fetchDeck: (_) => throw StateError('x'),
    ).download('d1');

    expect(ok, isFalse);
    expect(store.decks, isEmpty);
  });

  test('facts failure returns false and does not mark ready', () async {
    final ok = await build(factsError: StateError('x')).download('d1');

    expect(ok, isFalse);
    expect(store.decks, isEmpty);
  });

  test('cards failure returns false and does not mark ready', () async {
    final ok = await build(
      pages: [
        [_fact('f1')],
      ],
      cardsError: StateError('x'),
    ).download('d1');

    expect(ok, isFalse);
    expect(store.decks, isEmpty);
    expect(store.facts.keys, ['f1']);
  });

  group('parsing', () {
    test('parseOfflineFactsPage maps entries and tag ids', () {
      final page = parseOfflineFactsPage('d1', {
        'facts': [
          {
            'id': 'f1',
            'entries': [
              {'text': 'Apple', 'audio': 'a1'},
              'bad',
            ],
            'tags': [
              {'id': 't1', 'name': 'food'},
              {'name': 'no id'},
              {'id': 't2'},
            ],
          },
          {'id': 'f2'},
          'bad',
        ],
      }, limit: 3);

      expect(page.hasMore, isTrue);
      expect(page.facts, hasLength(2));
      final f1 = page.facts.first;
      expect([f1.deckId, f1.id], ['d1', 'f1']);
      expect(f1.entries.single.text, 'Apple');
      expect(f1.entries.single.audio, 'a1');
      expect(f1.tagIds, ['t1', 't2']);
      expect(page.facts[1].entries, isEmpty);
      expect(page.facts[1].tagIds, isEmpty);
    });

    test('parseOfflineFactsPage reports no more on a short page', () {
      final page = parseOfflineFactsPage('d1', {'facts': []}, limit: 200);

      expect(page.hasMore, isFalse);
    });

    test('parseOfflineFactsPage throws on missing facts', () {
      expect(
        () => parseOfflineFactsPage('d1', null, limit: 1),
        throwsStateError,
      );
      expect(() => parseOfflineFactsPage('d1', {}, limit: 1), throwsStateError);
    });

    test('parseOfflineCards maps cards with deck id and clean state', () {
      final cards = parseOfflineCards('d1', {
        'stats': {},
        'cards': [
          {
            'id': 'c1',
            'fact_id': 'f1',
            'template': [
              [0],
              [1],
            ],
            'last_review': 5,
            'due_date': 6,
            'hidden': true,
            'created_at': 4,
            'dirty': true,
          },
          'bad',
        ],
      });

      final c = cards.single;
      expect([c.deckId, c.id, c.factId], ['d1', 'c1', 'f1']);
      expect(c.template, [
        [0],
        [1],
      ]);
      expect([c.lastReview, c.dueDate, c.createdAt], [5, 6, 4]);
      expect(c.hidden, isTrue);
      expect(c.dirty, isFalse);
    });

    test('parseOfflineCards throws on missing cards', () {
      expect(() => parseOfflineCards('d1', 'x'), throwsStateError);
      expect(() => parseOfflineCards('d1', {'stats': {}}), throwsStateError);
    });
  });

  group('production defaults', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiService.clearToken();
      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      networkDioClient.dio.httpClientAdapter = _FakeAdapter();
    });

    test('download uses the real API helpers', () async {
      final downloader = OfflinePackageDownloader(
        store: store,
        mediaRootDir: tmp.path,
      );

      expect(await downloader.download('d1'), isTrue);

      expect(store.decks['d1']!.isReady, isTrue);
      expect(store.facts.keys, ['f1']);
      expect(store.facts['f1']!.tagIds, ['t1']);
      expect(store.cards.keys, ['c1']);
      final path = store.media['m1']!;
      expect(File(path).readAsBytesSync(), [1, 2, 3]);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (path == '/api/media/m1') return ResponseBody.fromBytes([1, 2, 3], 200);
    if (path.endsWith('/facts')) {
      expect(options.queryParameters, {'limit': 200, 'offset': 0});
      return _ok({
        'facts': [
          {
            'id': 'f1',
            'entries': [
              {'text': 'x', 'audio': 'm1'},
            ],
            'tags': [
              {'id': 't1'},
            ],
          },
        ],
      });
    }
    if (path.endsWith('/cards')) {
      return _ok({
        'stats': {},
        'cards': [
          {'id': 'c1', 'fact_id': 'f1'},
        ],
      });
    }
    return _ok({
      'id': 'd1',
      'name': 'Deck',
      'fields': ['A', 'B'],
    });
  }

  ResponseBody _ok(Map<String, dynamic> data) => ResponseBody.fromString(
    jsonEncode({'code': 0, 'msg': 'ok', 'data': data}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
