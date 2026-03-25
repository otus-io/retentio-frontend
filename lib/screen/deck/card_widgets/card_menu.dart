import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:retentio/extensions/context_extension.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/providers/card_provider.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_edit.dart';
import 'package:retentio/widgets/common_bottom_sheet.dart';

class CardMenu extends ConsumerWidget {
  const CardMenu({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
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
              await ref.read(cardProvider.notifier).nextCard(isHide: true);
              ref.read(cardProvider.notifier).flipCardController.showFront();
              ref.read(cardProvider.notifier).showAnswer();
            },
            icon: LucideIcons.eyeOff,
          ),
          PullDownMenuItem(
            title: 'Edit Fact',
            onTap: () {
              final deck = ref.read(deckProvider);
              final card = ref.read(cardProvider).cardDetail?.card;
              if (card == null) return;
              showCommonBottomSheet(
                context: context,
                initialChildSize: 0.4,
                minChildSize: 0.3,
                maxChildSize: 0.85,
                title: 'Edit Fact',
                child: FactEdit(
                  deck: deck,
                  factId: card.factId,
                  onSaved: () =>
                      ref.read(cardProvider.notifier).getCardDetail(),
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
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(loc.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(loc.deleteCard),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;

              final ok = await ref
                  .read(cardProvider.notifier)
                  .deleteCurrentCard();
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(loc.deleteCardFailed)));
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
          icon: Icon(LucideIcons.ellipsisVertical, color: color),
        ),
      ),
    );
  }
}
