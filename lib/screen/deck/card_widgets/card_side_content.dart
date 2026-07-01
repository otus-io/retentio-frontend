import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/features/deck_study/deck_study.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/bloc/deck_study_context_cubit.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/providers/deck_scope.dart';
import 'card_content_container.dart';
import 'card_menu.dart';

/// One side (front or back) of the current review card on the deck study screen:
/// field tabs, field content, and card actions (hide / edit fact / delete).
class CardSideContent extends StatelessWidget {
  static const _kContainerRadius = 16.0;
  static const _kMenuColorAlpha = 0.75;

  const CardSideContent({super.key, required this.isFront});

  final bool isFront;

  @override
  Widget build(BuildContext context) {
    final deck = _readCurrentDeck(context);
    final deckId = deck.id;
    final studyBloc = _readStudyBloc(context);

    return BlocBuilder<DeckStudyBloc, DeckStudyState>(
      bloc: studyBloc,
      builder: (context, state) {
        final sideCards =
            (isFront
                ? state.cardDetail?.card.front
                : state.cardDetail?.card.back) ??
            <CardSlot>[];
        final scheme = Theme.of(context).colorScheme;
        final accentColor = scheme.primary;
        final contentColor = scheme.onSurface;
        final cardId = state.cardDetail?.card.id;
        final content = CardContentContainer(
          cards: sideCards,
          color: accentColor,
          accentColor: accentColor,
          textColor: contentColor,
          trailing: sideCards.isNotEmpty
              ? CardMenu(
                  color: scheme.onSurface.withValues(alpha: _kMenuColorAlpha),
                )
              : null,
          typographyDeckId: deckId,
          typographyIsFront: isFront,
        );

        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(_kContainerRadius),
          ),
          child: sideCards.isEmpty
              ? content
              : DefaultTabController(
                  key: ValueKey(cardId),
                  length: sideCards.length,
                  child: content,
                ),
        );
      },
    );
  }
}

Deck _readCurrentDeck(BuildContext context) {
  try {
    return context.read<DeckStudyContextCubit>().state.deck;
  } catch (_) {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(currentDeckProvider);
  }
}

DeckStudyBloc _readStudyBloc(BuildContext context) {
  try {
    return context.read<DeckStudyBloc>();
  } catch (_) {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(deckStudyBlocProvider);
  }
}
