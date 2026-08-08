import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/services/apis/deck_catalog_service.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';
import 'package:retentio/widgets/app_toast.dart';
import 'package:retentio/widgets/common_bottom_sheet.dart';

enum ReportIssueKind { audio, content, other }

/// Importer report for a fact on an imported deck (message-only contribution).
Future<void> showReportIssueDialog({
  required BuildContext context,
  required String importDeckId,
  required String factId,
}) {
  return showCommonBottomSheet<void>(
    context: context,
    title: AppLocalizations.of(context)!.reportIssue,
    initialChildSize: 0.62,
    minChildSize: 0.45,
    maxChildSize: 0.92,
    routeSettings: const RouteSettings(name: 'report-issue-sheet'),
    child: _ReportIssueForm(
      importDeckId: importDeckId,
      factId: factId,
      pageContext: context,
    ),
  );
}

class _ReportIssueForm extends StatefulWidget {
  const _ReportIssueForm({
    required this.importDeckId,
    required this.factId,
    required this.pageContext,
  });

  final String importDeckId;
  final String factId;
  final BuildContext pageContext;

  @override
  State<_ReportIssueForm> createState() => _ReportIssueFormState();
}

class _ReportIssueFormState extends State<_ReportIssueForm> {
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

  IconData _kindIcon(ReportIssueKind kind) {
    return switch (kind) {
      ReportIssueKind.audio => LucideIcons.volume2,
      ReportIssueKind.content => LucideIcons.fileText,
      ReportIssueKind.other => LucideIcons.circleHelp,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detailsRequired = _kind == ReportIssueKind.other;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppThemeTokens.borderRadiusMd,
              ),
              child: Icon(
                LucideIcons.flag,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.reportIssueCategory,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final kind in ReportIssueKind.values) ...[
              if (kind != ReportIssueKind.values.first)
                const SizedBox(width: 8),
              Expanded(
                child: _KindTile(
                  label: _kindLabel(loc, kind),
                  icon: _kindIcon(kind),
                  selected: _kind == kind,
                  enabled: !_submitting,
                  onTap: () => setState(() => _kind = kind),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        AppInput(
          controller: _detailsController,
          hint: detailsRequired
              ? loc.reportIssueOtherHint
              : loc.reportIssueDetailsHint,
          maxLines: 4,
          minLines: 3,
          maxLength: 200,
          enabled: !_submitting,
          textAlignVertical: TextAlignVertical.top,
        ),
        const SizedBox(height: 20),
        AppButton(
          label: loc.reportIssueSubmit,
          variant: AppButtonVariant.primary,
          fullWidth: true,
          isLoading: _submitting,
          onPressed: _submitting ? null : _onSubmit,
          leading: const Icon(LucideIcons.send, size: 16),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: loc.cancel,
          variant: AppButtonVariant.ghost,
          fullWidth: true,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: 0.55);
    final bg = selected ? scheme.primary : Colors.transparent;
    final borderColor = selected
        ? scheme.primary
        : scheme.outline.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      borderRadius: AppThemeTokens.borderRadiusMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppThemeTokens.borderRadiusMd,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
