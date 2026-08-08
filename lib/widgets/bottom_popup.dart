import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:retentio/widgets/dismiss_keyboard_on_tap.dart';

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
        final availableAboveKeyboard =
            MediaQuery.sizeOf(context).height - keyboardBottom - safeBottom;
        final contentHeight = math.min(
          height ?? _kPopupDefaultHeight,
          math.max(0.0, availableAboveKeyboard),
        );
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardBottom),
          child: SizedBox(
            height: contentHeight + safeBottom,
            child: SafeArea(
              top: false,
              child: DismissKeyboardOnTap(child: child),
            ),
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
