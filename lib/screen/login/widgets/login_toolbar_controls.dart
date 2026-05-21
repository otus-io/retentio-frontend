import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/providers/locale_provider.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_icon_button.dart';

const _kToolbarTopSpacing = 8.0;
const _kToolbarHorizontalInset = 14.0;
const _kThemeIconSize = 16.0;
const _kLanguagePaddingHorizontal = AppThemeTokens.spaceMd;
const _kDropdownIconSize = 14.0;

class LoginToolbarControls extends HookConsumerWidget {
  final bool isLoading;
  final bool isDark;
  final Animation<double>? appearAnimation;

  const LoginToolbarControls({
    super.key,
    required this.isLoading,
    required this.isDark,
    this.appearAnimation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final paddingTop = MediaQuery.of(context).padding.top;

    final toolbar = Positioned(
      top: paddingTop + _kToolbarTopSpacing,
      left: _kToolbarHorizontalInset,
      right: _kToolbarHorizontalInset,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppIconButton(
            icon: isDark ? LucideIcons.moonStar : LucideIcons.sunMedium,
            size: _kThemeIconSize,
            outlined: true,
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _kLanguagePaddingHorizontal,
            ),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.9),
              borderRadius: AppThemeTokens.borderRadiusS,
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.46),
                width: AppThemeTokens.borderWidthHairline,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: currentLocale,
                icon: const Icon(
                  LucideIcons.chevronDown,
                  size: _kDropdownIconSize,
                ),
                style: Theme.of(context).textTheme.labelMedium,
                borderRadius: AppThemeTokens.borderRadiusS,
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('EN')),
                  DropdownMenuItem(value: Locale('zh'), child: Text('中')),
                ],
                onChanged: isLoading
                    ? null
                    : (Locale? newLocale) {
                        if (newLocale != null) {
                          ref
                              .read(localeProvider.notifier)
                              .setLocale(newLocale);
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );

    if (appearAnimation == null) {
      return toolbar;
    }

    final opacity = CurvedAnimation(
      parent: appearAnimation!,
      curve: const Interval(0.45, 0.95, curve: Curves.easeOut),
    );
    final offsetAnim =
        Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: appearAnimation!,
            curve: const Interval(0.45, 0.95, curve: Curves.easeOutCubic),
          ),
        );

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: offsetAnim, child: toolbar),
    );
  }
}
