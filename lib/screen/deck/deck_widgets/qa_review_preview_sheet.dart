import 'package:flutter/material.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/qa_review_preview.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/widgets/app_button.dart';

/// Author view of a `qa_review` request: which importer sign-offs can still be
/// adopted, and which no longer match the author's deck.
class QaReviewPreviewSheet extends StatefulWidget {
  const QaReviewPreviewSheet({
    super.key,
    required this.sourceDeckId,
    required this.contributionId,
    required this.fieldLabel,
  });

  final String sourceDeckId;
  final String contributionId;

  /// Column name for an entry index.
  final String Function(int entry) fieldLabel;

  @override
  State<QaReviewPreviewSheet> createState() => _QaReviewPreviewSheetState();
}

class _QaReviewPreviewSheetState extends State<QaReviewPreviewSheet> {
  QAReviewPreview? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _preview = null;
      _error = null;
    });
    try {
      final preview = await DeckCatalogService.of.getQAReviewPreview(
        sourceDeckId: widget.sourceDeckId,
        contributionId: widget.contributionId,
      );
      if (mounted) setState(() => _preview = preview);
    } catch (e) {
      if (mounted) setState(() => _error = rawApiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ApiErrorMessages.resolve(_error!, loc),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppButton(label: loc.retry, onPressed: _load),
        ],
      );
    }
    final preview = _preview;
    if (preview == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (preview.facts.isEmpty) {
      return Center(child: Text(loc.qaReviewNoFields));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.qaReviewPreviewSummary(
            preview.count(QAReviewItemStatus.ready),
            preview.total,
          ),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        for (final fact in preview.facts)
          _QaReviewFactRow(fact: fact, fieldLabel: widget.fieldLabel),
      ],
    );
  }
}

class _QaReviewFactRow extends StatelessWidget {
  const _QaReviewFactRow({required this.fact, required this.fieldLabel});

  final QAReviewPreviewFact fact;
  final String Function(int entry) fieldLabel;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.preview.isEmpty ? fact.factId : fact.preview,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final a in fact.aspects)
            Text(
              '${fieldLabel(a.entry)} · ${_aspectLabel(loc, a.aspect)} — '
              '${qaReviewStatusLabel(loc, a.status)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: a.status == QAReviewItemStatus.ready
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  static String _aspectLabel(AppLocalizations loc, String aspect) =>
      aspect == 'audio' ? loc.qaReviewAspectAudio : loc.qaReviewAspectText;
}

/// Localized label for a `qa_review` item status.
String qaReviewStatusLabel(AppLocalizations loc, QAReviewItemStatus status) =>
    switch (status) {
      QAReviewItemStatus.ready => loc.qaReviewStatusReady,
      QAReviewItemStatus.changed => loc.qaReviewStatusChanged,
      QAReviewItemStatus.verified => loc.qaReviewStatusVerified,
      QAReviewItemStatus.removed => loc.qaReviewStatusRemoved,
    };
