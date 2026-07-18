import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/theme/theme_tokens.dart';

const double _kHomeHorizontalPadding = 16;
const double _kSecondaryTextAlpha = 0.76;
const double _kMutedTextAlpha = 0.72;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(loc.home)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          _kHomeHorizontalPadding,
          10,
          _kHomeHorizontalPadding,
          28,
        ),
        children: [
          _DailyGoalHeader(),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                loc.homeLearningPath,
                style: theme.textTheme.titleMedium?.copyWith(
                  letterSpacing: -0.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.5),
                  borderRadius: AppThemeTokens.borderRadiusPill,
                ),
                child: Text(
                  loc.homeToday,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _PathNode(
            title: 'Warm-up Review',
            subtitle: '5 due cards',
            state: _PathNodeState.done,
          ),
          const _PathNode(
            title: 'Core Practice',
            subtitle: '12 cards in progress',
            state: _PathNodeState.current,
          ),
          const _PathNode(
            title: 'Quick Challenge',
            subtitle: '3 mixed cards',
            state: _PathNodeState.locked,
            isLast: true,
          ),
          const SizedBox(height: 18),
          Text(
            loc.homeTodayFocus,
            style: theme.textTheme.titleMedium?.copyWith(letterSpacing: -0.1),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: AppThemeTokens.borderRadiusXl,
              border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
            ),
            child: Text(
              loc.homeTodayFocusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: _kSecondaryTextAlpha),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppThemeTokens.borderRadiusXl,
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppThemeTokens.borderRadiusSm,
                ),
                child: const Icon(
                  LucideIcons.flame,
                  color: Colors.deepOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                loc.homeDailyGoal,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _GoalMetaPill(icon: LucideIcons.clock3, label: '12 min active'),
              _GoalMetaPill(icon: LucideIcons.target, label: '72% goal pace'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '18 / 25 cards completed',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: _kSecondaryTextAlpha),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppThemeTokens.borderRadiusPill,
            child: LinearProgressIndicator(
              minHeight: 8,
              value: 18 / 25,
              backgroundColor: scheme.outline.withValues(alpha: 0.45),
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMetaPill extends StatelessWidget {
  const _GoalMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.44),
        borderRadius: AppThemeTokens.borderRadiusPill,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PathNodeState { done, current, locked }

class _PathNode extends StatelessWidget {
  final String title;
  final String subtitle;
  final _PathNodeState state;
  final bool isLast;

  const _PathNode({
    required this.title,
    required this.subtitle,
    required this.state,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final icon = switch (state) {
      _PathNodeState.done => LucideIcons.check,
      _PathNodeState.current => LucideIcons.play,
      _PathNodeState.locked => LucideIcons.lock,
    };

    final iconColor = switch (state) {
      _PathNodeState.done => scheme.primary,
      _PathNodeState.current => scheme.secondary,
      _PathNodeState.locked => scheme.onSurface.withValues(alpha: 0.5),
    };

    final bubble = switch (state) {
      _PathNodeState.done => scheme.primary.withValues(alpha: 0.16),
      _PathNodeState.current => scheme.secondary.withValues(alpha: 0.2),
      _PathNodeState.locked => scheme.outline.withValues(alpha: 0.35),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: bubble,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 56,
                  color: scheme.outline.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
                borderRadius: AppThemeTokens.borderRadiusLg,
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.75),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: _kMutedTextAlpha,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
