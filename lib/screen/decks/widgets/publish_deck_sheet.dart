import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/publish_preview.dart';
import 'package:retentio/providers/main_tab_provider.dart'
    show discoveryRefreshSignalProvider;
import 'package:retentio/services/apis/deck_publish_service.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';

enum _PublishStatus { idle, loading, success, error }

class PublishDeckSheet extends ConsumerStatefulWidget {
  const PublishDeckSheet({super.key, required this.deck, this.onPublished});

  final Deck deck;
  final VoidCallback? onPublished;

  @override
  ConsumerState<PublishDeckSheet> createState() => _PublishDeckSheetState();
}

class _PublishDeckSheetState extends ConsumerState<PublishDeckSheet> {
  _PublishStatus _status = _PublishStatus.idle;
  int? _publishedVersion;
  String? _error;
  PublishPreview? _preview;
  bool _previewLoading = false;

  bool get _isUpdate => widget.deck.isPublishedSource;

  @override
  void initState() {
    super.initState();
    if (_isUpdate) {
      _loadPreview();
    }
  }

  Future<void> _loadPreview() async {
    setState(() => _previewLoading = true);
    try {
      final preview = await DeckPublishService.of.getPublishPreview(
        widget.deck.id,
        detail: true,
      );
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (_) {
      // Non-fatal: sheet still allows publish.
    } finally {
      if (mounted) {
        setState(() => _previewLoading = false);
      }
    }
  }

  Future<void> _publish() async {
    setState(() {
      _status = _PublishStatus.loading;
      _error = null;
    });
    try {
      final result = await DeckPublishService.of.publishDeck(widget.deck.id);
      if (!mounted) return;
      setState(() {
        _status = _PublishStatus.success;
        _publishedVersion = result.publishedVersion;
      });
      widget.onPublished?.call();
      ref.read(discoveryRefreshSignalProvider.notifier).increment();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _PublishStatus.error;
        _error = rawApiErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = _isUpdate ? loc.publishDeckUpdate : loc.publishDeck;
    final actionLabel = _status == _PublishStatus.loading
        ? loc.publishingDeck
        : (_isUpdate ? loc.publishDeckUpdate : loc.publishDeckAction);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  LucideIcons.share2,
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_status == _PublishStatus.success) ...[
            _SuccessBanner(
              version: _publishedVersion ?? 1,
              loc: loc,
              scheme: scheme,
              theme: theme,
            ),
          ] else ...[
            if (_isUpdate) ...[
              if (_previewLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    loc.publishingDeck,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                )
              else if (_preview != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _preview!.summaryLine(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                ),
            ] else
              Text(
                loc.publishDeckHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.68),
                  height: 1.5,
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                ApiErrorMessages.resolve(_error, loc),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: actionLabel,
              isLoading: _status == _PublishStatus.loading,
              fullWidth: true,
              onPressed: _status == _PublishStatus.loading ? null : _publish,
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({
    required this.version,
    required this.loc,
    required this.scheme,
    required this.theme,
  });

  final int version;
  final AppLocalizations loc;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: AppThemeTokens.borderRadiusLg,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
          width: AppThemeTokens.borderWidthHairline,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circleCheck, size: 22, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.publishDeckSuccess,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'v$version',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
