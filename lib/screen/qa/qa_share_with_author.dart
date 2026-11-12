import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/widgets/app_toast.dart';

/// Shares an importer's QA sign-offs with the deck author as a `qa_review`
/// request. Quiet unless it worked: with nothing transferable, offline, or an
/// older server, it does nothing and the next QA session tries again (the
/// request is rebuilt from the server's sign-offs each time).
Future<void> shareQaSignOffsWithAuthor(
  BuildContext context,
  String importDeckId,
) async {
  final loc = AppLocalizations.of(context)!;
  try {
    final summary = await DeckCatalogService.of.submitQAReview(
      importDeckId: importDeckId,
    );
    if (context.mounted) {
      AppToast.success(context, loc.qaReviewSent(summary.aspects));
    }
  } catch (_) {
    // Retried on the next close; see the doc comment.
  }
}
