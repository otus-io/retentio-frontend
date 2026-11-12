import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';

/// Check badge for a deck whose every text/audio field is human-verified.
class QaVerifiedBadge extends StatelessWidget {
  const QaVerifiedBadge({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.qaVerifiedBadge;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Icon(
          LucideIcons.badgeCheck,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
