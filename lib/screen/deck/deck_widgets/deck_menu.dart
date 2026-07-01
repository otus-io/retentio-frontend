import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/bloc/deck_study_context_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_add.dart';
import 'package:retentio/screen/decks/widgets/deck_create.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_icon_button.dart';
import 'package:retentio/widgets/common_bottom_sheet.dart';

import 'deck_font_sheet.dart';

class DeckMenu extends StatelessWidget {
  static const _kMenuWidth = 200.0;
  static const _kMenuRadius = 12.0;
  static const _kMenuShadowAlpha = 0.12;
  static const _kMenuActionWeight = FontWeight.w500;

  const DeckMenu({super.key, required this.deck});

  final Deck deck;

  Future<void> _showSheetAfterMenuDismissed(
    BuildContext context, {
    required VoidCallback showSheet,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!context.mounted) {
      return;
    }
    showSheet();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PullDownButton(
      routeTheme: PullDownMenuRouteTheme(
        width: _kMenuWidth,
        backgroundColor: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kMenuRadius),
        shadow: BoxShadow(
          color: theme.colorScheme.onSurface.withValues(
            alpha: _kMenuShadowAlpha,
          ),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ),
      itemBuilder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        TextStyle menuItemStyle(Color color) =>
            textTheme.bodyMedium?.copyWith(
              fontWeight: _kMenuActionWeight,
              color: color,
            ) ??
            TextStyle(fontWeight: _kMenuActionWeight, color: color);

        return [
          PullDownMenuItem(
            title: loc.font,
            onTap: () async {
              await _showSheetAfterMenuDismissed(
                context,
                showSheet: () {
                  showCommonBottomSheet<void>(
                    context: context,
                    title: loc.deckFontSheetTitle,
                    initialChildSize: 0.52,
                    minChildSize: 0.35,
                    maxChildSize: 0.85,
                    child: DeckFontSheet(deckId: deck.id),
                  );
                },
              );
            },
            icon: LucideIcons.type,
            itemTheme: PullDownMenuItemTheme(
              textStyle: menuItemStyle(scheme.onSurface),
              onPressedBackgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          PullDownMenuItem(
            title: loc.addFact,
            onTap: () async {
              await _showSheetAfterMenuDismissed(
                context,
                showSheet: () {
                  showCommonBottomSheet<void>(
                    context: context,
                    title: loc.addFact,
                    initialChildSize: 0.88,
                    minChildSize: 0.45,
                    maxChildSize: 0.95,
                    child: BlocProvider<TagManagerCubit>(
                      create: (_) =>
                          TagManagerCubit(usedOn: 'fact', deckId: deck.id)
                            ..loadTags(),
                      child: FactAdd(
                        deck: deck,
                        onStudyQueueRefresh: () async =>
                            requestDeckStudyReloadCurrentCard(context),
                      ),
                    ),
                  );
                },
              );
            },
            icon: LucideIcons.layersPlus,
            itemTheme: PullDownMenuItemTheme(
              textStyle: menuItemStyle(scheme.onSurface),
              onPressedBackgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          PullDownMenuItem(
            title: loc.editDeck,
            onTap: () async {
              final deckContextCubit = context.read<DeckStudyContextCubit>();
              await _showSheetAfterMenuDismissed(
                context,
                showSheet: () {
                  showCommonBottomSheet(
                    context: context,
                    title: loc.editDeck,
                    fullScreen: true,
                    child: MultiBlocProvider(
                      providers: [
                        BlocProvider.value(
                          value: context.read<DeckListCubit>(),
                        ),
                        BlocProvider<DeckCreateCubit>(
                          create: (_) => DeckCreateCubit(
                            name: deck.name,
                            rate: deck.rate,
                            deckId: deck.id,
                            cardType: DeckCardType.edit,
                            isImported: deck.isImported,
                          ),
                        ),
                        BlocProvider<TagManagerCubit>(
                          create: (_) => TagManagerCubit(usedOn: 'deck'),
                        ),
                      ],
                      child: DeckCreate(deck: deck),
                    ),
                  ).then((value) {
                    if (value is String && value.isNotEmpty) {
                      deckContextCubit.updateDeck(deck.copyWith(name: value));
                    }
                  });
                },
              );
            },
            icon: LucideIcons.squarePen,
            itemTheme: PullDownMenuItemTheme(
              textStyle: menuItemStyle(scheme.onSurface),
              onPressedBackgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const PullDownMenuDivider.large(),
          PullDownMenuItem(
            title: loc.deleteDeck,
            onTap: () async {
              await context.read<DeckListCubit>().deleteDeck(deck);
              if (context.mounted) {
                context.pop();
              }
            },
            icon: LucideIcons.trash2,
            iconColor: scheme.error,
            itemTheme: PullDownMenuItemTheme(
              textStyle: menuItemStyle(scheme.error),
              onPressedBackgroundColor: scheme.error.withValues(alpha: 0.1),
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => AppIconButton(
        icon: LucideIcons.ellipsis,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.all(AppThemeTokens.spaceSm),
        onPressed: showMenu,
        tooltip: 'Deck options',
      ),
    );
  }
}
