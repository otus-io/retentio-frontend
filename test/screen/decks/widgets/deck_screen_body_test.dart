import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/data/offline_deck_catalog.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_sharing_status_cubit.dart';
import 'package:retentio/screen/decks/widgets/deck_list_card.dart';
import 'package:retentio/screen/decks/widgets/deck_screen_body.dart';

import '../../../helpers/test_wrapper.dart';

class _ReadyCubit extends DeckListCubit {
  _ReadyCubit() : super(offlineCatalog: _Catalog());

  void setOfflineReady(Set<String> ids) {
    emit(state.copyWith(offlineReadyDeckIds: ids));
  }
}

class _Catalog implements OfflineDeckCatalog {
  @override
  Future<List<Deck>> decks(Future<List<Deck>> Function() fetchRemote) async => [
    Deck.fromJson({'id': 'd1', 'name': 'Downloaded'}),
    Deck.fromJson({'id': 'd2', 'name': 'Online only'}),
  ];

  @override
  Future<Set<String>> readyDeckIds() async => {'d1'};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('only offline-ready decks show the offline marker', (
    tester,
  ) async {
    final cubit = _ReadyCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        MultiBlocProvider(
          providers: [
            BlocProvider<DeckListCubit>.value(value: cubit),
            BlocProvider(create: (_) => DeckSharingStatusCubit()),
          ],
          child: const Scaffold(body: DeckScreenBody()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Downloaded'), findsOneWidget);
    expect(find.text('Online only'), findsOneWidget);
    expect(find.byTooltip('Available offline'), findsOneWidget);

    cubit.setOfflineReady({'d2'});
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .widget<DeckListCard>(find.widgetWithText(DeckListCard, 'Downloaded'))
          .availableOffline,
      isFalse,
    );
    expect(
      tester
          .widget<DeckListCard>(
            find.widgetWithText(DeckListCard, 'Online only'),
          )
          .availableOffline,
      isTrue,
    );
  });
}
