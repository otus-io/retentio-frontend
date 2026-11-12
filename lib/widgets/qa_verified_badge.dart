import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';

/// Badge for a deck whose every text/audio field is human-verified: a ring
/// with a bold check mark that breaks out past its top-right edge.
///
/// Painted rather than a `LucideIcons` glyph on purpose: Lucide has no icon
/// with this shape (the check breaking out of a translucent ring), and the
/// design asks for it. Other icons in `lib/` stay on `LucideIcons`.
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
        child: CustomPaint(
          size: Size.square(size),
          painter: QaVerifiedBadgePainter(
            ring: scheme.primary.withValues(alpha: 0.35),
            check: scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Paints [QaVerifiedBadge] in a square canvas.
class QaVerifiedBadgePainter extends CustomPainter {
  const QaVerifiedBadgePainter({required this.ring, required this.check});

  final Color ring;
  final Color check;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.drawCircle(
      Offset(s * 0.46, s * 0.54),
      s * 0.34,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.12
        ..color = ring,
    );
    final tick = Path()
      ..moveTo(s * 0.22, s * 0.50)
      ..lineTo(s * 0.42, s * 0.68)
      ..lineTo(s * 0.90, s * 0.12);
    canvas.drawPath(
      tick,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.15
        ..strokeJoin = StrokeJoin.miter
        ..color = check,
    );
  }

  @override
  bool shouldRepaint(QaVerifiedBadgePainter oldDelegate) =>
      oldDelegate.ring != ring || oldDelegate.check != check;
}
