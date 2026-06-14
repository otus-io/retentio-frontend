import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: scheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (selectedIndex == index) return;
          onDestinationSelected(index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.library),
            selectedIcon: const Icon(LucideIcons.libraryBig),
            label: loc.decks,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.tag),
            selectedIcon: const Icon(LucideIcons.tags),
            label: loc.tags,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.user),
            selectedIcon: const Icon(LucideIcons.userRoundCheck),
            label: loc.profile,
          ),
        ],
      ),
    );
  }
}
