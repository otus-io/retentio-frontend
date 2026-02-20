import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wordupx/providers/loading_state_provider.dart';

class LoadingStateWidget extends ConsumerWidget {
  const LoadingStateWidget({super.key, required this.child, this.size});

  final Widget child;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(loadingStateProvider);
    return switch (loading) {
      LoadingState.loading => CircularProgressIndicator(
        color: Colors.blue,
        strokeWidth: 2,
        constraints: BoxConstraints.expand(
          width: size ?? 20,
          height: size ?? 20,
        ),
      ),
      LoadingState.error => Icon(LucideIcons.circleX, color: Colors.red),
      LoadingState.loaded => Icon(LucideIcons.circleCheck, color: Colors.green),
      _ => child,
    };
  }
}
