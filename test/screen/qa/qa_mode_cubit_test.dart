import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/screen/qa/qa_column_prefs.dart';
import 'package:retentio/screen/qa/qa_mode_cubit.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_qa_api_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeQaApiAdapter adapter;

  FakeQaApiAdapter buildAdapter({
    List<String> factIds = const ['fact-1', 'fact-2'],
    Map<String, Map<String, dynamic>> qualityByFactId = const {},
    Map<String, Map<String, int>> mediaVersionsByFactId = const {},
    Map<String, dynamic>? stats,
    bool qualityPutFails = false,
    bool contributionFails = false,
    Set<String> verifiedFactIds = const {},
  }) {
    adapter = FakeQaApiAdapter(
      factIds: factIds,
      entriesByFactId: {
        'fact-1': [
          {'text': 'headword', 'audio': 'aud-1'},
          {'text': 'meaning'},
        ],
        'fact-2': [
          {'text': 'second'},
        ],
        'fact-3': [
          {'text': 'third'},
        ],
      },
      qualityByFactId: qualityByFactId,
      mediaVersionsByFactId: mediaVersionsByFactId,
      stats: stats,
      qualityPutFails: qualityPutFails,
      contributionFails: contributionFails,
      verifiedFactIds: verifiedFactIds,
    );
    networkDioClient.dio.httpClientAdapter = adapter;
    return adapter;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.clearToken();
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
    buildAdapter();
  });

  Future<void> startWalk(
    QaModeCubit cubit, {
    Set<int> columns = const {0, 1},
  }) => cubit.startWalk(columns);

  group('startWalk', () {
    test('loads the first fact and deck counters', () async {
      buildAdapter(stats: {'verified_aspects': 2, 'total_aspects': 6});
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await startWalk(cubit);

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.factIds, ['fact-1', 'fact-2']);
      expect(cubit.state.entries, hasLength(2));
      expect(cubit.state.stats?.verifiedAspects, 2);
      expect(cubit.state.hasPrev, isFalse);
      expect(cubit.state.hasNext, isTrue);
      expect(cubit.state.factLoadFailed, isFalse);
      await cubit.close();
    });

    test('walks only facts still unverified in the selected columns', () async {
      buildAdapter(verifiedFactIds: {'fact-1'});
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await cubit.startWalk({1, 0});

      expect(adapter.unverifiedColumnsQueries, ['0,1']);
      expect(cubit.state.factIds, ['fact-2']);
      expect(cubit.state.index, 0);
      expect(cubit.state.entries.first.text, 'second');
      expect(cubit.state.hasPrev, isFalse);
      await cubit.close();
    });

    test('shows walk complete when nothing is left to verify', () async {
      buildAdapter(
        verifiedFactIds: {'fact-1', 'fact-2'},
        stats: {'verified_aspects': 4, 'total_aspects': 4},
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await startWalk(cubit);

      expect(cubit.state.walkComplete, isTrue);
      expect(cubit.state.pickingColumns, isFalse);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.fact, isNull);
      await cubit.close();
    });

    test('a deck with nothing to verify is empty, not complete', () async {
      buildAdapter(
        factIds: const [],
        stats: {'verified_aspects': 0, 'total_aspects': 0},
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await startWalk(cubit);

      expect(cubit.state.walkComplete, isFalse);
      expect(cubit.state.factIds, isEmpty);
      await cubit.close();
    });

    test('starts with all columns unchecked', () async {
      buildAdapter(
        qualityByFactId: {
          'fact-1': {
            '0': {
              'text': {'score': 10, 'model': 'human'},
              'audio': {'score': 10, 'model': 'human'},
            },
            '1': {
              'text': {'score': 3, 'model': 'claude'},
            },
          },
        },
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await startWalk(cubit);

      expect(cubit.state.checkedIndexes, isEmpty);
      expect(cubit.state.canVerify, isFalse);
      await cubit.close();
    });

    test('loads every id before painting the first fact', () async {
      final ids = [for (var i = 0; i < 450; i++) 'fact-$i'];
      adapter = FakeQaApiAdapter(
        factIds: ids,
        entriesByFactId: {
          for (final id in ids)
            id: [
              {'text': id},
            ],
        },
      );
      networkDioClient.dio.httpClientAdapter = adapter;
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await startWalk(cubit);

      expect(cubit.state.factIds, hasLength(450));
      expect(adapter.factIdsRequestCount, 1);
      expect(cubit.state.entries.first.text, 'fact-0');
      await cubit.close();
    });

    test('loads snapshot media_versions for the current fact', () async {
      buildAdapter(
        mediaVersionsByFactId: {
          'fact-1': {'aud-1': 1},
        },
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await startWalk(cubit);

      expect(cubit.state.mediaVersions, {'aud-1': 1});
      await cubit.close();
    });

    test('stays empty when the deck has no facts', () async {
      buildAdapter(factIds: const []);
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await startWalk(cubit);

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.factIds, isEmpty);
      expect(cubit.state.factLoadFailed, isFalse);
      await cubit.close();
    });

    test('flags a fact that cannot be loaded', () async {
      buildAdapter(factIds: const ['missing']);
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await startWalk(cubit);

      expect(cubit.state.factLoadFailed, isTrue);
      expect(cubit.state.canVerify, isFalse);
      await cubit.close();
    });
  });

  group('navigation', () {
    test('next and prev walk the fact list', () async {
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);
      cubit.toggleColumn(1);

      await cubit.next();
      expect(cubit.state.index, 1);
      expect(cubit.state.walkComplete, isFalse);
      expect(cubit.state.entries.first.text, 'second');
      expect(cubit.state.hasNext, isFalse);

      await cubit.prev();
      expect(cubit.state.index, 0);
      await cubit.close();
    });

    test(
      'next does not advance until every scoreable column is checked',
      () async {
        final cubit = QaModeCubit(
          deckId: 'imp-1',
          deckFieldCount: 2,
          isOnline: () async => true,
        );
        await startWalk(cubit);
        expect(cubit.state.canAdvance, isFalse);

        expect(await cubit.next(), isNull);
        expect(cubit.state.index, 0);
        expect(adapter.qualityPuts, isEmpty);

        cubit.toggleColumn(0);
        expect(cubit.state.canAdvance, isFalse);
        expect(await cubit.next(), isNull);
        expect(cubit.state.index, 0);
        expect(adapter.qualityPuts, isEmpty);

        cubit.toggleColumn(1);
        expect(cubit.state.canAdvance, isTrue);
        await cubit.next();
        expect(cubit.state.index, 1);
        await cubit.close();
      },
    );

    test('auto-signs the checked columns before advancing', () async {
      buildAdapter(stats: {'verified_aspects': 0, 'total_aspects': 3});
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);
      cubit.toggleColumn(1);

      expect(await cubit.next(), isNull);

      expect(adapter.qualityPuts, hasLength(1));
      expect(adapter.qualityPuts.single.containsKey('columns'), isFalse);
      expect(adapter.verifiedFactIds, {'fact-1'});
      expect(cubit.state.index, 1);
      expect(cubit.state.checkedIndexes, isEmpty);
      await cubit.close();
    });

    test('next verifies the last fact without advancing', () async {
      buildAdapter(factIds: const ['fact-1']);
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);
      cubit.toggleColumn(1);

      expect(cubit.state.hasNext, isFalse);

      final hold = Completer<void>();
      adapter.statsHold = hold.future;
      final pending = cubit.next();
      await adapter.waitUntilStatsHold;
      expect(cubit.state.busy, isTrue);
      hold.complete();
      expect(await pending, isNull);

      expect(adapter.qualityPuts, hasLength(1));
      expect(cubit.state.index, 0);
      expect(cubit.state.checkedIndexes, isEmpty);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.walkComplete, isTrue);
      await cubit.close();
    });

    test('next returns the API message when verify fails', () async {
      buildAdapter(qualityPutFails: true);
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);
      cubit.toggleColumn(1);

      expect(await cubit.next(), 'fact not in pinned snapshot');
      expect(cubit.state.index, 0);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.walkComplete, isFalse);
      expect(adapter.verifiedFactIds, isEmpty);
      await cubit.close();
    });

    test('next signs off a single column and finishes the walk', () async {
      buildAdapter(stats: {'verified_aspects': 0, 'total_aspects': 3});
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await cubit.startWalk({1});
      cubit.toggleColumn(1);

      await cubit.next();
      expect(cubit.state.index, 1);
      expect(cubit.state.walkComplete, isFalse);
      expect(adapter.qualityPuts.single['entries'], contains('1'));
      expect(adapter.verifiedFactIds, {'fact-1'});

      expect(cubit.state.canAdvance, isTrue);
      await cubit.next();
      expect(cubit.state.index, 1);
      expect(cubit.state.walkComplete, isTrue);
      // Fact 2 has nothing scoreable in column 1, so no second quality PUT.
      expect(adapter.qualityPuts, hasLength(1));

      await cubit.prev();
      expect(cubit.state.walkComplete, isFalse);
      await cubit.close();
    });

    test('a new walk skips facts verified in an earlier one', () async {
      buildAdapter(
        factIds: const ['fact-1', 'fact-2', 'fact-3'],
        stats: {'verified_aspects': 0, 'total_aspects': 3},
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);
      cubit.toggleColumn(1);
      await cubit.next();
      await cubit.prev();
      expect(cubit.state.factIds, ['fact-1', 'fact-2', 'fact-3']);
      expect(cubit.state.index, 0, reason: 'Prev revisits a verified fact');
      await cubit.close();

      final again = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(again);
      expect(again.state.factIds, ['fact-2', 'fact-3']);
      expect(again.state.entries.first.text, 'second');
      await again.close();
    });

    test('ignores out-of-range targets', () async {
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);

      await cubit.prev();
      expect(cubit.state.index, 0);

      await cubit.goTo(9);
      expect(cubit.state.index, 0);
      await cubit.close();
    });
  });

  group('toggleColumn', () {
    test('adds and removes a column', () async {
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);

      cubit.toggleColumn(1);
      expect(cubit.state.checkedIndexes, <int>{1});
      expect(cubit.state.canVerify, isFalse);

      cubit.toggleColumn(0);
      expect(cubit.state.checkedIndexes, <int>{0, 1});
      expect(cubit.state.canVerify, isTrue);

      cubit.toggleColumn(1);
      expect(cubit.state.checkedIndexes, <int>{0});
      expect(cubit.state.canVerify, isFalse);
      await cubit.close();
    });
  });

  group('verify', () {
    test('PUTs only checked columns and keeps them checked', () async {
      buildAdapter(stats: {'verified_aspects': 0, 'total_aspects': 3});
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);

      expect(cubit.pendingPutEntries().keys, ['0']);
      final error = await cubit.verify();

      expect(error, isNull);
      expect(adapter.qualityPuts, hasLength(1));
      expect(adapter.qualityPuts.first, {
        'entries': {
          '0': {
            'text': {'score': 10, 'model': 'human'},
            'audio': {'score': 10, 'model': 'human'},
          },
        },
      });
      expect(cubit.state.busy, isFalse);
      await cubit.close();
    });

    test(
      'signs off only the checked column when others are empty or out of range',
      () async {
        adapter = FakeQaApiAdapter(
          factIds: const ['fact-1', 'fact-2'],
          entriesByFactId: {
            'fact-1': [
              {'text': 'headword', 'audio': 'aud-1'},
              {},
              {'text': 'extra'},
            ],
            'fact-2': [
              {'text': 'second'},
            ],
          },
          stats: {'verified_aspects': 0, 'total_aspects': 3},
        );
        networkDioClient.dio.httpClientAdapter = adapter;
        final cubit = QaModeCubit(
          deckId: 'imp-1',
          deckFieldCount: 4,
          isOnline: () async => true,
        );
        await cubit.startWalk({0, 1, 3});
        cubit.toggleColumn(0);

        expect(await cubit.verify(), isNull);

        // Only the checked column is signed off; no cursor columns are sent.
        expect(adapter.qualityPuts.single.containsKey('columns'), isFalse);
        expect(adapter.qualityPuts.single['entries'], {
          '0': {
            'text': {'score': 10, 'model': 'human'},
            'audio': {'score': 10, 'model': 'human'},
          },
        });
        await cubit.close();
      },
    );

    test('re-reads the record and clears the checkboxes', () async {
      buildAdapter(
        qualityByFactId: {
          'fact-1': {
            '1': {
              'text': {'score': 10, 'model': 'human'},
            },
          },
        },
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);
      cubit.toggleColumn(1);

      expect(await cubit.verify(), isNull);

      expect(cubit.state.quality, isNotNull);
      expect(cubit.state.checkedIndexes, isEmpty);
      await cubit.close();
    });

    test('clears checkboxes when the record cannot be re-read', () async {
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(1);

      expect(await cubit.verify(), isNull);

      expect(cubit.state.quality, isNull);
      expect(cubit.state.checkedIndexes, isEmpty);
      expect(cubit.state.busy, isFalse);
      await cubit.close();
    });

    test(
      'clears busy when header refresh fails after a successful PUT',
      () async {
        buildAdapter(
          qualityByFactId: {
            'fact-1': {
              '0': {
                'text': {'score': 10, 'model': 'human'},
              },
            },
          },
        );
        final cubit = QaModeCubit(
          deckId: 'imp-1',
          deckFieldCount: 2,
          isOnline: () async => true,
        );
        await startWalk(cubit);
        cubit.toggleColumn(0);
        cubit.debugFailNextRefreshHeader = true;

        expect(await cubit.verify(), isNull);

        expect(adapter.qualityPuts, hasLength(1));
        expect(cubit.state.busy, isFalse);
        expect(cubit.state.checkedIndexes, isEmpty);
        expect(cubit.state.quality, isNotNull);
        await cubit.close();
      },
    );

    test('returns the API message and clears busy on failure', () async {
      buildAdapter(qualityPutFails: true);
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);

      expect(await cubit.verify(), 'fact not in pinned snapshot');
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.checkedIndexes, <int>{0});
      await cubit.close();
    });

    test('returns a network error offline without calling the API', () async {
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => false,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);

      expect(await cubit.verify(), 'Connect error');
      expect(adapter.qualityPuts, isEmpty);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.checkedIndexes, <int>{0});
      await cubit.close();
    });

    test('a failing connectivity check does not block verify', () async {
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () => Future<bool>.error(StateError('plugin')),
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);

      expect(await cubit.verify(), isNull);
      expect(adapter.qualityPuts, hasLength(1));
      await cubit.close();
    });

    test(
      'is busy during the connectivity check and rejects re-entry',
      () async {
        final gate = Completer<bool>();
        final cubit = QaModeCubit(
          deckId: 'imp-1',
          deckFieldCount: 2,
          isOnline: () => gate.future,
        );
        await startWalk(cubit);
        cubit.toggleColumn(0);

        final first = cubit.verify();
        expect(cubit.state.busy, isTrue);
        expect(await cubit.verify(), isNull);

        gate.complete(true);
        expect(await first, isNull);
        expect(adapter.qualityPuts, hasLength(1));
        await cubit.close();
      },
    );

    test('stops when closed during the connectivity check', () async {
      final gate = Completer<bool>();
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () => gate.future,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);

      final pending = cubit.verify();
      await cubit.close();
      gate.complete(true);

      expect(await pending, isNull);
      expect(adapter.qualityPuts, isEmpty);
    });

    test(
      'abandons when the fact changes during the connectivity check',
      () async {
        buildAdapter(
          factIds: const ['fact-1', 'fact-2', 'fact-3'],
          stats: {'verified_aspects': 0, 'total_aspects': 3},
        );
        final gate = Completer<bool>();
        final cubit = QaModeCubit(
          deckId: 'imp-1',
          deckFieldCount: 2,
          isOnline: () => gate.future,
        );
        await startWalk(cubit);
        expect(cubit.state.factId, 'fact-1');
        cubit.toggleColumn(0);
        adapter.verifiedFactIds.add('fact-1'); // verified on another device

        final walk = cubit.startWalk({0});
        final pending = cubit.verify();
        await walk;
        expect(cubit.state.factId, 'fact-2');
        gate.complete(true);

        expect(await pending, isNull);
        expect(adapter.qualityPuts, isEmpty);
        expect(cubit.state.busy, isFalse);
        await cubit.close();
      },
    );

    test('does nothing without checked columns', () async {
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);

      expect(await cubit.verify(), isNull);
      expect(adapter.qualityPuts, isEmpty);
      await cubit.close();
    });

    test('does nothing before facts are loaded', () async {
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      expect(await cubit.verify(), isNull);
      expect(await cubit.submitEdit(), isNull);
      expect(adapter.qualityPuts, isEmpty);
      await cubit.close();
    });
  });

  group('submitEdit', () {
    test('reloads overlay text and counters after FactEdit', () async {
      final entries = <String, List<Map<String, dynamic>>>{
        'fact-1': [
          {'text': 'headword', 'audio': 'aud-1'},
          {'text': 'meaning'},
        ],
        'fact-2': [
          {'text': 'second'},
        ],
      };
      adapter = FakeQaApiAdapter(
        factIds: const ['fact-1', 'fact-2'],
        entriesByFactId: entries,
        stats: {'verified_aspects': 0, 'total_aspects': 3, 'edited_count': 0},
      );
      networkDioClient.dio.httpClientAdapter = adapter;

      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      expect(cubit.state.entries.first.text, 'headword');
      expect(cubit.state.editedCount, 0);

      // Simulate overlay already saved by FactEdit before onSaved refresh.
      entries['fact-1'] = [
        {'text': 'updated headword', 'audio': 'aud-1'},
        {'text': 'meaning'},
      ];
      adapter.stats = {
        'verified_aspects': 0,
        'total_aspects': 3,
        'edited_count': 1,
      };

      final error = await cubit.submitEdit(entryIndex: 0);

      expect(error, isNull);
      expect(adapter.contributionPosts, isEmpty);
      expect(cubit.state.entries.first.text, 'updated headword');
      expect(cubit.state.editedCount, 1);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.loading, isFalse);
      await cubit.close();
    });

    test('clears busy and loading when header refresh fails', () async {
      buildAdapter();
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.debugFailNextRefreshHeader = true;

      expect(await cubit.submitEdit(entryIndex: 0), isNull);

      expect(cubit.state.busy, isFalse);
      expect(cubit.state.loading, isFalse);
      await cubit.close();
    });
  });

  group('refreshStats', () {
    test('loads column stats into state', () async {
      buildAdapter(
        stats: {
          'columns': {
            '0': {'verified_aspects': 1, 'total_aspects': 4},
          },
        },
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );

      await cubit.refreshStats();

      expect(cubit.state.stats?.columnAt(0)?.completionPercent, 25);
      await cubit.close();
    });

    test('keeps the last edited count when stats cannot be loaded', () async {
      buildAdapter(
        stats: {'verified_aspects': 1, 'total_aspects': 4, 'edited_count': 2},
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await cubit.refreshStats();
      expect(cubit.state.editedCount, 2);

      adapter.stats = null;
      await cubit.refreshStats();

      expect(cubit.state.stats?.verifiedAspects, 1);
      expect(cubit.state.editedCount, 2);
      await cubit.close();
    });
  });

  group('column filter', () {
    test('initialColumnSelection restores saved indexes', () async {
      await QaColumnPrefs.save('imp-1', {1});
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      expect(await cubit.initialColumnSelection(), {1});
      await cubit.close();
    });

    test('only active columns are required for verify', () async {
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await cubit.startWalk({0});

      cubit.toggleColumn(0);
      expect(cubit.state.canVerify, isTrue);

      cubit.toggleColumn(1);
      expect(cubit.state.checkedIndexes, <int>{0});
      await cubit.close();
    });

    test('verify preserves quality on inactive columns', () async {
      buildAdapter(
        qualityByFactId: {
          'fact-1': {
            '1': {
              'text': {'score': 10, 'model': 'human'},
            },
          },
        },
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await cubit.startWalk({0});
      cubit.toggleColumn(0);

      await cubit.verify();

      expect(adapter.qualityPuts.single['entries'], {
        '0': {
          'text': {'score': 10, 'model': 'human'},
          'audio': {'score': 10, 'model': 'human'},
        },
        '1': {
          'text': {'score': 10, 'model': 'human'},
        },
      });
      await cubit.close();
    });

    test('reopening the picker refetches only unverified facts', () async {
      buildAdapter(factIds: const ['fact-1', 'fact-2', 'fact-3']);
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      cubit.toggleColumn(0);
      cubit.toggleColumn(1);
      await cubit.next();

      cubit.reopenColumnPicker();
      expect(cubit.state.pickingColumns, isTrue);
      expect(cubit.state.index, 1);

      await cubit.startWalk({0, 1});
      expect(cubit.state.pickingColumns, isFalse);
      expect(cubit.state.factIds, ['fact-2', 'fact-3']);
      expect(cubit.state.index, 0);
      expect(cubit.state.entries.first.text, 'second');
      await cubit.close();
    });

    test('a restart picks up facts verified on another device', () async {
      buildAdapter(factIds: const ['fact-1', 'fact-2', 'fact-3']);
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      expect(cubit.state.factIds, hasLength(3));

      adapter.verifiedFactIds.addAll({'fact-1', 'fact-2'});
      cubit.reopenColumnPicker();
      await cubit.startWalk({0});

      expect(adapter.unverifiedColumnsQueries.last, '0');
      expect(cubit.state.factIds, ['fact-3']);
      expect(cubit.state.entries.first.text, 'third');
      await cubit.close();
    });

    test('keeps loaded stats when a column-switch refetch fails', () async {
      buildAdapter(
        factIds: const ['fact-1', 'fact-2', 'fact-3'],
        stats: {'verified_aspects': 2, 'total_aspects': 4, 'edited_count': 3},
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      expect(cubit.state.editedCount, 3);

      adapter.stats = null;
      cubit.reopenColumnPicker();
      await cubit.startWalk({0});

      expect(cubit.state.stats?.verifiedAspects, 2);
      expect(cubit.state.stats?.totalAspects, 4);
      expect(cubit.state.editedCount, 3);
      expect(cubit.state.index, 0);
      expect(cubit.state.entries.first.text, 'headword');
      await cubit.close();
    });

    test('column switch to a finished set opens walk complete', () async {
      buildAdapter(
        factIds: const ['fact-1', 'fact-2'],
        stats: {'verified_aspects': 0, 'total_aspects': 3},
      );
      final cubit = QaModeCubit(
        deckId: 'imp-1',
        deckFieldCount: 2,
        isOnline: () async => true,
      );
      await startWalk(cubit);
      expect(cubit.state.walkComplete, isFalse);

      adapter.stats = {
        'verified_aspects': 3,
        'total_aspects': 3,
        'edited_count': 1,
      };
      adapter.verifiedFactIds.addAll({'fact-1', 'fact-2'});
      cubit.reopenColumnPicker();
      await cubit.startWalk({0, 1});

      expect(cubit.state.walkComplete, isTrue);
      expect(cubit.state.editedCount, 1);
      expect(cubit.state.fact, isNull);
      await cubit.close();
    });

    test(
      'startWalk stops when the cubit is closed while saving columns',
      () async {
        final cubit = QaModeCubit(
          deckId: 'imp-1',
          deckFieldCount: 2,
          isOnline: () async => true,
        );
        final pending = cubit.startWalk({0, 1});
        await cubit.close();
        await pending;

        expect(cubit.state.factIds, isEmpty);
        expect(cubit.state.pickingColumns, isTrue);
      },
    );
  });
}
