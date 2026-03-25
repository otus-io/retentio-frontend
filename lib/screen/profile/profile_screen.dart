import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/providers/locale_provider.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/screen/profile/profile_settings_dialogs.dart';
import 'package:retentio/screen/profile/widgets/profile_user_header.dart';

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
          const ProfileUserHeader(),
          const SizedBox(height: 16),
          const Divider(height: 1),
          ListTile(
            leading: Icon(LucideIcons.globe),
            title: Text(loc.changeLanguage),
            subtitle: Text(profileLanguageDisplayName(currentLocale)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => showProfileLanguageDialog(context, ref, loc),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.palette),
            title: Text(loc.changeTheme),
            subtitle: Text(profileThemeDisplayName(currentTheme, loc)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => showProfileThemeDialog(context, ref, loc),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.red),
            title: Text(loc.logout, style: const TextStyle(color: Colors.red)),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.red,
            ),
            onTap: () => showProfileLogoutDialog(context, ref, loc),
          ),
        ],
      ),
    );
  }
}
