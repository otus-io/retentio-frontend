import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';

/// Outcome of auto-submitting an importer fact edit (and optional tag diff).
class ImportedFactContributionSubmitResult {
  const ImportedFactContributionSubmitResult({
    required this.sentCount,
    required this.failures,
  });

  final int sentCount;
  final List<String> failures;

  bool get allSucceeded => failures.isEmpty;
  bool get partialSuccess => sentCount > 0 && failures.isNotEmpty;
}

/// Stages then immediately submits `fact_edit` (and `fact_tag_update` when
/// [addTagNames]/[removeTagNames] are non-empty). Failures leave pending rows.
Future<ImportedFactContributionSubmitResult>
submitImportedFactEditContributions({
  required String importDeckId,
  required String factId,
  String? preview,
  List<String> addTagNames = const [],
  List<String> removeTagNames = const [],
  String? message,
  int? entryIndex,
  PendingContributionsStore? store,
  DeckCatalogService? catalog,
}) async {
  final s = store ?? PendingContributionsStore.of;
  final c = catalog ?? DeckCatalogService.of;
  final hasTagDiff = addTagNames.isNotEmpty || removeTagNames.isNotEmpty;

  await s.upsert(
    deckId: importDeckId,
    kind: PendingContributionKind.edit,
    factId: factId,
    preview: preview,
  );

  if (hasTagDiff) {
    await s.upsert(
      deckId: importDeckId,
      kind: PendingContributionKind.factTags,
      factId: factId,
      addTags: addTagNames,
      removeTags: removeTagNames,
      preview: preview,
    );
  }

  final failures = <String>[];
  var sentCount = 0;

  try {
    final contributionId = await c.submitFactEditContribution(
      importDeckId: importDeckId,
      factId: factId,
      message: message,
      entryIndex: entryIndex,
    );
    await s.markAsSent(
      importDeckId,
      s.itemId(PendingContributionKind.edit, factId: factId),
      contributionId: contributionId,
      message: message,
    );
    sentCount += 1;
  } catch (e) {
    failures.add(rawApiErrorMessage(e));
  }

  if (hasTagDiff) {
    try {
      final contributionId = await c.submitFactTagsContribution(
        importDeckId: importDeckId,
        factId: factId,
        addTags: addTagNames,
        removeTags: removeTagNames,
        message: message,
      );
      await s.markAsSent(
        importDeckId,
        s.itemId(PendingContributionKind.factTags, factId: factId),
        contributionId: contributionId,
        message: message,
      );
      sentCount += 1;
    } catch (e) {
      failures.add(rawApiErrorMessage(e));
    }
  }

  return ImportedFactContributionSubmitResult(
    sentCount: sentCount,
    failures: failures,
  );
}

/// Stages then immediately submits a `fact_add` for an importer's new local
/// fact. Returns whether it reached the author; on failure the pending row
/// stays in the unsent list for retry.
Future<bool> submitImportedFactAddContribution({
  required String importDeckId,
  required String factId,
  String? preview,
  PendingContributionsStore? store,
  DeckCatalogService? catalog,
}) async {
  final s = store ?? PendingContributionsStore.of;
  final c = catalog ?? DeckCatalogService.of;
  await s.upsert(
    deckId: importDeckId,
    kind: PendingContributionKind.add,
    factId: factId,
    preview: preview,
  );
  try {
    final contributionId = await c.submitFactAddContribution(
      importDeckId: importDeckId,
      factId: factId,
    );
    await s.markAsSent(
      importDeckId,
      s.itemId(PendingContributionKind.add, factId: factId),
      contributionId: contributionId,
    );
    return true;
  } catch (_) {
    return false;
  }
}

/// Tail of the in-flight deck-tag send per import deck, so sends for one deck
/// run one at a time and each marks only its own staged row as sent.
final _deckTagSends = <String, Future<void>>{};

/// Stages then immediately submits a `deck_tag_update` for an import deck.
/// Returns whether it reached the author; on failure the pending row stays in
/// the unsent list for retry.
///
/// An earlier unsent change is folded into this one (see [mergeTagDeltas])
/// instead of being overwritten, and the merged change is what gets sent.
Future<bool> submitImportedDeckTagsContribution({
  required String importDeckId,
  required List<String> addTags,
  required List<String> removeTags,
  PendingContributionsStore? store,
  DeckCatalogService? catalog,
}) {
  final previous = _deckTagSends[importDeckId] ?? Future<void>.value();
  final run = previous.then(
    (_) => _sendDeckTags(
      importDeckId: importDeckId,
      addTags: addTags,
      removeTags: removeTags,
      store: store ?? PendingContributionsStore.of,
      catalog: catalog ?? DeckCatalogService.of,
    ),
  );
  final tail = run.then<void>((_) {}, onError: (Object _) {});
  _deckTagSends[importDeckId] = tail;
  tail.whenComplete(() {
    if (identical(_deckTagSends[importDeckId], tail)) {
      _deckTagSends.remove(importDeckId);
    }
  });
  return run;
}

/// Folds a new tag change into an earlier unsent one. A tag added then
/// removed (or the reverse) cancels out.
({List<String> add, List<String> remove}) mergeTagDeltas({
  required Iterable<String> priorAdd,
  required Iterable<String> priorRemove,
  required Iterable<String> add,
  required Iterable<String> remove,
}) {
  final newAdd = add.toSet();
  final newRemove = remove.toSet();
  final oldAdd = priorAdd.toSet();
  final oldRemove = priorRemove.toSet();
  return (
    add: {
      ...oldAdd.difference(newRemove),
      ...newAdd.difference(oldRemove),
    }.toList(),
    remove: {
      ...oldRemove.difference(newAdd),
      ...newRemove.difference(oldAdd),
    }.toList(),
  );
}

Future<bool> _sendDeckTags({
  required String importDeckId,
  required List<String> addTags,
  required List<String> removeTags,
  required PendingContributionsStore store,
  required DeckCatalogService catalog,
}) async {
  final pendingId = store.itemId(PendingContributionKind.deckTags);
  final unsent = (await store.listPending(
    importDeckId,
  )).where((row) => row.id == pendingId).firstOrNull;
  final delta = mergeTagDeltas(
    priorAdd: unsent?.addTags ?? const [],
    priorRemove: unsent?.removeTags ?? const [],
    add: addTags,
    remove: removeTags,
  );
  if (delta.add.isEmpty && delta.remove.isEmpty) {
    // This change undid the unsent one: nothing is left to tell the author.
    await store.remove(importDeckId, pendingId);
    return true;
  }
  await store.upsert(
    deckId: importDeckId,
    kind: PendingContributionKind.deckTags,
    addTags: delta.add,
    removeTags: delta.remove,
  );
  try {
    final contributionId = await catalog.submitDeckTagsContribution(
      importDeckId: importDeckId,
      addTags: delta.add,
      removeTags: delta.remove,
    );
    await store.markAsSent(
      importDeckId,
      pendingId,
      contributionId: contributionId,
    );
    return true;
  } catch (_) {
    return false;
  }
}
