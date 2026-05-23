import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/providers/locale_provider.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/screen/profile/bloc/profile_cubit.dart';
import 'package:retentio/screen/profile/profile_settings_dialogs.dart';
import 'package:retentio/screen/profile/widgets/profile_user_header.dart';
import 'package:retentio/theme/theme_tokens.dart';

const _kListBottomPadding = 24.0;
const _kHeaderToCardSpacing = 14.0;
const _kCardHorizontalMargin = AppThemeTokens.spaceLg;
const _kDividerHorizontalInset = AppThemeTokens.spaceLg;
const _kChevronSize = 16.0;
const _kSubtitleAlpha = 0.76;

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dividerTheme = theme.dividerTheme;
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);

    return BlocProvider<ProfileCubit>(
      create: (_) => ProfileCubit(),
      child: Builder(
        builder: (context) {
          final profileCubit = context.read<ProfileCubit>();
          return Scaffold(
            appBar: AppBar(title: Text(loc.profile)),
            body: ListView(
              padding: const EdgeInsets.only(bottom: _kListBottomPadding),
              children: [
                const ProfileUserHeader(),
                const SizedBox(height: _kHeaderToCardSpacing),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _kCardHorizontalMargin,
                  ),
                  child: Material(
                    color: scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppThemeTokens.borderRadiusXl,
                      side: BorderSide(
                        color: scheme.outline,
                        width: AppThemeTokens.borderWidthHairline,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _ProfileTileWidget(
                          icon: LucideIcons.globe,
                          title: loc.changeLanguage,
                          subtitle: profileLanguageDisplayName(currentLocale),
                          onTap: () => showProfileLanguageDialog(
                            context,
                            ref,
                            currentLocale,
                            loc,
                          ),
                        ),
                        Divider(
                          height: dividerTheme.space ?? 1,
                          indent: _kDividerHorizontalInset,
                          endIndent: _kDividerHorizontalInset,
                        ),
                        _ProfileTileWidget(
                          icon: LucideIcons.palette,
                          title: loc.changeTheme,
                          subtitle: profileThemeDisplayName(currentTheme, loc),
                          onTap: () => showProfileThemeDialog(
                            context,
                            ref,
                            currentTheme,
                            loc,
                          ),
                        ),
                        Divider(
                          height: dividerTheme.space ?? 1,
                          indent: _kDividerHorizontalInset,
                          endIndent: _kDividerHorizontalInset,
                        ),
                        _ProfileTileWidget(
                          icon: LucideIcons.logOut,
                          title: loc.logout,
                          titleColor: scheme.error,
                          iconColor: scheme.error,
                          onTap: () => showProfileLogoutDialog(
                            context,
                            profileCubit,
                            loc,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileTileWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileTileWidget({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? scheme.onSurface),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: titleColor ?? scheme.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: _kSubtitleAlpha),
              ),
            ),
      trailing: const Icon(LucideIcons.chevronRight, size: _kChevronSize),
      onTap: onTap,
    );
  }
}
