import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/bloc/deck_study_context_cubit.dart';
import 'package:retentio/screen/deck/bloc/deck_study_flip_card_controller_cubit.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_menu.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_body.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/theme/theme_tokens.dart';

import '../../features/deck_study/deck_study.dart';

class DeckViewScreen extends StatelessWidget {
  final Deck deck;

  const DeckViewScreen({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final repository = DeckStudyLegacyServiceRepository();
    final maybeDeckListCubit = _tryReadDeckListCubit(context);
    final injectedStudyBloc = _tryReadInjectedStudyBloc(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<DeckStudyContextCubit>(
          create: (_) => DeckStudyContextCubit(deck),
        ),
        BlocProvider<DeckStudyFlipCardControllerCubit>(
          create: (_) => DeckStudyFlipCardControllerCubit(),
        ),
        if (injectedStudyBloc != null)
          BlocProvider<DeckStudyBloc>.value(value: injectedStudyBloc)
        else
          BlocProvider<DeckStudyBloc>(
            create: (_) => DeckStudyBloc(
              deckId: deck.id,
              getNextDueCardUseCase: GetNextDueCardUseCase(repository),
              submitCardReviewUseCase: SubmitCardReviewUseCase(repository),
              deleteStudyCardUseCase: DeleteStudyCardUseCase(repository),
              loadDeckTagsUseCase: LoadDeckTagsUseCase(repository),
            )..add(const DeckStudyStarted()),
            lazy: false,
          ),
        if (maybeDeckListCubit != null)
          BlocProvider<DeckListCubit>.value(value: maybeDeckListCubit),
        BlocProvider<DeckCreateCubit>(
          create: (_) => DeckCreateCubit(
            name: deck.name,
            rate: deck.rate,
            deckId: deck.id,
            cardType: DeckCardType.edit,
          ),
        ),
      ],
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.surfaceContainerHighest,
          title: BlocBuilder<DeckStudyContextCubit, DeckStudyContextState>(
            buildWhen: (previous, current) =>
                previous.deck.name != current.deck.name,
            builder: (context, state) => Text(state.deck.name),
          ),
          leadingWidth: 52,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(size: 22, color: scheme.onSurface),
          actionsPadding: const EdgeInsets.only(right: AppThemeTokens.spaceMd),
          actions: [
            BlocBuilder<DeckStudyContextCubit, DeckStudyContextState>(
              buildWhen: (previous, current) =>
                  previous.deck.id != current.deck.id ||
                  previous.deck.name != current.deck.name,
              builder: (context, state) => DeckMenu(deck: state.deck),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
              height: 1,
              color: scheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        body: const DeckViewBody(),
      ),
    );
  }
}

DeckListCubit? _tryReadDeckListCubit(BuildContext context) {
  try {
    return context.read<DeckListCubit>();
  } catch (_) {
    return null;
  }
}

DeckStudyBloc? _tryReadInjectedStudyBloc(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(deckStudyBlocProvider);
  } catch (_) {
    return null;
  }
}
