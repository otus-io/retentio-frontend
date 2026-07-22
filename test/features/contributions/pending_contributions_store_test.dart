import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PendingContributionsStore', () {
    test('upsert replaces same id and counts pending', () async {
      final store = PendingContributionsStore.of;
      await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.edit,
        factId: 'f1',
        preview: 'Apple',
      );
      await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.edit,
        factId: 'f1',
        preview: 'Orange',
      );
      final pending = await store.listPending('imp1');
      expect(pending, hasLength(1));
      expect(pending.first.preview, 'Orange');
      expect(await store.countPending('imp1'), 1);
    });

    test('markAsSent moves pending to sent history', () async {
      final store = PendingContributionsStore.of;
      await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.add,
        factId: 'f2',
        preview: 'New',
      );
      final id = store.itemId(PendingContributionKind.add, factId: 'f2');
      await store.markAsSent('imp1', id, contributionId: 'c1');
      expect(await store.listPending('imp1'), isEmpty);
      final sent = await store.listSent('imp1');
      expect(sent, hasLength(1));
      expect(sent.first.contributionId, 'c1');
      expect(sent.first.kind, PendingContributionKind.add);
    });

    test('previewFromEntryTexts truncates long text', () {
      final short = PendingContributionsStore.previewFromEntryTexts(['hi']);
      expect(short, 'hi');
      final long = PendingContributionsStore.previewFromEntryTexts(['a' * 100]);
      expect(long!.endsWith('…'), isTrue);
      expect(long.length, lessThanOrEqualTo(80));
    });
  });
}
