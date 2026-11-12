import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/deck_widgets/contributions_inbox_sheet.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_menu.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/qa/qa_mode_screen.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_qa_api_adapter.dart';
import '../../../helpers/test_wrapper.dart';

Deck _deck({required bool imported}) => Deck.fromJson({
  'id': 'deck-1',
  'name': 'Deck one',
  'rate': 30,
  'fields': ['Front'],
  'min_interval': 60,
  'def_interval': 300,
  'max_interval': 86400,
  if (imported) 'source_deck_id': 'src-1',
  if (imported) 'source_version': 3,
});

/// Counts deck list refreshes without hitting the network.
class _CountingDeckListCubit extends DeckListCubit {
  int refreshes = 0;

  @override
  Future<void> onRefresh() async => refreshes++;
}

void main() {
  setUp(() async {
    await setupTestEnvironment();
    await ApiService.clearToken();
    SharedPreferences.setMockInitialValues({});
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
    networkDioClient.dio.httpClientAdapter = FakeQaApiAdapter(
      factIds: const ['fact-1'],
      entriesByFactId: {
        'fact-1': [
          {'text': 'headword'},
        ],
      },
    );
  });

  tearDown(() {
    networkDioClient.dio.httpClientAdapter = IOHttpClientAdapter();
    tearDownTestEnvironment();
  });

  group('DeckMenu QA mode entry', () {
    testWidgets('opens QA mode for an imported deck', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(body: DeckMenu(deck: _deck(imported: true))),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DeckMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('QA mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start QA'));
      await tester.pumpAndSettle();

      expect(find.byType(QaModeScreen), findsOneWidget);
    });

    testWidgets('lets the author walk a source deck and refreshes the list', (
      tester,
    ) async {
      final deckList = _CountingDeckListCubit();
      addTearDown(deckList.close);
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          BlocProvider<DeckListCubit>.value(
            value: deckList,
            child: Scaffold(body: DeckMenu(deck: _deck(imported: false))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = deckList.refreshes;

      await tester.tap(find.byType(DeckMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('QA mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start QA'));
      await tester.pumpAndSettle();
      expect(find.byType(QaModeScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(QaModeScreen), findsNothing);
      expect(deckList.refreshes, before + 1, reason: 'badge may have changed');
    });

    testWidgets('source deck inbox gets the deck columns for QA reviews', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(body: DeckMenu(deck: _deck(imported: false))),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DeckMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contributions'));
      await tester.pumpAndSettle();

      final inbox = tester.widget<ContributionsInboxSheet>(
        find.byType(ContributionsInboxSheet),
      );
      expect(inbox.sourceDeckId, 'deck-1');
      expect(inbox.fields, ['Front']);
    });

    testWidgets('closing the inbox refreshes the deck list', (tester) async {
      final deckList = _CountingDeckListCubit();
      addTearDown(deckList.close);
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          BlocProvider<DeckListCubit>.value(
            value: deckList,
            child: Scaffold(body: DeckMenu(deck: _deck(imported: false))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = deckList.refreshes;

      await tester.tap(find.byType(DeckMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contributions'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(ContributionsInboxSheet))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(ContributionsInboxSheet), findsNothing);
      expect(deckList.refreshes, before + 1, reason: 'accepts may change it');
    });
  });
}
