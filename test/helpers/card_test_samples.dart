import 'package:retentio/models/card.dart';
import 'package:retentio/models/deck.dart';

Deck sampleDeck({int cardsCount = 5}) {
  return Deck.fromJson({
    'id': 'deck-test-1',
    'name': 'Test deck',
    'stats': {
      'cards_count': cardsCount,
      'unseen_cards': cardsCount,
      'due_cards': cardsCount,
      'facts_count': 1,
      'reviewed_cards': 0,
      'hidden_cards': 0,
      'new_cards_today': 0,
      'last_reviewed_at': 0,
    },
    'rate': 10,
    'min_interval': 60,
    'def_interval': 300,
    'max_interval': 86400,
    'owner': {'username': 'u', 'email': 'u@t.com'},
    'fields': ['Front', 'Back'],
  });
}

/// Minimal valid [CardDetail] for widget/provider tests (single tab per side).
CardDetail sampleCardDetail({bool hidden = false}) {
  return CardDetail.fromJson({
    'urgency': 0.5,
    'card': {
      'id': 'card-test-1',
      'fact_id': 'fact-test-1',
      'hidden': hidden,
      'created_at': 1,
      'due_date': 9999999999,
      'last_review': 1,
      'template': [
        [0],
        [1],
      ],
      'front': [
        {
          'field': 'Front',
          'items': [
            {'type': 'text', 'value': 'Hello'},
          ],
        },
      ],
      'back': [
        {
          'field': 'Back',
          'items': [
            {'type': 'text', 'value': 'World'},
          ],
        },
      ],
    },
  });
}

/// Three back fields for stacked layout widget tests.
CardDetail sampleMultiFieldCardDetail() {
  return CardDetail.fromJson({
    'urgency': 0.5,
    'card': {
      'id': 'card-multi-1',
      'fact_id': 'fact-multi-1',
      'hidden': false,
      'created_at': 1,
      'due_date': 9999999999,
      'last_review': 1,
      'template': [
        [0],
        [1, 2, 3],
      ],
      'front': [
        {
          'field': 'Word',
          'items': [
            {'type': 'text', 'value': 'benefit'},
          ],
        },
        {
          'field': 'Reading',
          'items': [
            {'type': 'text', 'value': 'ˈbenɪfɪt'},
          ],
        },
      ],
      'back': [
        {
          'field': 'Chinese',
          'items': [
            {'type': 'text', 'value': '利益, 好处 ; 优势'},
          ],
        },
        {
          'field': 'English Example',
          'items': [
            {
              'type': 'text',
              'value':
                  'The discovery of oil brought many benefits to the town.',
            },
          ],
        },
        {
          'field': 'Chinese Example',
          'items': [
            {'type': 'text', 'value': '石油的发现给该镇带来很多利益。'},
          ],
        },
      ],
    },
  });
}
