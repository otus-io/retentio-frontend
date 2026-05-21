import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:retentio/theme/app_theme.dart';

class LoginGradientBackground extends HookWidget {
  final bool isDark;

  const LoginGradientBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colors = AppTheme.loginBackground(brightness);
    final scheme = Theme.of(context).colorScheme;
    final overlay = scheme.primary.withValues(alpha: isDark ? 0.14 : 0.1);
    final accent = scheme.secondary.withValues(alpha: isDark ? 0.1 : 0.08);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [overlay, Colors.transparent],
                  stops: const [0.08, 1],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 310,
              height: 310,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent, Colors.transparent],
                  stops: const [0.1, 1],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.surface.withValues(alpha: isDark ? 0.04 : 0.02),
                  Colors.transparent,
                  scheme.tertiary.withValues(alpha: isDark ? 0.05 : 0.03),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}
