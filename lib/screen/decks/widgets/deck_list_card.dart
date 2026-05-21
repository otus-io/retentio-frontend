import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/decks/deck_text_styles.dart';
import 'package:retentio/theme/theme_tokens.dart';

import '../../../routers/routers.dart';

class DeckListCard extends StatelessWidget {
  final Deck deck;

  const DeckListCard({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        context.push(
          AppRoutes.study.path,
          extra: {'deck': deck, 'deckListCubit': context.read<DeckListCubit>()},
        );
      },
      borderRadius: AppThemeTokens.borderRadiusXl,
      splashColor: scheme.primary.withValues(alpha: 0.07),
      highlightColor: scheme.primary.withValues(alpha: 0.05),
      splashFactory: InkRipple.splashFactory,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: AppThemeTokens.borderRadiusXl,
          color: scheme.surfaceContainerHighest,
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.18),
            width: AppThemeTokens.borderWidthHairline,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deck.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DeckTextStyles.deckTitle(theme),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${deck.totalCards} ${loc.cards}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatBox(
                  value: deck.stats.unseenCards.toString(),
                  label: loc.newCards,
                  color: scheme.primary,
                  theme: theme,
                  scheme: scheme,
                ),
                const SizedBox(width: 8),
                _StatBox(
                  value: deck.reviewCards.toString(),
                  label: loc.dueCards,
                  color: scheme.secondary,
                  theme: theme,
                  scheme: scheme,
                ),
                const SizedBox(width: 8),
                _StatBox(
                  value: deck.stats.factsCount.toString(),
                  label: loc.facts,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  theme: theme,
                  scheme: scheme,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: AppThemeTokens.borderRadiusPill,
              child: LinearProgressIndicator(
                value: deck.progress / 100,
                minHeight: 6,
                backgroundColor: scheme.outline.withValues(alpha: 0.28),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.progress, style: DeckTextStyles.progressLabel(theme)),
                Text(
                  '${deck.learnedCards}/${deck.totalCards} (${deck.progress.toStringAsFixed(0)}%)',
                  style: DeckTextStyles.progressValue(theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.theme,
    required this.scheme,
  });

  final String value;
  final String label;
  final Color color;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isZero = value == '0';
    final effectiveColor = isZero
        ? scheme.onSurface.withValues(alpha: 0.3)
        : color;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: isZero ? 0.04 : 0.08),
          borderRadius: AppThemeTokens.borderRadiusSm,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
