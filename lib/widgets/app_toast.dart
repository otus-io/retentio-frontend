import 'package:flutter/material.dart';
import 'dart:async';

class AppToast {
  static OverlayEntry? _entry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface);
    final bg = backgroundColor ?? scheme.inverseSurface;

    _entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_entry!);

    _dismissTimer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _entry?.remove();
    _entry = null;
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) => show(
    context,
    message,
    backgroundColor: Theme.of(context).colorScheme.error,
    duration: duration,
  );

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) => show(context, message, duration: duration);

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) => show(context, message, duration: duration);

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) => show(context, message, duration: duration);
}
