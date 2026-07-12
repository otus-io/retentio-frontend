import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/catalog_deck.dart';
import 'package:retentio/screen/decks/deck_text_styles.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_icon_button.dart';

/// 社区共享卡组列表卡片（v2 — 4行固定骨架，无语言方向）。
///
/// 行结构：
///   ① [已导入/已下架?] 标题               [♡]
///   ② {N}词 · {相对时间}
///   ③ @{owner}
///   ④ 标签行 OR 描述兜底（可选）   chevron ›
class SharedCatalogDeckCard extends StatelessWidget {
  const SharedCatalogDeckCard({
    super.key,
    required this.deck,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    this.isImported = false,
    this.isUnavailable = false,
  });

  final CatalogDeck deck;
  final bool isFavorite;

  /// 用户已导入该卡组。
  final bool isImported;

  /// 收藏筛选专用：卡组已从 catalog 下架（404）。
  final bool isUnavailable;

  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  // ── helpers ──────────────────────────────────────────────────────────────

  String _relativeTime(BuildContext context) {
    final dt = deck.publishedAt;
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}年前';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}个月前';
    if (diff.inDays >= 1) return '${diff.inDays}天前';
    if (diff.inHours >= 1) return '${diff.inHours}小时前';
    return '刚刚';
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final time = _relativeTime(context);

    return Semantics(
      label: '${deck.name}，${deck.factCount}词，${deck.owner}发布',
      button: true,
      child: InkWell(
        onTap: isUnavailable ? null : onTap,
        borderRadius: AppThemeTokens.borderRadiusXl,
        splashColor: scheme.primary.withValues(alpha: 0.07),
        highlightColor: scheme.primary.withValues(alpha: 0.05),
        splashFactory: InkRipple.splashFactory,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: AppThemeTokens.borderRadiusXl,
            color: scheme.surfaceContainerHighest,
            border: Border.all(
              color: isImported
                  ? scheme.primary.withValues(alpha: 0.35)
                  : scheme.outline.withValues(alpha: 0.18),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row ①: badge + title + favorite ──────────────────────────
              Row(
                children: [
                  if (isImported || isUnavailable) ...[
                    _StatusBadge(
                      label: isUnavailable ? '已下架' : '已导入',
                      isImported: isImported,
                      scheme: scheme,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DeckTextStyles.deckTitle(theme)?.copyWith(
                        color: isUnavailable
                            ? scheme.onSurface.withValues(alpha: 0.4)
                            : null,
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: AppIconButton(
                      variant: AppIconButtonVariant.subtle,
                      icon: LucideIcons.heart,
                      color: isFavorite
                          ? scheme.error
                          : scheme.onSurface.withValues(alpha: 0.38),
                      tooltip: isFavorite ? '取消收藏' : '收藏',
                      onPressed: onFavoriteToggle,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── Row ②: fact count · relative time ────────────────────────
              Text(
                [
                  loc.discoveryDetailFactCount(deck.factCount),
                  if (time.isNotEmpty) time,
                ].join(' · '),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isUnavailable
                      ? scheme.onSurface.withValues(alpha: 0.35)
                      : scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 3),
              // ── Row ③: @owner ─────────────────────────────────────────────
              Text(
                '@${deck.owner}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              // ── Row ④ (optional): tags / description / chevron ───────────
              if (deck.deckTagNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                _BottomRow(
                  tagNames: deck.deckTagNames,
                  scheme: scheme,
                  theme: theme,
                ),
              ] else if ((deck.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deck.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.52),
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: scheme.onSurface.withValues(alpha: 0.28),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.isImported,
    required this.scheme,
  });

  final String label;
  final bool isImported;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final bg = isImported
        ? scheme.primaryContainer
        : scheme.outline.withValues(alpha: 0.14);
    final fg = isImported
        ? scheme.onPrimaryContainer
        : scheme.onSurface.withValues(alpha: 0.55);

    return Semantics(
      label: isImported ? '已导入到我的卡组' : '该卡组已下架',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppThemeTokens.borderRadiusPill,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: fg,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow({
    required this.tagNames,
    required this.scheme,
    required this.theme,
  });

  static const int _maxVisible = 2;

  final List<String> tagNames;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final visible = tagNames.take(_maxVisible).toList();
    final overflow = tagNames.length - _maxVisible;

    return Row(
      children: [
        ...visible.map(
          (name) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _StringTagChip(name: name, scheme: scheme, theme: theme),
          ),
        ),
        if (overflow > 0) ...[
          Text(
            '+$overflow',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
        const Spacer(),
        Icon(
          LucideIcons.chevronRight,
          size: 14,
          color: scheme.onSurface.withValues(alpha: 0.28),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _StringTagChip extends StatelessWidget {
  const _StringTagChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppThemeTokens.borderRadiusPill,
      ),
      child: Text(
        name,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
