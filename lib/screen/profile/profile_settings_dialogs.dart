import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retentio/providers/locale_provider.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/screen/profile/bloc/profile_cubit.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';

const _kDialogOptionPadding = EdgeInsets.symmetric(horizontal: 2);

String profileLanguageDisplayName(Locale locale) {
  switch (locale.languageCode) {
    case 'zh':
      return '简体中文';
    case 'en':
      return 'English';
    default:
      return locale.languageCode;
  }
}

String profileThemeDisplayName(ThemeMode theme, AppLocalizations loc) {
  switch (theme) {
    case ThemeMode.light:
      return loc.themeLight;
    case ThemeMode.dark:
      return loc.themeDark;
    case ThemeMode.system:
      return loc.themeSystem;
  }
}

Future<void> showProfileLanguageDialog(
  BuildContext context,
  WidgetRef ref,
  Locale currentLocale,
  AppLocalizations loc,
) async {
  final selected = await showGeneralDialog<Locale>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        _ProfileRadioDialog<Locale>(
          title: loc.changeLanguage,
          groupValue: currentLocale,
          options: const [
            _RadioOption(value: Locale('en'), label: 'English'),
            _RadioOption(value: Locale('zh'), label: '简体中文'),
          ],
          onChanged: (value) {
            Navigator.of(dialogContext).pop(value);
          },
        ),
  );

  if (selected != null) {
    ref.read(localeProvider.notifier).setLocale(selected);
  }
}

Future<void> showProfileThemeDialog(
  BuildContext context,
  WidgetRef ref,
  ThemeMode currentTheme,
  AppLocalizations loc,
) async {
  final selected = await showGeneralDialog<ThemeMode>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        _ProfileRadioDialog<ThemeMode>(
          title: loc.changeTheme,
          groupValue: currentTheme,
          options: [
            _RadioOption(value: ThemeMode.light, label: loc.themeLight),
            _RadioOption(value: ThemeMode.dark, label: loc.themeDark),
            _RadioOption(value: ThemeMode.system, label: loc.themeSystem),
          ],
          onChanged: (value) {
            Navigator.of(dialogContext).pop(value);
          },
        ),
  );

  if (selected != null) {
    ref.read(themeModeProvider.notifier).setThemeMode(selected);
  }
}

void showProfileLogoutDialog(
  BuildContext context,
  ProfileCubit profileCubit,
  AppLocalizations loc,
) {
  showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc.logoutConfirmTitle),
      content: Text(loc.logoutConfirmMessage),
      actions: [
        AppButton(
          label: loc.cancel,
          onPressed: () {
            context.pop();
          },
          variant: AppButtonVariant.ghost,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            textStyle: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        AppButton(
          label: loc.logout,
          variant: AppButtonVariant.secondary,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: AppThemeTokens.borderWidthHairline,
            ),
            textStyle: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          onPressed: () {
            context.pop();
            profileCubit.logout();
          },
        ),
      ],
    ),
  );
}

class _ProfileRadioDialog<T> extends StatelessWidget {
  final String title;
  final T groupValue;
  final List<_RadioOption<T>> options;
  final ValueChanged<T> onChanged;

  const _ProfileRadioDialog({
    required this.title,
    required this.groupValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: RadioGroup<T>(
        groupValue: groupValue,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          onChanged(value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              RadioListTile<T>(
                value: option.value,
                title: Text(option.label),
                contentPadding: _kDialogOptionPadding,
              ),
          ],
        ),
      ),
    );
  }
}

class _RadioOption<T> {
  final T value;
  final String label;

  const _RadioOption({required this.value, required this.label});
}
