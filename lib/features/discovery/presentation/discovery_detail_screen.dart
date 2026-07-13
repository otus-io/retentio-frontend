import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart'
    as feature_auth;
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';
import 'package:retentio/features/discovery/bloc/discovery_detail_cubit.dart';
import 'package:retentio/features/discovery/data/discovery_favorites_repository.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/catalog_deck.dart';
import 'package:retentio/providers/main_tab_provider.dart';
import 'package:retentio/routers/routers.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_icon_button.dart';
import 'package:retentio/widgets/app_toast.dart';
import 'package:retentio/core/di/app_service_locator.dart';

class DiscoveryDetailScreen extends StatefulWidget {
  const DiscoveryDetailScreen({super.key, required this.sourceDeckId});

  final String sourceDeckId;

  @override
  State<DiscoveryDetailScreen> createState() => _DiscoveryDetailScreenState();
}

class _DiscoveryDetailScreenState extends State<DiscoveryDetailScreen> {
  late final DiscoveryDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = DiscoveryDetailCubit(
      favoritesRepository: DiscoveryFavoritesRepository(),
    );
    _cubit.load(widget.sourceDeckId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  bool get _isLoggedIn {
    if (!sl.isRegistered<feature_auth.AuthBloc>()) return false;
    return sl<feature_auth.AuthBloc>().state.status == AuthStatus.authenticated;
  }

  void _onImportTap(AppLocalizations loc) {
    if (!_isLoggedIn) {
      context.push(AppRoutes.login.path);
      return;
    }
    _cubit.importDeck();
  }

  void _showImportSuccess(BuildContext context, AppLocalizations loc) {
    AppToast.success(context, loc.discoveryImportSuccess);
  }

  Future<void> _goToImportedDeckStudy() async {
    final importResult = _cubit.state.importResult;
    final container = ProviderScope.containerOf(context, listen: false);
    if (importResult == null) {
      if (mounted) {
        container.read(selectedTabIndexProvider.notifier).setIndex(0);
        container.read(deckListRefreshSignalProvider.notifier).increment();
        context.go(AppRoutes.main.path);
      }
      return;
    }

    if (!mounted) return;
    container.read(selectedTabIndexProvider.notifier).setIndex(0);
    container.read(deckListRefreshSignalProvider.notifier).increment();
    context.go(AppRoutes.main.path);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocProvider<DiscoveryDetailCubit>.value(
      value: _cubit,
      child: BlocListener<DiscoveryDetailCubit, DiscoveryDetailState>(
        listenWhen: (prev, curr) =>
            prev.importStatus != curr.importStatus &&
            curr.importStatus == ImportStatus.imported,
        listener: (context, state) => _showImportSuccess(context, loc),
        child: Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            actions: [
              BlocBuilder<DiscoveryDetailCubit, DiscoveryDetailState>(
                buildWhen: (p, c) => p.isFavorite != c.isFavorite,
                builder: (context, state) {
                  return AppIconButton(
                    icon: LucideIcons.heart,
                    color: state.isFavorite
                        ? scheme.error
                        : scheme.onSurface.withValues(alpha: 0.4),
                    tooltip: state.isFavorite
                        ? loc.discoveryUnfavorite
                        : loc.discoveryFavorite,
                    onPressed: _cubit.toggleFavorite,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: BlocBuilder<DiscoveryDetailCubit, DiscoveryDetailState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Center(
                  child: CircularProgressIndicator(color: scheme.primary),
                );
              }

              if (state.error != null || state.deck == null) {
                return _ErrorView(
                  message: ApiErrorMessages.resolve(state.error, loc),
                  onRetry: () => _cubit.load(widget.sourceDeckId),
                  loc: loc,
                  scheme: scheme,
                );
              }

              return _DetailBody(
                deck: state.deck!,
                importState: state,
                loc: loc,
                theme: theme,
                scheme: scheme,
                onImportTap: () => _onImportTap(loc),
                onGoStudy: _goToImportedDeckStudy,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.deck,
    required this.importState,
    required this.loc,
    required this.theme,
    required this.scheme,
    required this.onImportTap,
    required this.onGoStudy,
  });

  final CatalogDeck deck;
  final DiscoveryDetailState importState;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onImportTap;
  final Future<void> Function() onGoStudy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  deck.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                // 作者
                Row(
                  children: [
                    Icon(
                      LucideIcons.user,
                      size: 14,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '@${deck.owner}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 统计行
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: LucideIcons.layersPlus,
                      label: loc.discoveryDetailFactCount(deck.factCount),
                      scheme: scheme,
                      theme: theme,
                    ),
                    _MetaChip(
                      icon: LucideIcons.clock,
                      label: deck.publishedAt != null
                          ? _formatDate(deck.publishedAt!)
                          : '—',
                      scheme: scheme,
                      theme: theme,
                    ),
                    _MetaChip(
                      icon: LucideIcons.globe,
                      label: 'v${deck.publishedVersion}',
                      scheme: scheme,
                      theme: theme,
                    ),
                  ],
                ),
                if (deck.fields.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionLabel(
                    label: loc.discoveryDetailFields,
                    theme: theme,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: deck.fields
                        .map(
                          (f) =>
                              _FieldPill(name: f, scheme: scheme, theme: theme),
                        )
                        .toList(),
                  ),
                ],
                if (deck.deckTagNames.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionLabel(label: loc.tags, theme: theme, scheme: scheme),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: deck.deckTagNames
                        .map(
                          (t) =>
                              _TagPill(name: t, scheme: scheme, theme: theme),
                        )
                        .toList(),
                  ),
                ],
                if ((deck.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionLabel(
                    label: loc.discoveryDetailDescription,
                    theme: theme,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deck.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // ── 底部主按钮 ───────────────────────────────────────────────────────
        _BottomAction(
          importState: importState,
          loc: loc,
          scheme: scheme,
          theme: theme,
          onImportTap: onImportTap,
          onGoStudy: onGoStudy,
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
        '-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.importState,
    required this.loc,
    required this.scheme,
    required this.theme,
    required this.onImportTap,
    required this.onGoStudy,
  });

  final DiscoveryDetailState importState;
  final AppLocalizations loc;
  final ColorScheme scheme;
  final ThemeData theme;
  final VoidCallback onImportTap;
  final VoidCallback onGoStudy;

  @override
  Widget build(BuildContext context) {
    final isImported = importState.importStatus == ImportStatus.imported;
    final isImporting = importState.importStatus == ImportStatus.importing;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (importState.importError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorText(importState.importError!, loc),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          AppButton(
            label: isImported
                ? loc.discoveryGoStudy
                : isImporting
                ? loc.discoveryImporting
                : loc.discoveryImport,
            isLoading: isImporting,
            fullWidth: true,
            onPressed: isImporting
                ? null
                : isImported
                ? () => onGoStudy()
                : onImportTap,
          ),
        ],
      ),
    );
  }

  String _errorText(String error, AppLocalizations loc) {
    return ApiErrorMessages.resolve(error, loc);
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.theme,
    required this.scheme,
  });

  final String label;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.5),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.scheme,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppThemeTokens.borderRadiusSm,
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.18),
          width: AppThemeTokens.borderWidthHairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldPill extends StatelessWidget {
  const _FieldPill({
    required this.name,
    required this.scheme,
    required this.theme,
  });

  final String name;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: AppThemeTokens.borderRadiusPill,
      ),
      child: Text(
        name,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.name,
    required this.scheme,
    required this.theme,
  });

  final String name;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppThemeTokens.borderRadiusPill,
      ),
      child: Text(
        name,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.loc,
    required this.scheme,
  });

  final String message;
  final VoidCallback onRetry;
  final AppLocalizations loc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.triangleAlert, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(loc.discoveryRetry)),
          ],
        ),
      ),
    );
  }
}
