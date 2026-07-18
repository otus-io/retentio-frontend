import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/decks/deck_text_styles.dart';
import 'package:retentio/screen/decks/widgets/deck_create.dart';
import 'package:retentio/screen/decks/widgets/deck_screen_body.dart';
import 'package:retentio/screen/tags/tags_screen.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_icon_button.dart';
import 'package:retentio/widgets/draggable_fab.dart';

import '../../widgets/common_bottom_sheet.dart';

const double _kDeckListHorizontalPadding = 16;

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  late final DeckListCubit _deckListCubit;

  @override
  void initState() {
    super.initState();
    _deckListCubit = DeckListCubit();
  }

  @override
  void dispose() {
    _deckListCubit.close();
    super.dispose();
  }

  void _openCreateSheet(BuildContext context, AppLocalizations loc) {
    showCommonBottomSheet(
      context: context,
      title: loc.createDeck,
      fullScreen: true,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DeckListCubit>.value(value: _deckListCubit),
          BlocProvider<DeckCreateCubit>(
            create: (_) => DeckCreateCubit(
              name: '',
              rate: kDeckEditorRateDefault,
              deckId: '',
              cardType: DeckCardType.add,
            ),
          ),
          BlocProvider<TagManagerCubit>(
            create: (_) => TagManagerCubit(usedOn: 'deck'),
          ),
        ],
        child: const DeckCreate(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Stack(
      children: [
        BlocProvider<DeckListCubit>.value(
          value: _deckListCubit,
          child: Scaffold(
            appBar: AppBar(
              title: Text(loc.decks),
              scrolledUnderElevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AppIconButton(
                    icon: LucideIcons.tag,
                    tooltip: loc.tags,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: const EdgeInsets.all(AppThemeTokens.spaceSm),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TagsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(30),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _kDeckListHorizontalPadding,
                      0,
                      _kDeckListHorizontalPadding,
                      10,
                    ),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'zh'
                          ? '你的学习卡组'
                          : 'Your study collections',
                      style: DeckTextStyles.pageSubtitle(theme),
                    ),
                  ),
                ),
              ),
            ),
            body: const DeckScreenBody(),
          ),
        ),
        DraggableFab(
          onPressed: () => _openCreateSheet(context, loc),
          tooltip: loc.createDeck,
          storageKey: 'fab_decks',
        ),
      ],
    );
  }
}
