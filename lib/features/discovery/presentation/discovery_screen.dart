import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/features/discovery/bloc/discovery_list_cubit.dart';
import 'package:retentio/features/discovery/presentation/widgets/shared_catalog_deck_card.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/providers/main_tab_provider.dart';
import 'package:retentio/routers/routers.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_input.dart';
import 'package:retentio/widgets/common_refresher.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  late final DiscoveryListCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = DiscoveryListCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(discoveryRefreshSignalProvider, (prev, next) {
      if (next != (prev ?? 0)) _cubit.onRefresh();
    });

    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider<DiscoveryListCubit>.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.discoveryTab),
          scrolledUnderElevation: 0,
        ),
        body: Column(
          children: [
            // ── 搜索框 ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AppInput(
                controller: _searchController,
                hint: loc.discoverySearchHint,
                prefix: const Icon(LucideIcons.search, size: 18),
                onChanged: _cubit.search,
              ),
            ),
            // ── 筛选切换 ─────────────────────────────────────────────────────
            BlocBuilder<DiscoveryListCubit, DiscoveryListState>(
              buildWhen: (prev, curr) => prev.filter != curr.filter,
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: loc.discoveryFilterLatest,
                        selected: state.filter == DiscoveryFilter.latest,
                        onTap: () => _cubit.setFilter(DiscoveryFilter.latest),
                        scheme: scheme,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: loc.discoveryFilterFavorites,
                        selected: state.filter == DiscoveryFilter.favorites,
                        onTap: () =>
                            _cubit.setFilter(DiscoveryFilter.favorites),
                        scheme: scheme,
                      ),
                    ],
                  ),
                );
              },
            ),
            // ── 列表 ─────────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<DiscoveryListCubit, DiscoveryListState>(
                buildWhen: (prev, curr) =>
                    prev.decks != curr.decks ||
                    prev.isLoading != curr.isLoading ||
                    prev.error != curr.error ||
                    prev.favoriteIds != curr.favoriteIds,
                builder: (context, state) {
                  if (state.isLoading && state.decks.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: scheme.primary),
                    );
                  }

                  if (state.error != null && state.decks.isEmpty) {
                    return _ErrorView(
                      message: ApiErrorMessages.resolve(state.error, loc),
                      onRetry: _cubit.onRefresh,
                      loc: loc,
                      scheme: scheme,
                    );
                  }

                  final emptyText = state.filter == DiscoveryFilter.favorites
                      ? loc.discoveryFavoritesEmpty
                      : loc.discoveryEmpty;

                  return CommonRefresher(
                    controller: _cubit.refreshController,
                    onRefresh: _cubit.onRefresh,
                    onLoading: _cubit.onLoading,
                    isEmpty: state.decks.isEmpty,
                    emptyView: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.inbox,
                              size: 54,
                              color: scheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(emptyText, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: state.decks.length,
                      itemBuilder: (context, index) {
                        final deck = state.decks[index];
                        final isFav = state.favoriteIds.contains(deck.id);
                        return Padding(
                          key: ValueKey(deck.id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SharedCatalogDeckCard(
                            deck: deck,
                            isFavorite: isFav,
                            onFavoriteToggle: () =>
                                _cubit.toggleFavorite(deck.id),
                            onTap: () => context.push(
                              AppRoutes.discoveryDetail.path.replaceFirst(
                                ':id',
                                deck.id,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  static const _kHeight = 32.0;
  static const _kHPad = 16.0;
  static const _kDuration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _kDuration,
        curve: Curves.easeInOut,
        height: _kHeight,
        padding: const EdgeInsets.symmetric(horizontal: _kHPad),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: AppThemeTokens.borderRadiusPill,
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: _kDuration,
            style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
              color: selected
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.55),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.1,
            ),
            child: Text(label),
          ),
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
