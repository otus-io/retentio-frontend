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

/// Stages then immediately submits a `deck_tag_update` for an import deck.
/// Returns whether it reached the author; on failure the pending row stays in
/// the unsent list for retry.
Future<bool> submitImportedDeckTagsContribution({
  required String importDeckId,
  required List<String> addTags,
  required List<String> removeTags,
  PendingContributionsStore? store,
  DeckCatalogService? catalog,
}) async {
  final s = store ?? PendingContributionsStore.of;
  final c = catalog ?? DeckCatalogService.of;
  await s.upsert(
    deckId: importDeckId,
    kind: PendingContributionKind.deckTags,
    addTags: addTags,
    removeTags: removeTags,
  );
  try {
    final contributionId = await c.submitDeckTagsContribution(
      importDeckId: importDeckId,
      addTags: addTags,
      removeTags: removeTags,
    );
    await s.markAsSent(
      importDeckId,
      s.itemId(PendingContributionKind.deckTags),
      contributionId: contributionId,
    );
    return true;
  } catch (_) {
    return false;
  }
}
