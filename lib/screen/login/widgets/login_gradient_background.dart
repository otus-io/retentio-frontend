import 'package:flutter/material.dart';

class LoginGradientBackground extends StatelessWidget {
  final bool isDark;

  const LoginGradientBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors = isDark
        ? const [
            Color(0xFF070A14),
            Color(0xFF101522),
            Color(0xFF1A1F2B),
            Color(0xFF23283A),
          ]
        : const [
            Color(0xFFFFF1EB),
            Color(0xFFFFD6E0),
            Color(0xFFFFB4A2),
            Color(0xFFFFCDB2),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
    );
  }
}
