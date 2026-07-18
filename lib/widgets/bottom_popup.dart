import 'package:flutter/material.dart';

const double _kPopupTopRadius = 16;
const double _kPopupDefaultHeight = 320;

class BottomPopup extends StatelessWidget {
  final Widget child;
  final double? height;

  const BottomPopup({super.key, required this.child, this.height});

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double? height,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_kPopupTopRadius),
        ),
      ),
      builder: (context) {
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardBottom),
          child: SizedBox(
            height: (height ?? _kPopupDefaultHeight) + safeBottom,
            child: SafeArea(top: false, child: child),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
