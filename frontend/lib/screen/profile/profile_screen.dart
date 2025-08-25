import 'package:flutter/material.dart';
import 'package:wordupx/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        loc.profile,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
