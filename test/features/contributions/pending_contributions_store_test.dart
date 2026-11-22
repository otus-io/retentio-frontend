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

    test('updateMessage changes only the note of the stored row', () async {
      final store = PendingContributionsStore.of;
      await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.description,
        proposedDescription: 'Old',
        message: 'old note',
      );
      await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.edit,
        factId: 'f1',
      );
      final before = await store.listPending('imp1');
      final id = store.itemId(PendingContributionKind.description);

      final returned = await store.updateMessage('imp1', id, 'new note');

      final after = await store.listPending('imp1');
      expect(after.map((r) => r.id), before.map((r) => r.id));
      final row = after.singleWhere((r) => r.id == id);
      expect(row.message, 'new note');
      expect(returned!.message, 'new note');
      expect(row.proposedDescription, 'Old');
      expect(row.savedAt, before.singleWhere((r) => r.id == id).savedAt);
      expect(after.singleWhere((r) => r.id != id).message, isNull);
    });

    test('updateMessage ignores a row that is gone', () async {
      final store = PendingContributionsStore.of;
      expect(await store.updateMessage('imp1', 'missing', 'note'), isNull);
      expect(await store.listPending('imp1'), isEmpty);
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

    test('markAsSent keeps a row re-staged during the send', () async {
      final store = PendingContributionsStore.of;
      final submitted = (await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.description,
        preview: 'Old',
        proposedDescription: 'Old',
      )).single;
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.description,
        preview: 'New',
        proposedDescription: 'New',
      );

      await store.markAsSent('imp1', submitted.id, submitted: submitted);

      expect((await store.listPending('imp1')).single.preview, 'New');
      expect((await store.listSent('imp1')).single.preview, 'Old');
    });

    test('markAsSent removes the submitted version of a row', () async {
      final store = PendingContributionsStore.of;
      final submitted = (await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.description,
        preview: 'Old',
      )).single;

      await store.markAsSent('imp1', submitted.id, submitted: submitted);

      expect(await store.listPending('imp1'), isEmpty);
      expect((await store.listSent('imp1')).single.preview, 'Old');
    });

    test('markAsSent records a submitted row removed meanwhile', () async {
      final store = PendingContributionsStore.of;
      final submitted = (await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.description,
        preview: 'Old',
      )).single;
      await store.clearPending('imp1');

      await store.markAsSent('imp1', submitted.id, submitted: submitted);

      expect((await store.listSent('imp1')).single.preview, 'Old');
    });

    test('concurrent changes to one deck all persist', () async {
      final store = PendingContributionsStore.of;
      await Future.wait([
        for (final f in ['f1', 'f2', 'f3'])
          store.upsert(
            deckId: 'imp1',
            kind: PendingContributionKind.edit,
            factId: f,
          ),
        store.upsert(
          deckId: 'imp2',
          kind: PendingContributionKind.edit,
          factId: 'f1',
        ),
      ]);

      expect(await store.countPending('imp1'), 3);
      expect(await store.countPending('imp2'), 1);
    });

    test('a failed change does not block later ones', () async {
      SharedPreferences.setMockInitialValues({
        'retentio_pending_contribs_v2:imp1': 1,
      });
      final store = PendingContributionsStore.of;

      await expectLater(store.remove('imp1', 'x'), throwsA(isA<TypeError>()));
      await store.clearPending('imp1');

      expect(await store.listPending('imp1'), isEmpty);
    });

    test('description rows are one per deck and keep their text', () async {
      final store = PendingContributionsStore.of;
      await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.description,
        proposedDescription: 'First',
      );
      await store.upsert(
        deckId: 'imp1',
        kind: PendingContributionKind.description,
        proposedDescription: 'Second',
      );
      final pending = await store.listPending('imp1');
      expect(pending.single.id, 'description');
      expect(pending.single.kind, PendingContributionKind.description);
      expect(pending.single.proposedDescription, 'Second');
    });

    test('previewFromEntryTexts truncates long text', () {
      final short = PendingContributionsStore.previewFromEntryTexts(['hi']);
      expect(short, 'hi');
      final long = PendingContributionsStore.previewFromEntryTexts([
        List.filled(100, 'a').join(),
      ]);
      expect(long!.endsWith('…'), isTrue);
      expect(long.length, lessThanOrEqualTo(80));
    });
  });
}
