import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardText extends ConsumerWidget {
  const CardText({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}
