import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_add.dart';
import 'package:retentio/screen/decks/providers/deck_list.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_deck_list_notifier.dart';
import '../../helpers/fake_fact_api_interceptor.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  group('FactAdd', () {
    testWidgets(
      'save fact calls API and shows success when deckListProvider is available',
      (tester) async {
        await setupTestEnvironment();
        final interceptor = attachFakeFactApiInterceptor();
        addTearDown(() {
          detachFakeFactApiInterceptor(interceptor);
          tearDownTestEnvironment();
        });

        final deck = sampleDeck();

        await tester.pumpWidget(
          buildTestableWidgetWithOverrides(
            Scaffold(body: FactAdd(deck: deck)),
            overrides: [
              deckListProvider.overrideWith(() => FakeDeckListNotifier([deck])),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Front'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(find.byTooltip('Add row'), findsNothing);
        expect(find.byTooltip('Remove row'), findsNothing);

        final textFields = find.byType(TextField);
        expect(textFields, findsNWidgets(2));

        await tester.enterText(textFields.at(0), 'Hello');
        await tester.enterText(textFields.at(1), 'World');
        await tester.pump();

        await tester.tap(find.text('Save fact'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(interceptor.addFactsCount, 1);
        expect(find.text('Fact added'), findsOneWidget);
      },
    );
  });
}
