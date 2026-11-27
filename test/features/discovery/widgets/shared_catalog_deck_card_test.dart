import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/qa_verified_badge.dart';
import 'package:retentio/features/discovery/presentation/widgets/shared_catalog_deck_card.dart';
import 'package:retentio/models/catalog_deck.dart';

import '../../../helpers/test_wrapper.dart';

void main() {
  Widget card({required bool verified, bool unavailable = false}) =>
      buildTestableWidgetWithoutProvider(
        Scaffold(
          body: SharedCatalogDeckCard(
            deck: CatalogDeck(
              id: 'src-1',
              name: 'N5',
              owner: 'alice',
              fields: const ['A', 'B'],
              publishedVersion: 1,
              factCount: 3,
              deckTagNames: const [],
              qaVerified: verified,
            ),
            isFavorite: false,
            onFavoriteToggle: () {},
            onTap: () {},
            isUnavailable: unavailable,
          ),
        ),
      );

  testWidgets('shows the QA badge only for verified decks', (tester) async {
    await tester.pumpWidget(card(verified: true));
    expect(find.byType(QaVerifiedBadge), findsOneWidget);
    final nameLeft = tester.getTopLeft(find.text('N5')).dx;
    final badgeLeft = tester.getTopLeft(find.byType(QaVerifiedBadge)).dx;
    expect(badgeLeft - nameLeft, lessThan(120));

    await tester.pumpWidget(card(verified: false));
    expect(find.byType(QaVerifiedBadge), findsNothing);
  });

  testWidgets('dims the name of an unavailable deck', (tester) async {
    await tester.pumpWidget(card(verified: true, unavailable: true));
    final name = tester.widget<Text>(find.text('N5'));
    expect(name.style?.color?.a, lessThan(0.5));
  });
}
