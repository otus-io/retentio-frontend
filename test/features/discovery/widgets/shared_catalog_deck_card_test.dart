import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/qa_verified_badge.dart';
import 'package:retentio/features/discovery/presentation/widgets/shared_catalog_deck_card.dart';
import 'package:retentio/models/catalog_deck.dart';

import '../../../helpers/test_wrapper.dart';

void main() {
  Widget card({required bool verified}) => buildTestableWidgetWithoutProvider(
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
      ),
    ),
  );

  testWidgets('shows the QA badge only for verified decks', (tester) async {
    await tester.pumpWidget(card(verified: true));
    expect(find.byType(QaVerifiedBadge), findsOneWidget);

    await tester.pumpWidget(card(verified: false));
    expect(find.byType(QaVerifiedBadge), findsNothing);
  });
}
