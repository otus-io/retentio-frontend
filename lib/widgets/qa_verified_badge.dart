import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';

/// Round "V" badge for a deck whose every text/audio field is human-verified.
class QaVerifiedBadge extends StatelessWidget {
  const QaVerifiedBadge({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.qaVerifiedBadge;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            'V',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: size * 0.6,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
