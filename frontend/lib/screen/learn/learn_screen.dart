import 'package:flutter/material.dart';
import 'package:wordupx/l10n/app_localizations.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Text(loc.learn, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
