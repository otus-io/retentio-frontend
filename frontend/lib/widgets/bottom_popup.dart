import 'package:flutter/material.dart';

class BottomPopup extends StatelessWidget {
  final Widget child;
  final double? height;

  const BottomPopup({super.key, required this.child, this.height});

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double? height,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(height: height ?? 320, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
