import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/features/offline_learning/presentation/offline_logout_guard.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retentio/providers/locale_provider.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/screen/profile/bloc/profile_cubit.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';

const _kDialogOptionPadding = EdgeInsets.symmetric(horizontal: 2);

String profileLanguageDisplayName(Locale locale, AppLocalizations loc) {
  switch (locale.languageCode) {
    case 'zh':
      return loc.languageChinese;
    case 'ja':
      return loc.languageJapanese;
    case 'en':
      return loc.languageEnglish;
    default:
      return locale.languageCode;
  }
}

String profileThemeDisplayName(AppThemeMode theme, AppLocalizations loc) {
  return switch (theme) {
    AppThemeMode.light => loc.themeLight,
    AppThemeMode.dark => loc.themeDark,
    AppThemeMode.sepia => loc.themeSepia,
    AppThemeMode.system => loc.themeSystem,
  };
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
          options: [
            _RadioOption(value: Locale('en'), label: loc.languageEnglish),
            _RadioOption(value: Locale('zh'), label: loc.languageChinese),
            _RadioOption(value: Locale('ja'), label: loc.languageJapanese),
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
  AppThemeMode currentTheme,
  AppLocalizations loc,
) async {
  final selected = await showGeneralDialog<AppThemeMode>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        _ProfileRadioDialog<AppThemeMode>(
          title: loc.changeTheme,
          groupValue: currentTheme,
          options: [
            _RadioOption(value: AppThemeMode.light, label: loc.themeLight),
            _RadioOption(value: AppThemeMode.dark, label: loc.themeDark),
            _RadioOption(value: AppThemeMode.sepia, label: loc.themeSepia),
            _RadioOption(value: AppThemeMode.system, label: loc.themeSystem),
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
  final outerContext = context;
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
          onPressed: () async {
            context.pop();
            if (await settleOfflineDataBeforeLogout(outerContext)) {
              await profileCubit.logout();
            }
          },
        ),
      ],
    ),
  );
}

Future<void> showProfileDeleteAccountDialog(
  BuildContext context,
  ProfileCubit profileCubit,
) async {
  final deleted = await showDialog<bool>(
    context: context,
    builder: (_) => _DeleteAccountDialog(profileCubit: profileCubit),
  );
  if (deleted == true) {
    await profileCubit.logout();
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.profileCubit});

  final ProfileCubit profileCubit;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.profileCubit.deleteAccount(_password.text);
    } catch (_) {
      error = 'Unknown error';
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _loading = false;
      _error = error == 'Invalid credentials'
          ? loc.deleteAccountWrongPassword
          : ApiErrorMessages.resolve(error, loc);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
        title: Text(loc.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.deleteAccountMessage),
            const SizedBox(height: AppThemeTokens.spaceMd),
            AppInput(
              controller: _password,
              label: loc.password,
              obscureText: true,
              enabled: !_loading,
              errorText: _error,
              onChanged: (_) => setState(() => _error = null),
            ),
          ],
        ),
        actions: [
          AppButton(
            label: loc.cancel,
            variant: AppButtonVariant.ghost,
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
          ),
          AppButton(
            label: loc.deleteAccount,
            variant: AppButtonVariant.danger,
            isLoading: _loading,
            onPressed: _password.text.isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
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
