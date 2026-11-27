import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_icon_button.dart';

/// `?` that explains how importers can fix facts and send them to the author.
class ContributeHelpButton extends StatelessWidget {
  const ContributeHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppIconButton(
      icon: LucideIcons.circleHelp,
      tooltip: loc.contributeHelpTitle,
      iconSize: 18,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(loc.contributeHelpTitle),
          content: Text(loc.contributeHelpMessage),
          actions: [
            AppButton(
              label: loc.contributeHelpGotIt,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
