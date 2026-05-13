import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/common_refresher.dart';

import 'deck_list_card.dart';

const double _kDeckStateHorizontalPadding = 26;

class DeckScreenBody extends StatelessWidget {
  const DeckScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final deckCubit = context.read<DeckListCubit>();
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<DeckListCubit, DeckListState>(
      builder: (context, state) {
        if (state.isLoading && state.decks.isEmpty) {
          return Center(child: CircularProgressIndicator(color: scheme.primary));
        }

        if (state.error != null && state.decks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(_kDeckStateHorizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.triangleAlert, size: 54, color: scheme.error),
                  const SizedBox(height: 12),
                  Text('Error: ${state.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  AppButton(
                    label: loc.retry,
                    variant: AppButtonVariant.primary,
                    onPressed: deckCubit.onRefresh,
                  ),
                ],
              ),
            ),
          );
        }

        return CommonRefresher(
          controller: deckCubit.refreshController,
          onRefresh: deckCubit.onRefresh,
          onLoading: deckCubit.onLoading,
          isEmpty: state.decks.isEmpty,
          emptyView: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kDeckStateHorizontalPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.inbox, size: 58, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(loc.noDecksAvailable, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            itemCount: state.decks.length,
            itemBuilder: (context, index) {
              final deck = state.decks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeckListCard(deck: deck),
              );
            },
          ),
        );
      },
    );
  }
}
