import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/providers/locale_provider.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/screen/profile/providers/profile.dart';

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

void showProfileLanguageDialog(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations loc,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc.changeLanguage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioGroup(
            onChanged: (value) {
              if (value != null) {
                ref.read(localeProvider.notifier).setLocale(value);
                Navigator.of(context).pop();
              }
            },
            groupValue: ref.read(localeProvider),
            child: RadioListTile<Locale>(
              title: const Text('English'),
              value: const Locale('en'),
            ),
          ),
          RadioGroup(
            groupValue: ref.read(localeProvider),
            onChanged: (value) {
              if (value != null) {
                ref.read(localeProvider.notifier).setLocale(value);
                Navigator.of(context).pop();
              }
            },
            child: RadioListTile<Locale>(
              title: const Text('简体中文'),
              value: const Locale('zh'),
            ),
          ),
        ],
      ),
    ),
  );
}

void showProfileThemeDialog(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations loc,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc.changeTheme),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioGroup(
            groupValue: ref.read(themeModeProvider),
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
                Navigator.of(context).pop();
              }
            },
            child: RadioListTile<ThemeMode>(
              title: Text(loc.themeLight),
              value: ThemeMode.light,
            ),
          ),
          RadioGroup(
            groupValue: ref.read(themeModeProvider),
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
                Navigator.of(context).pop();
              }
            },
            child: RadioListTile<ThemeMode>(
              title: Text(loc.themeDark),
              value: ThemeMode.dark,
            ),
          ),
          RadioGroup(
            groupValue: ref.read(themeModeProvider),
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
                Navigator.of(context).pop();
              }
            },
            child: RadioListTile<ThemeMode>(
              title: Text(loc.themeSystem),
              value: ThemeMode.system,
            ),
          ),
        ],
      ),
    ),
  );
}

void showProfileLogoutDialog(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations loc,
) {
  showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc.logoutConfirmTitle),
      content: Text(loc.logoutConfirmMessage),
      actions: [
        TextButton(
          onPressed: () {
            context.pop();
          },
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () {
            context.pop();
            ref.read(profileProvider.notifier).logout();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(loc.logout),
        ),
      ],
    ),
  );
}
