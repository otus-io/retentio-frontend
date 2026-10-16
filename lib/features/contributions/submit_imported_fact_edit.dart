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
