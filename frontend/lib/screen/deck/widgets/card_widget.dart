import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';

import '../../../extensions/context_extension.dart';
import '../../../widgets/common_bottom_sheet.dart';
import '../providers/card_provider.dart';
import 'buttons_tabbar/buttons_tab_bar_widget.dart';
import 'edit_fact_widget.dart';
import 'field_content_widget.dart';

class CardWidget extends ConsumerWidget {
  const CardWidget({super.key, required this.isFront});

  final bool isFront;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.read(
      cardProvider.select(
        (value) => isFront
            ? value.cardDetail?.card?.front
            : value.cardDetail?.card?.back,
      ),
    );
    final color = isFront ? Colors.blue : Colors.green;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: DefaultTabController(
        key: ValueKey('${ref.read(cardProvider).cardDetail?.card?.id}'),
        length: cards?.length ?? 0,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(width: 0.3, color: color)),
              ),
              child: Row(
                mainAxisSize: .max,
                children: [
                  ButtonsTabBar(
                    backgroundColor: Colors.transparent,
                    unselectedBackgroundColor: Colors.transparent,
                    borderWidth: 1,
                    radius: 10,
                    borderColor: Colors.transparent,
                    unselectedBorderColor: Colors.transparent,
                    labelStyle: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                    // Add your tabs here
                    tabs:
                        cards?.map((e) {
                          return Tab(icon: Icon(LucideIcons.file));
                        }).toList() ??
                        [],
                  ).expanded(),
                  if (cards?.isNotEmpty == true)
                    SizedBox(
                      width: 50,
                      height: 46,
                      child: PullDownButton(
                        routeTheme: PullDownMenuRouteTheme(
                          width: 180,
                          backgroundColor: context.colorScheme.surface,
                        ),
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            title: AppLocalizations.of(context)!.hideCard,
                            onTap: () async {
                              await ref
                                  .read(cardProvider.notifier)
                                  .nextCard(isHide: true);
                              ref
                                  .read(cardProvider.notifier)
                                  .flashCardController
                                  .showFront();
                              ref.read(cardProvider.notifier).showAnswer();
                            },
                            icon: LucideIcons.eyeOff,
                          ),
                          PullDownMenuItem(
                            title: 'Edit Fact',
                            onTap: () {
                              final deck = ref.read(deckProvider);
                              final card = ref
                                  .read(cardProvider)
                                  .cardDetail
                                  ?.card;
                              if (card == null) return;
                              showCommonBottomSheet(
                                context: context,
                                initialChildSize: 0.4,
                                minChildSize: 0.3,
                                maxChildSize: 0.85,
                                title: 'Edit Fact',
                                child: EditFactWidget(
                                  deck: deck,
                                  factId: card.factId,
                                  onSaved: () => ref
                                      .read(cardProvider.notifier)
                                      .getCardDetail(),
                                ),
                              );
                            },
                            icon: LucideIcons.pencil,
                          ),
                          PullDownMenuItem(
                            title: AppLocalizations.of(context)!.deleteCard,
                            onTap: () async {
                              final loc = AppLocalizations.of(context)!;
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(loc.deleteCard),
                                  content: Text(loc.deleteCardConfirm),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                                      child: Text(loc.cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(loc.deleteCard),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !context.mounted) {
                                return;
                              }
                              final ok = await ref
                                  .read(cardProvider.notifier)
                                  .deleteCurrentCard();
                              if (!context.mounted) return;
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(loc.deleteCardFailed)),
                                );
                              }
                            },
                            icon: LucideIcons.trash2,
                            iconColor: Colors.red,
                            itemTheme: PullDownMenuItemTheme(
                              textStyle: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        buttonBuilder: (context, showMenu) => IconButton(
                          onPressed: showMenu,
                          icon: Icon(
                            LucideIcons.ellipsisVertical,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            TabBarView(
              children:
                  cards?.map((e) {
                    return FieldContentWidget(back: e, color: color);
                  }).toList() ??
                  [],
            ).expanded(),
          ],
        ),
      ),
    );
  }
}
