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
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
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
  final ops = <StudySyncOperation>[];
  bool failGetMediaPath = false;

  @override
  Future<List<StudySyncOperation>> getOperations() async => ops;

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
  late List<String> versionLookups;

  setUp(() async {
    store = _FakeStore();
    tmp = await Directory.systemTemp.createTemp('offline_dl_test');
    factOffsets = [];
    downloadedUrls = [];
    versionLookups = [];
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
    FetchMediaVersionsFn? fetchMediaVersions,
    bool online = true,
    int now = 1000,
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
    fetchMediaVersions:
        fetchMediaVersions ??
        (deckId, factId) async {
          versionLookups.add(factId);
          return const {};
        },
    nowSec: () => now,
    isOnline: () async => online,
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

  test('concurrent downloads of one deck share a single run', () async {
    final downloader = build(
      pages: [
        [
          _fact('f1', entries: const [FactEntry(audio: 'aud')]),
        ],
      ],
    );

    final results = await Future.wait([
      downloader.download('d1'),
      downloader.download('d1'),
    ]);
    await downloader.download('d1');

    expect(results, [true, true]);
    expect(factOffsets, [0, 0]);
    expect(downloadedUrls, ['/api/media/aud']);
  });

  group('refreshIfStale', () {
    const ready = OfflineDeck(
      id: 'd1',
      name: 'Old',
      fields: [],
      downloadedAt: 1,
    );
    const now = 10000;
    const interval = OfflinePackageDownloader.refreshIntervalSec;

    test('does nothing offline', () async {
      await build(online: false).refreshIfStale('d1');

      expect(factOffsets, isEmpty);
      expect(store.decks, isEmpty);
    });

    test('first download runs and leaves the deck due a refresh', () async {
      await build(now: now).refreshIfStale('d1');

      expect(factOffsets, [0]);
      final deck = store.decks['d1']!;
      expect(deck.downloadedAt, now);
      expect(deck.refreshedAt, 0);
    });

    test('skips a ready deck refreshed within the interval', () async {
      store.decks['d1'] = ready.copyWith(refreshedAt: now - interval + 1);

      await build(now: now).refreshIfStale('d1');

      expect(factOffsets, isEmpty);
    });

    test('refreshes a ready deck once the interval has passed', () async {
      store.decks['d1'] = ready.copyWith(refreshedAt: now - interval);

      await build(now: now).refreshIfStale('d1');

      expect(factOffsets, [0]);
      expect(store.decks['d1']!.refreshedAt, now);
      expect(store.decks['d1']!.downloadedAt, 1);
    });

    test('refreshes a ready deck never refreshed before', () async {
      store.decks['d1'] = ready;

      await build(now: now).refreshIfStale('d1');

      expect(store.decks['d1']!.refreshedAt, now);
    });
  });

  test('first seed inserts all cards', () async {
    await build(remoteCards: [_card('c1'), _card('c2')]).download('d1');

    expect(store.cards.keys, unorderedEquals(['c1', 'c2']));
  });

  test(
    're-download refreshes clean cards, keeps deck state, adds new cards',
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
      store.cards['local'] = _card('local', lastReview: 5);
      store.ops.add(
        const StudySyncOperation(
          operationId: 'op',
          sequence: 1,
          deckId: 'd2',
          cardId: 'c1',
          type: StudySyncType.hide,
          createdAt: 1,
        ),
      );
      const server = OfflineCard(
        deckId: 'd1',
        id: 'c1',
        factId: 'f2',
        template: [
          [1],
          [0],
        ],
        lastReview: 1,
        dueDate: 2,
        createdAt: 3,
      );

      await build(remoteCards: [server, _card('c2')]).download('d1');

      expect(store.cards['c1']!.toJson(), server.toJson());
      expect(store.cards['local']!.lastReview, 5);
      expect(store.cards.keys, unorderedEquals(['c1', 'local', 'c2']));
      final deck = store.decks['d1']!;
      expect(deck.name, 'Deck');
      expect(deck.downloadedAt, 10);
      expect(deck.lastSyncedAt, 20);
      expect(deck.totalReviews, 50);
      expect(deck.totalReviewsToday, 5);
      expect(deck.tags, isEmpty);
    },
  );

  test(
    'caches the fact tags of all pages, deduped and ordered by id',
    () async {
      store.decks['d1'] = const OfflineDeck(
        id: 'd1',
        name: 'Old',
        fields: [],
        tags: [Tag(id: 'old', name: 'gone', description: '')],
      );
      Tag tag(String id, String name) =>
          Tag(id: id, name: name, description: '');
      final pages = [
        OfflineFactsPage(
          facts: List.generate(200, (i) => _fact('a$i')),
          hasMore: true,
          tags: [tag('t2', 'b'), tag('t1', 'c')],
        ),
        OfflineFactsPage(
          facts: [_fact('b0')],
          hasMore: false,
          tags: [tag('t2', 'b'), tag('t0', 'a')],
        ),
      ];
      final downloader = OfflinePackageDownloader(
        store: store,
        mediaRootDir: tmp.path,
        fetchDeck: (_) async => _deck,
        fetchFactsPage: (_, _, offset) async => pages[offset ~/ 200],
        fetchCards: (_) async => [],
        nowSec: () => 1000,
      );

      expect(await downloader.download('d1'), isTrue);

      final tags = store.decks['d1']!.tags;
      expect([for (final t in tags) t.id], ['t0', 't1', 't2']);
      expect(tags.first.name, 'a');
    },
  );

  test('keeps deck counters written during the download', () async {
    const stored = OfflineDeck(id: 'd1', name: 'Old', fields: []);
    store.decks['d1'] = stored.copyWith(downloadedAt: 10);
    final downloader = OfflinePackageDownloader(
      store: store,
      mediaRootDir: tmp.path,
      fetchDeck: (_) async => _deck,
      fetchFactsPage: (_, _, _) async =>
          const OfflineFactsPage(facts: [], hasMore: false),
      fetchCards: (_) async {
        store.decks['d1'] = stored.copyWith(
          downloadedAt: 10,
          totalReviews: 70,
          totalReviewsToday: 7,
          lastSyncedAt: 30,
        );
        return [];
      },
      nowSec: () => 1000,
    );

    await downloader.download('d1');

    final deck = store.decks['d1']!;
    expect(deck.name, 'Deck');
    expect(deck.sourceVersion, 3);
    expect(deck.downloadedAt, 10);
    expect([deck.totalReviews, deck.totalReviewsToday], [70, 7]);
    expect(deck.lastSyncedAt, 30);
  });

  test('re-download keeps dirty cards and cards with queued ops', () async {
    store.cards['dirty'] = _card('dirty', lastReview: 77).copyWith(dirty: true);
    store.cards['queued'] = _card('queued', lastReview: 66);
    store.ops.add(
      const StudySyncOperation(
        operationId: 'op',
        sequence: 1,
        deckId: 'd1',
        cardId: 'queued',
        type: StudySyncType.review,
        createdAt: 1,
        status: StudySyncStatus.failed,
      ),
    );

    await build(
      remoteCards: [
        _card('dirty', lastReview: 1),
        _card('queued', lastReview: 2),
      ],
    ).download('d1');

    expect(store.cards['dirty']!.lastReview, 77);
    expect(store.cards['dirty']!.dirty, isTrue);
    expect(store.cards['queued']!.lastReview, 66);
  });

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

  test('imported deck downloads listed media at the pinned version', () async {
    final page = parseOfflineFactsPage('d1', {
      'facts': [
        {
          'id': 'f1',
          'entries': [
            {'audio': 'aud', 'image': 'ovl'},
          ],
          'media_versions': {'aud': 4},
        },
      ],
    }, limit: 200);

    await build(pages: [page.facts]).download('d1');

    expect(downloadedUrls, ['/api/media/aud?v=4', '/api/media/ovl']);
    expect(versionLookups, isEmpty);
    expect(store.media['aud?v=4'], '${tmp.path}/d1/aud_v=4');
    expect(store.media['ovl'], '${tmp.path}/d1/ovl');
    expect(store.facts['f1']!.mediaVersions, {'aud': 4});
  });

  group('imported deck media versions', () {
    FetchMediaVersionsFn lookup(Map<String, Map<String, int>?> byFact) =>
        (deckId, factId) async {
          expect(deckId, 'd1');
          versionLookups.add(factId);
          return byFact[factId];
        };

    test('looks up only facts with media and pins their downloads', () async {
      final ok = await build(
        pages: [
          [
            _fact(
              'f1',
              entries: const [FactEntry(audio: 'aud', video: 'vid')],
            ),
            _fact('f2', entries: const [FactEntry(text: 'no media')]),
            _fact('f3', entries: const [FactEntry(image: 'ovl')]),
          ],
        ],
        fetchMediaVersions: lookup({
          'f1': {'aud': 4, 'vid': 2},
          'f3': {},
        }),
      ).download('d1');

      expect(ok, isTrue);
      expect(versionLookups, unorderedEquals(['f1', 'f3']));
      expect(downloadedUrls, ['/api/media/aud?v=4', '/api/media/ovl']);
      expect(store.facts['f1']!.mediaVersions, {'aud': 4, 'vid': 2});
      expect(store.facts['f2']!.mediaVersions, isNull);
      expect(store.facts['f3']!.mediaVersions, isEmpty);
    });

    test('runs at most four lookups at a time', () async {
      var active = 0;
      var peak = 0;
      await build(
        pages: [
          [
            for (var i = 0; i < 10; i++)
              _fact('f$i', entries: [FactEntry(audio: 'a$i')]),
          ],
        ],
        fetchMediaVersions: (_, factId) async {
          versionLookups.add(factId);
          peak = ++active > peak ? active : peak;
          await Future<void>.delayed(Duration.zero);
          active--;
          return {};
        },
      ).download('d1');

      expect(versionLookups, hasLength(10));
      expect(peak, OfflinePackageDownloader.versionLookupConcurrency);
    });

    test('reuses stored versions of the same snapshot and media', () async {
      store.decks['d1'] = const OfflineDeck(
        id: 'd1',
        name: 'Deck',
        fields: [],
        sourceDeckId: 'src',
        sourceVersion: 3,
      );
      store.facts['f1'] = _fact(
        'f1',
        entries: const [FactEntry(audio: 'aud')],
      ).withMediaVersions({'aud': 4});
      store.facts['f2'] = _fact(
        'f2',
        entries: const [FactEntry(audio: 'old')],
      ).withMediaVersions({'old': 1});
      store.facts['f3'] = _fact('f3', entries: const [FactEntry(audio: 'a3')]);

      await build(
        pages: [
          [
            _fact('f1', entries: const [FactEntry(audio: 'aud')]),
            _fact('f2', entries: const [FactEntry(audio: 'new')]),
            _fact('f3', entries: const [FactEntry(audio: 'a3')]),
          ],
        ],
        fetchMediaVersions: lookup({
          'f2': {'new': 2},
          'f3': {'a3': 3},
        }),
      ).download('d1');

      expect(versionLookups, unorderedEquals(['f2', 'f3']));
      expect(store.facts['f1']!.mediaVersions, {'aud': 4});
      expect(downloadedUrls, [
        '/api/media/aud?v=4',
        '/api/media/new?v=2',
        '/api/media/a3?v=3',
      ]);
    });

    test('a new snapshot re-resolves and re-downloads pinned media', () async {
      store.decks['d1'] = const OfflineDeck(
        id: 'd1',
        name: 'Deck',
        fields: [],
        sourceDeckId: 'src',
        sourceVersion: 2,
      );
      store.facts['f1'] = _fact(
        'f1',
        entries: const [FactEntry(audio: 'aud')],
      ).withMediaVersions({'aud': 4});
      final oldPath = '${tmp.path}/d1/aud_v=4';
      File(oldPath).createSync(recursive: true);
      store.media['aud?v=4'] = oldPath;

      await build(
        pages: [
          [
            _fact('f1', entries: const [FactEntry(audio: 'aud')]),
          ],
        ],
        fetchMediaVersions: lookup({
          'f1': {'aud': 5},
        }),
      ).download('d1');

      expect(versionLookups, ['f1']);
      expect(downloadedUrls, ['/api/media/aud?v=5']);
      expect(store.media['aud?v=5'], '${tmp.path}/d1/aud_v=5');
    });

    test(
      'a failed lookup keeps the download and leaves media unpinned',
      () async {
        final ok = await build(
          pages: [
            [
              _fact('f1', entries: const [FactEntry(audio: 'a1')]),
              _fact('f2', entries: const [FactEntry(audio: 'a2')]),
            ],
          ],
          fetchMediaVersions: (_, factId) async {
            if (factId == 'f1') throw Exception('network');
            return null;
          },
        ).download('d1');

        expect(ok, isTrue);
        expect(store.decks['d1']!.isReady, isTrue);
        expect(downloadedUrls, ['/api/media/a1', '/api/media/a2']);
        expect(store.facts['f1']!.mediaVersions, isNull);
        expect(store.facts['f2']!.mediaVersions, isNull);
      },
    );

    test('owned decks never look up versions', () async {
      await build(
        fetchDeck: (_) async =>
            Deck.fromJson({'id': 'd1', 'name': 'Mine', 'fields': []}),
        pages: [
          [
            _fact('f1', entries: const [FactEntry(audio: 'aud')]),
          ],
        ],
      ).download('d1');

      expect(versionLookups, isEmpty);
      expect(downloadedUrls, ['/api/media/aud']);
      expect(store.facts['f1']!.mediaVersions, isNull);
    });
  });

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

    test('parseOfflineFactsPage keeps listed media versions of the fact', () {
      final page = parseOfflineFactsPage('d1', {
        'facts': [
          {
            'id': 'f1',
            'entries': [
              {'audio': 'a', 'image': 'b', 'video': 'c', 'json': 'd'},
              {'audio': 'e', 'image': 'f', 'video': 'g'},
            ],
            'media_versions': {
              'a': 1,
              'b': 2.0,
              'c': '3',
              'd': 'x',
              'e': 0,
              'f': -1,
              'other': 9,
            },
          },
          {
            'id': 'f2',
            'entries': [
              {'audio': 'a'},
            ],
          },
        ],
        'media_versions': {'a': 7},
      }, limit: 200);

      expect(page.facts[0].mediaVersions, {'a': 1, 'b': 2, 'c': 3});
      expect(page.facts[1].mediaVersions, {'a': 7});
      final unlisted = parseOfflineFactsPage('d1', {
        'facts': [
          {'id': 'f1'},
        ],
      }, limit: 200);
      expect(unlisted.facts.single.mediaVersions, isNull);
    });

    test('parseOfflineFactsPage collects tag objects of every fact', () {
      final page = parseOfflineFactsPage('d1', {
        'facts': [
          {
            'id': 'f1',
            'tags': [
              {'id': 't2', 'name': 'verb', 'description': 'pos'},
              {'name': 'no id'},
              'bad',
            ],
          },
          {
            'id': 'f2',
            'tags': [
              {'id': 7, 'name': null},
            ],
          },
          {'id': 'f3'},
        ],
      }, limit: 200);

      expect(
        [for (final t in page.tags) t.toJson()],
        [
          const Tag(id: 't2', name: 'verb', description: 'pos').toJson(),
          const Tag(id: '7', name: '', description: '').toJson(),
        ],
      );
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

    test('imported deck fetches pinned versions per fact', () async {
      final adapter = _FakeAdapter(imported: true);
      networkDioClient.dio.httpClientAdapter = adapter;

      final ok = await OfflinePackageDownloader(
        store: store,
        mediaRootDir: tmp.path,
      ).download('d1');

      expect(ok, isTrue);
      expect(store.facts['f1']!.mediaVersions, {'m1': 7});
      expect(adapter.mediaUris, ['/api/media/m1?v=7']);
      expect(File(store.media['m1?v=7']!).readAsBytesSync(), [1, 2, 3]);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.imported = false});

  final bool imported;
  final mediaUris = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path == '/api/media/m1') {
      mediaUris.add(
        '$path${options.uri.hasQuery ? '?${options.uri.query}' : ''}',
      );
      return ResponseBody.fromBytes([1, 2, 3], 200);
    }
    if (path.endsWith('/facts/f1')) {
      return _ok({
        'fact': {'id': 'f1', 'entries': []},
        'media_versions': {'m1': 7},
      });
    }
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
      if (imported) 'source_deck_id': 'src',
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
