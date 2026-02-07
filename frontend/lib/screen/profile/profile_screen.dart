import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordupx/l10n/app_localizations.dart';
import 'package:wordupx/providers/theme_provider.dart';
import 'package:wordupx/providers/locale_provider.dart';

import '../../services/apis/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc.profile)),
      body: ListView(
        children: [
          // 用户信息卡片
          _buildUserProfileHeader(),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // 语言设置
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.changeLanguage),
            subtitle: Text(_getLanguageDisplayName(currentLocale)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context, ref, loc),
          ),
          const Divider(),

          // 主题设置
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(loc.changeTheme),
            subtitle: Text(_getThemeDisplayName(currentTheme, loc)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showThemeDialog(context, ref, loc),
          ),
          const Divider(),

          // 退出登录
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(loc.logout, style: const TextStyle(color: Colors.red)),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.red,
            ),
            onTap: () => _showLogoutDialog(context, loc),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader() {
    const String username = 'Mango'; // 暂时写死

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              username[0].toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 用户名
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$username',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '简体中文';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }

  String _getThemeDisplayName(ThemeMode theme, AppLocalizations loc) {
    switch (theme) {
      case ThemeMode.light:
        return loc.themeLight;
      case ThemeMode.dark:
        return loc.themeDark;
      case ThemeMode.system:
        return loc.themeSystem;
    }
  }

  void _showLanguageDialog(
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

  void _showThemeDialog(
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

  void _showLogoutDialog(BuildContext context, AppLocalizations loc) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.logoutConfirmTitle),
        content: Text(loc.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.logout),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      // 退出登录
      await AuthService.logout();

      // 跳转到登录页
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}
