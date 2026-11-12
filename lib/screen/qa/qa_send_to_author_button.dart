import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_toast.dart';

/// Sends the importer's QA sign-offs to the deck author as a `qa_review`
/// request, so the author can adopt them for the catalog badge.
class QaSendToAuthorButton extends StatefulWidget {
  const QaSendToAuthorButton({super.key, required this.importDeckId});

  final String importDeckId;

  @override
  State<QaSendToAuthorButton> createState() => _QaSendToAuthorButtonState();
}

class _QaSendToAuthorButtonState extends State<QaSendToAuthorButton> {
  bool _sending = false;

  Future<void> _send() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _sending = true);
    try {
      final summary = await DeckCatalogService.of.submitQAReview(
        importDeckId: widget.importDeckId,
      );
      if (!mounted) return;
      AppToast.success(context, loc.qaReviewSent(summary.aspects));
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        ApiErrorMessages.resolve(rawApiErrorMessage(e), loc),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: loc.qaReviewSendToAuthor,
          fullWidth: true,
          variant: AppButtonVariant.secondary,
          leading: const Icon(LucideIcons.send),
          isLoading: _sending,
          onPressed: _sending ? null : _send,
        ),
        const SizedBox(height: 6),
        Text(
          loc.qaReviewSendHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
