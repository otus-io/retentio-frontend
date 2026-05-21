import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';

const double _kDeckLoadingIndicatorSize = 20;
const double _kDeckLoadingStrokeWidth = 2;

class DeckLoadingState extends StatelessWidget {
  const DeckLoadingState({super.key, required this.child, this.size});

  final Widget child;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final loading = context.select(
      (DeckCreateCubit cubit) => cubit.state.loadingState,
    );
    final scheme = Theme.of(context).colorScheme;
    return switch (loading) {
      DeckCreateLoadingState.loading => CircularProgressIndicator(
        color: scheme.primary,
        strokeWidth: _kDeckLoadingStrokeWidth,
        constraints: BoxConstraints.expand(
          width: size ?? _kDeckLoadingIndicatorSize,
          height: size ?? _kDeckLoadingIndicatorSize,
        ),
      ),
      DeckCreateLoadingState.error => Icon(
        LucideIcons.circleX,
        color: scheme.error,
      ),
      DeckCreateLoadingState.loaded => Icon(
        LucideIcons.circleCheck,
        color: scheme.secondary,
      ),
      _ => child,
    };
  }
}
