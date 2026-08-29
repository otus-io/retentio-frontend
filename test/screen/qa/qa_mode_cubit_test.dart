import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
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
      },
      qualityByFactId: qualityByFactId,
      mediaVersionsByFactId: mediaVersionsByFactId,
      stats: stats,
      qualityPutFails: qualityPutFails,
      contributionFails: contributionFails,
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

  group('load', () {
    test('loads the first fact and deck counters', () async {
      buildAdapter(stats: {'verified_aspects': 2, 'total_aspects': 6});
      final cubit = QaModeCubit(deckId: 'imp-1');

      await cubit.load();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.factIds, ['fact-1', 'fact-2']);
      expect(cubit.state.entries, hasLength(2));
      expect(cubit.state.stats?.verifiedAspects, 2);
      expect(cubit.state.hasPrev, isFalse);
      expect(cubit.state.hasNext, isTrue);
      expect(cubit.state.factLoadFailed, isFalse);
      await cubit.close();
    });

    test('resumes just past the last verified fact', () async {
      buildAdapter(stats: {'last_fact_id': 'fact-1'});
      final cubit = QaModeCubit(deckId: 'imp-1');

      await cubit.load();

      expect(cubit.state.index, 1);
      expect(cubit.state.entries.first.text, 'second');
      expect(cubit.state.hasPrev, isTrue);
      await cubit.close();
    });

    test('stays on the last fact when it was the one verified', () async {
      buildAdapter(stats: {'last_fact_id': 'fact-2'});
      final cubit = QaModeCubit(deckId: 'imp-1');

      await cubit.load();

      expect(cubit.state.index, 1);
      expect(cubit.state.hasNext, isFalse);
      await cubit.close();
    });

    test('falls back to the first fact when the cursor is unknown', () async {
      buildAdapter(stats: {'last_fact_id': 'ghost'});
      final cubit = QaModeCubit(deckId: 'imp-1');

      await cubit.load();

      expect(cubit.state.index, 0);
      expect(cubit.state.entries.first.text, 'headword');
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
      final cubit = QaModeCubit(deckId: 'imp-1');

      await cubit.load();

      expect(cubit.state.checkedIndexes, isEmpty);
      expect(cubit.state.canVerify, isFalse);
      await cubit.close();
    });

    test('renders the first fact after one page of ids', () async {
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
      final cubit = QaModeCubit(deckId: 'imp-1');

      final firstPaint = cubit.stream.firstWhere(
        (state) => !state.loading && state.fact != null,
      );
      final loaded = cubit.load();

      final painted = await firstPaint;
      expect(painted.factIds, hasLength(50));
      expect(adapter.factListOffsets, [0]);

      await loaded;
      expect(cubit.state.factIds, hasLength(450));
      expect(adapter.factListOffsets, [
        0,
        50,
        100,
        150,
        200,
        250,
        300,
        350,
        400,
        450,
      ]);
      await cubit.close();
    });

    test('loads snapshot media_versions for the current fact', () async {
      buildAdapter(
        mediaVersionsByFactId: {
          'fact-1': {'aud-1': 1},
        },
      );
      final cubit = QaModeCubit(deckId: 'imp-1');

      await cubit.load();

      expect(cubit.state.mediaVersions, {'aud-1': 1});
      await cubit.close();
    });

    test('stays empty when the deck has no facts', () async {
      buildAdapter(factIds: const []);
      final cubit = QaModeCubit(deckId: 'imp-1');

      await cubit.load();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.factIds, isEmpty);
      expect(cubit.state.factLoadFailed, isFalse);
      await cubit.close();
    });

    test('flags a fact that cannot be loaded', () async {
      buildAdapter(factIds: const ['missing']);
      final cubit = QaModeCubit(deckId: 'imp-1');

      await cubit.load();

      expect(cubit.state.factLoadFailed, isTrue);
      expect(cubit.state.canVerify, isFalse);
      await cubit.close();
    });
  });

  group('navigation', () {
    test('next and prev walk the fact list', () async {
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();

      await cubit.next();
      expect(cubit.state.index, 1);
      expect(cubit.state.entries.first.text, 'second');
      expect(cubit.state.hasNext, isFalse);

      await cubit.prev();
      expect(cubit.state.index, 0);
      await cubit.close();
    });

    test('auto-signs the checked columns before advancing', () async {
      buildAdapter(stats: {'verified_aspects': 0, 'total_aspects': 3});
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();
      cubit.toggleColumn(0);

      await cubit.next();

      expect(adapter.qualityPuts, hasLength(1));
      expect(cubit.state.index, 1);
      expect(cubit.state.checkedIndexes, isEmpty);
      await cubit.close();
    });

    test('ignores out-of-range targets', () async {
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();

      await cubit.prev();
      expect(cubit.state.index, 0);

      await cubit.goTo(9);
      expect(cubit.state.index, 0);
      await cubit.close();
    });
  });

  group('toggleColumn', () {
    test('adds and removes a column', () async {
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();

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
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();
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
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();
      cubit.toggleColumn(0);
      cubit.toggleColumn(1);

      expect(await cubit.verify(), isNull);

      expect(cubit.state.quality, isNotNull);
      expect(cubit.state.checkedIndexes, isEmpty);
      await cubit.close();
    });

    test('keeps state when the record cannot be re-read', () async {
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();
      cubit.toggleColumn(1);

      expect(await cubit.verify(), isNull);

      expect(cubit.state.quality, isNull);
      expect(cubit.state.checkedIndexes, <int>{1});
      expect(cubit.state.busy, isFalse);
      await cubit.close();
    });

    test('returns the API message and clears busy on failure', () async {
      buildAdapter(qualityPutFails: true);
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();
      cubit.toggleColumn(0);

      expect(await cubit.verify(), 'fact not in pinned snapshot');
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.checkedIndexes, <int>{0});
      await cubit.close();
    });

    test('does nothing without checked columns', () async {
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();

      expect(await cubit.verify(), isNull);
      expect(adapter.qualityPuts, isEmpty);
      await cubit.close();
    });

    test('does nothing before facts are loaded', () async {
      final cubit = QaModeCubit(deckId: 'imp-1');

      expect(await cubit.verify(), isNull);
      expect(await cubit.submitEdit(), isNull);
      expect(adapter.qualityPuts, isEmpty);
      await cubit.close();
    });
  });

  group('submitEdit', () {
    test('sends the overlay as fact_edit and clears the outbox row', () async {
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();
      await PendingContributionsStore.of.upsert(
        deckId: 'imp-1',
        kind: PendingContributionKind.edit,
        factId: 'fact-1',
        preview: 'headword',
      );

      final error = await cubit.submitEdit(entryIndex: 0);

      expect(error, isNull);
      expect(adapter.contributionPosts, hasLength(1));
      expect(adapter.contributionPosts.first, {
        'message': kQaEditMessage,
        'entry_index': 0,
      });
      expect(await PendingContributionsStore.of.listPending('imp-1'), isEmpty);
      expect(cubit.state.editedCount, 1);
      expect(cubit.state.busy, isFalse);
      await cubit.close();
    });

    test('returns the API message when the POST fails', () async {
      buildAdapter(contributionFails: true);
      final cubit = QaModeCubit(deckId: 'imp-1');
      await cubit.load();
      await PendingContributionsStore.of.upsert(
        deckId: 'imp-1',
        kind: PendingContributionKind.edit,
        factId: 'fact-1',
        preview: 'headword',
      );

      expect(
        await cubit.submitEdit(entryIndex: 1),
        'daily contribution limit exceeded',
      );
      expect(
        await PendingContributionsStore.of.listPending('imp-1'),
        hasLength(1),
      );
      expect(cubit.state.editedCount, 0);
      await cubit.close();
    });
  });
}
