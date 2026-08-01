import 'package:flutter/material.dart';
import 'package:retentio/widgets/app_icon_button.dart';

/// [AppIconButton] with an optional corner badge dot (update / unpublished).
class BadgedAppIconButton extends StatelessWidget {
  const BadgedAppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.showBadge,
    this.size = 18,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showBadge;
  final double size;

  static const double _badgeSize = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = AppIconButton(
      icon: icon,
      tooltip: tooltip,
      variant: AppIconButtonVariant.subtle,
      size: size,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: onPressed,
    );
    if (!showBadge) {
      return button;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: 4,
          right: 4,
          child: IgnorePointer(
            child: Container(
              width: _badgeSize,
              height: _badgeSize,
              decoration: BoxDecoration(
                color: scheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
