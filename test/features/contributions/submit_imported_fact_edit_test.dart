import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
import 'package:retentio/features/contributions/submit_imported_fact_edit.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_fact_api_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFactApiInterceptor interceptor;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.clearToken();
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
    interceptor = attachFakeFactApiInterceptor();
  });

  tearDown(() {
    detachFakeFactApiInterceptor(interceptor);
  });

  group('submitImportedFactEditContributions', () {
    test('submits fact_edit and clears the pending row', () async {
      final result = await submitImportedFactEditContributions(
        importDeckId: 'imp-1',
        factId: 'fact-1',
        preview: 'Alpha',
        message: 'QA edit',
        entryIndex: 0,
      );

      expect(result.allSucceeded, isTrue);
      expect(result.sentCount, 1);
      expect(result.failures, isEmpty);
      expect(interceptor.contributionEditCount, 1);
      expect(interceptor.lastContributionEditBody, {
        'message': 'QA edit',
        'entry_index': 0,
      });
      expect(await PendingContributionsStore.of.listPending('imp-1'), isEmpty);
      expect(
        await PendingContributionsStore.of.listSent('imp-1'),
        hasLength(1),
      );
    });

    test('leaves pending when fact_edit submit fails', () async {
      detachFakeFactApiInterceptor(interceptor);
      interceptor = attachFakeFactApiInterceptor(contributionEditFails: true);

      final result = await submitImportedFactEditContributions(
        importDeckId: 'imp-1',
        factId: 'fact-1',
        preview: 'Alpha',
      );

      expect(result.allSucceeded, isFalse);
      expect(result.partialSuccess, isFalse);
      expect(result.sentCount, 0);
      expect(result.failures, ['daily contribution limit exceeded']);
      expect(
        await PendingContributionsStore.of.listPending('imp-1'),
        hasLength(1),
      );
    });

    test('also submits fact tags when tag names are provided', () async {
      final result = await submitImportedFactEditContributions(
        importDeckId: 'imp-1',
        factId: 'fact-1',
        preview: 'Alpha',
        addTagNames: const ['new'],
        removeTagNames: const ['old'],
      );

      expect(result.allSucceeded, isTrue);
      expect(result.sentCount, 2);
      expect(interceptor.contributionEditCount, 1);
      expect(interceptor.contributionTagsCount, 1);
      expect(await PendingContributionsStore.of.listPending('imp-1'), isEmpty);
      expect(
        await PendingContributionsStore.of.listSent('imp-1'),
        hasLength(2),
      );
    });

    test('reports partial success when tags fail after edit', () async {
      detachFakeFactApiInterceptor(interceptor);
      interceptor = attachFakeFactApiInterceptor(contributionTagsFails: true);

      final result = await submitImportedFactEditContributions(
        importDeckId: 'imp-1',
        factId: 'fact-1',
        preview: 'Alpha',
        addTagNames: const ['new'],
      );

      expect(result.partialSuccess, isTrue);
      expect(result.sentCount, 1);
      expect(result.failures, ['daily contribution limit exceeded']);
      expect(
        await PendingContributionsStore.of.listPending('imp-1'),
        hasLength(1),
      );
      expect(
        await PendingContributionsStore.of.listSent('imp-1'),
        hasLength(1),
      );
    });
  });

  group('ImportedFactContributionSubmitResult', () {
    test('flags allSucceeded and partialSuccess', () {
      expect(
        const ImportedFactContributionSubmitResult(
          sentCount: 2,
          failures: [],
        ).allSucceeded,
        isTrue,
      );
      expect(
        const ImportedFactContributionSubmitResult(
          sentCount: 1,
          failures: ['x'],
        ).partialSuccess,
        isTrue,
      );
      expect(
        const ImportedFactContributionSubmitResult(
          sentCount: 0,
          failures: ['x'],
        ).partialSuccess,
        isFalse,
      );
    });
  });

  group('submitImportedFactAddContribution', () {
    test('sends fact_add and moves the row to sent', () async {
      final ok = await submitImportedFactAddContribution(
        importDeckId: 'imp-1',
        factId: 'local-1',
        preview: 'Orange',
      );

      expect(ok, isTrue);
      expect(interceptor.contributionAddCount, 1);
      expect(await PendingContributionsStore.of.listPending('imp-1'), isEmpty);
      final sent = await PendingContributionsStore.of.listSent('imp-1');
      expect(sent.single.contributionId, 'cont-add-1');
    });

    test('keeps the row unsent when sending fails', () async {
      interceptor.contributionAddFails = true;

      final ok = await submitImportedFactAddContribution(
        importDeckId: 'imp-1',
        factId: 'local-1',
      );

      expect(ok, isFalse);
      final pending = await PendingContributionsStore.of.listPending('imp-1');
      expect(pending.single.kind, PendingContributionKind.add);
      expect(pending.single.factId, 'local-1');
    });
  });

  group('submitImportedDeckTagsContribution', () {
    test('sends deck_tag_update and moves the row to sent', () async {
      final ok = await submitImportedDeckTagsContribution(
        importDeckId: 'imp-1',
        addTags: const ['N5'],
        removeTags: const ['old'],
      );

      expect(ok, isTrue);
      expect(interceptor.contributionDeckTagsCount, 1);
      expect(await PendingContributionsStore.of.listPending('imp-1'), isEmpty);
      final sent = await PendingContributionsStore.of.listSent('imp-1');
      expect(sent.single.kind, PendingContributionKind.deckTags);
    });

    test('keeps the row unsent when sending fails', () async {
      interceptor.contributionDeckTagsFails = true;

      final ok = await submitImportedDeckTagsContribution(
        importDeckId: 'imp-1',
        addTags: const ['N5'],
        removeTags: const [],
      );

      expect(ok, isFalse);
      final pending = await PendingContributionsStore.of.listPending('imp-1');
      expect(pending.single.kind, PendingContributionKind.deckTags);
      expect(pending.single.addTags, ['N5']);
    });

    test('folds an earlier unsent change into the next send', () async {
      interceptor.contributionDeckTagsFails = true;
      await submitImportedDeckTagsContribution(
        importDeckId: 'imp-1',
        addTags: const ['N5'],
        removeTags: const ['old'],
      );
      interceptor.contributionDeckTagsFails = false;

      final ok = await submitImportedDeckTagsContribution(
        importDeckId: 'imp-1',
        addTags: const ['N4'],
        removeTags: const [],
      );

      expect(ok, isTrue);
      final body = interceptor.contributionDeckTagsBodies.last as Map;
      expect(body['add_tags'], unorderedEquals(['N5', 'N4']));
      expect(body['remove_tags'], ['old']);
      expect(await PendingContributionsStore.of.listPending('imp-1'), isEmpty);
    });

    test('undoing an unsent change clears it without a request', () async {
      interceptor.contributionDeckTagsFails = true;
      await submitImportedDeckTagsContribution(
        importDeckId: 'imp-1',
        addTags: const ['N5'],
        removeTags: const [],
      );
      interceptor.contributionDeckTagsFails = false;

      final ok = await submitImportedDeckTagsContribution(
        importDeckId: 'imp-1',
        addTags: const [],
        removeTags: const ['N5'],
      );

      expect(ok, isTrue);
      expect(interceptor.contributionDeckTagsCount, 1);
      expect(await PendingContributionsStore.of.listPending('imp-1'), isEmpty);
    });

    test('overlapping sends for a deck run one at a time', () async {
      final results = await Future.wait([
        submitImportedDeckTagsContribution(
          importDeckId: 'imp-1',
          addTags: const ['N5'],
          removeTags: const [],
        ),
        submitImportedDeckTagsContribution(
          importDeckId: 'imp-1',
          addTags: const ['N4'],
          removeTags: const [],
        ),
      ]);

      expect(results, [isTrue, isTrue]);
      final bodies = interceptor.contributionDeckTagsBodies;
      expect((bodies[0] as Map)['add_tags'], ['N5']);
      expect((bodies[1] as Map)['add_tags'], ['N4']);
      expect(await PendingContributionsStore.of.listPending('imp-1'), isEmpty);
      final sent = await PendingContributionsStore.of.listSent('imp-1');
      expect(sent, hasLength(2));
    });
  });

  group('mergeTagDeltas', () {
    test('keeps both changes and cancels opposites', () {
      final merged = mergeTagDeltas(
        priorAdd: const ['a', 'b'],
        priorRemove: const ['x', 'y'],
        add: const ['c', 'x'],
        remove: const ['b', 'z'],
      );

      expect(merged.add, unorderedEquals(['a', 'c']));
      expect(merged.remove, unorderedEquals(['y', 'z']));
    });
  });
}
