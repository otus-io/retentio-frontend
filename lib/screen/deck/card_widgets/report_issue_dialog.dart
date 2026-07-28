import 'package:flutter/material.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';
import 'package:retentio/widgets/app_toast.dart';

enum ReportIssueKind { audio, content, other }

/// Importer report for a fact on an imported deck (message-only contribution).
Future<void> showReportIssueDialog({
  required BuildContext context,
  required String importDeckId,
  required String factId,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ReportIssueDialog(
      importDeckId: importDeckId,
      factId: factId,
      pageContext: context,
    ),
  );
}

class _ReportIssueDialog extends StatefulWidget {
  const _ReportIssueDialog({
    required this.importDeckId,
    required this.factId,
    required this.pageContext,
  });

  final String importDeckId;
  final String factId;
  final BuildContext pageContext;

  @override
  State<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<_ReportIssueDialog> {
  ReportIssueKind _kind = ReportIssueKind.audio;
  final _detailsController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  String _kindLabel(AppLocalizations loc, ReportIssueKind kind) {
    return switch (kind) {
      ReportIssueKind.audio => loc.reportIssueAudio,
      ReportIssueKind.content => loc.reportIssueContent,
      ReportIssueKind.other => loc.reportIssueOther,
    };
  }

  String? _buildMessage(AppLocalizations loc) {
    final details = _detailsController.text.trim();
    if (_kind == ReportIssueKind.other) {
      if (details.isEmpty) return null;
      return details;
    }
    final label = _kindLabel(loc, _kind);
    if (details.isEmpty) return label;
    return '$label: $details';
  }

  Future<void> _onSubmit() async {
    final loc = AppLocalizations.of(context)!;
    final message = _buildMessage(loc);
    if (message == null) {
      AppToast.show(context, loc.reportIssueDetailsRequired);
      return;
    }
    setState(() => _submitting = true);
    try {
      await DeckCatalogService.of.submitFactReport(
        importDeckId: widget.importDeckId,
        factId: widget.factId,
        message: message,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final pageContext = widget.pageContext;
      if (pageContext.mounted) {
        AppToast.success(pageContext, loc.reportIssueSuccess);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        ApiErrorMessages.resolve(rawApiErrorMessage(e), loc),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final detailsRequired = _kind == ReportIssueKind.other;

    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: Text(loc.reportIssue),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<ReportIssueKind>(
              initialValue: _kind,
              decoration: InputDecoration(labelText: loc.reportIssueCategory),
              items: [
                for (final kind in ReportIssueKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(_kindLabel(loc, kind)),
                  ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _kind = value);
                    },
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _detailsController,
              hint: detailsRequired
                  ? loc.reportIssueOtherHint
                  : loc.reportIssueDetailsHint,
              maxLines: 4,
              minLines: 3,
              maxLength: 200,
              enabled: !_submitting,
            ),
          ],
        ),
        actions: [
          AppButton(
            label: loc.cancel,
            variant: AppButtonVariant.ghost,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
          AppButton(
            label: loc.reportIssueSubmit,
            variant: AppButtonVariant.primary,
            isLoading: _submitting,
            onPressed: _submitting ? null : _onSubmit,
          ),
        ],
      ),
    );
  }
}
