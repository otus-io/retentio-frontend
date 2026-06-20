import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/features/deck_study/deck_study.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/bloc/deck_study_context_cubit.dart';
import 'package:retentio/screen/deck/bloc/deck_study_flip_card_controller_cubit.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_edit.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_icon_button.dart';
import 'package:retentio/widgets/common_bottom_sheet.dart';

class CardMenu extends StatelessWidget {
  static const _kButtonExtent = 48.0;
  static const _kMenuWidth = 180.0;
  static const _kMenuRadius = 12.0;
  static const _kMenuShadowAlpha = 0.12;

  const CardMenu({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    TextStyle menuItemStyle(Color color) =>
        textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: color,
        ) ??
        TextStyle(fontWeight: FontWeight.w500, color: color);

    return SizedBox(
      width: _kButtonExtent,
      height: _kButtonExtent,
      child: PullDownButton(
        routeTheme: PullDownMenuRouteTheme(
          width: _kMenuWidth,
          backgroundColor: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(_kMenuRadius),
          shadow: BoxShadow(
            color: scheme.onSurface.withValues(alpha: _kMenuShadowAlpha),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ),
        itemBuilder: (context) {
          return [
            PullDownMenuItem(
              title: loc.hideCard,
              onTap: () async {
                requestDeckStudyNextCard(context, hideCurrentCard: true);
                _tryShowFrontOnFlipController(context);
              },
              icon: LucideIcons.eyeOff,
              itemTheme: PullDownMenuItemTheme(
                textStyle: menuItemStyle(scheme.onSurface),
              ),
            ),
            PullDownMenuItem(
              title: loc.editFact,
              onTap: () {
                final deck = context.read<DeckStudyContextCubit>().state.deck;
                final card = context
                    .read<DeckStudyBloc>()
                    .state
                    .cardDetail
                    ?.card;
                if (card == null) return;
                showCommonBottomSheet(
                  context: context,
                  fullScreen: true,
                  title: loc.editFact,
                  child: BlocProvider<TagManagerCubit>(
                    create: (_) =>
                        TagManagerCubit(usedOn: 'fact', deckId: deck.id)
                          ..loadTags(),
                    child: FactEdit(
                      deck: deck,
                      factId: card.factId,
                      onSaved: () async =>
                          requestDeckStudyReloadCurrentCard(context),
                    ),
                  ),
                );
              },
              icon: LucideIcons.pencil,
              itemTheme: PullDownMenuItemTheme(
                textStyle: menuItemStyle(scheme.onSurface),
              ),
            ),
            PullDownMenuItem(
              title: loc.deleteCard,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(loc.deleteCard),
                    content: Text(loc.deleteCardConfirm),
                    actions: [
                      AppButton(
                        label: loc.cancel,
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        variant: AppButtonVariant.ghost,
                      ),
                      AppButton(
                        label: loc.deleteCard,
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        variant: AppButtonVariant.danger,
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                requestDeckStudyDeleteCurrentCard(context);
              },
              icon: LucideIcons.trash2,
              iconColor: scheme.error,
              itemTheme: PullDownMenuItemTheme(
                textStyle: menuItemStyle(scheme.error),
                onPressedBackgroundColor: scheme.error.withValues(alpha: 0.08),
              ),
            ),
          ];
        },
        buttonBuilder: (context, showMenu) => AppIconButton(
          icon: LucideIcons.ellipsis,
          onPressed: showMenu,
          color: color,
          tooltip: 'Card options',
        ),
      ),
    );
  }
}

void _tryShowFrontOnFlipController(BuildContext context) {
  try {
    context.read<DeckStudyFlipCardControllerCubit>().state.showFront();
  } catch (_) {}
}
