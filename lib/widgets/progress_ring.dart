import 'package:flutter/material.dart';

/// Circular progress with the whole percent in the middle (unless
/// [showPercent] is off, for sizes too small to read it). A null [value]
/// shows an indeterminate spinner without a number.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    this.value,
    this.size = 48,
    this.showPercent = true,
  });

  /// Progress from 0 to 1, or null when unknown.
  final double? value;
  final double size;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = this.value?.clamp(0.0, 1.0);
    final percent = value == null ? null : (value * 100).floor();
    return Semantics(
      label: percent == null ? null : '$percent%',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: size / 10,
                backgroundColor: theme.colorScheme.outline.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            if (percent != null && showPercent)
              ExcludeSemantics(
                child: Text(
                  '$percent%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: size * 0.25,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
