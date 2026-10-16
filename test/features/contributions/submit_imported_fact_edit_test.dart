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
}
