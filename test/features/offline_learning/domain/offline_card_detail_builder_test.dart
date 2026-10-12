import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_card_detail_builder.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/models/fact.dart';

OfflineCard _card(List<List<int>> template) => OfflineCard(
  deckId: 'd1',
  id: 'c1',
  factId: 'f1',
  template: template,
  lastReview: 10,
  dueDate: 20,
  hidden: true,
  createdAt: 5,
);

const _fact = OfflineFact(
  deckId: 'd1',
  id: 'f1',
  entries: [
    FactEntry(text: 'hello'),
    FactEntry(text: 'world', audio: 'a1', image: 'i1'),
    FactEntry(video: 'v1', json: 'j1'),
  ],
);

CardDetail _build(
  List<List<int>> template, {
  List<String> fields = const ['Front', 'Back'],
}) => buildOfflineCardDetail(
  card: _card(template),
  fact: _fact,
  deckFields: fields,
  urgency: 0.75,
  resolveMedia: (id) => '/media/$id',
);

List<(String, String)> _items(CardSlot slot) => [
  for (final i in slot.items) (i.type, i.value),
];

void main() {
  test('copies card metadata and urgency', () {
    final d = _build([
      [0],
      [1],
    ]);
    expect(d.urgency, 0.75);
    expect(d.card.id, 'c1');
    expect(d.card.factId, 'f1');
    expect(d.card.lastReview, 10);
    expect(d.card.dueDate, 20);
    expect(d.card.hidden, isTrue);
    expect(d.card.createdAt, 5);
    expect(d.card.template, [
      [0],
      [1],
    ]);
  });

  test('builds slots with field labels and resolved media', () {
    final d = _build([
      [0],
      [1],
    ]);
    expect(d.card.front.single.field, 'Front');
    expect(_items(d.card.front.single), [('text', 'hello')]);
    expect(d.card.back.single.field, 'Back');
    expect(_items(d.card.back.single), [
      ('text', 'world'),
      ('audio', '/media/a1'),
      ('image', '/media/i1'),
    ]);
  });

  test('missing or empty field label falls back to default', () {
    final d = _build(
      [
        [0],
        [1, 2],
      ],
      fields: const ['', 'Back'],
    );
    expect(d.card.front.single.field, 'Text');
    expect(d.card.back[0].field, 'Back');
    expect(d.card.back[1].field, 'Text');
  });

  test('video and json pass through the resolver', () {
    final d = _build([
      [2],
    ]);
    expect(_items(d.card.front.single), [
      ('json', '/media/j1'),
      ('video', '/media/v1'),
    ]);
  });

  test('out-of-range indexes are skipped and missing back is empty', () {
    final d = _build([
      [-1, 0, 9],
    ]);
    expect(d.card.front, hasLength(1));
    expect(d.card.back, isEmpty);
    expect(_build(const []).card.front, isEmpty);
  });

  test('empty back side yields no slots', () {
    final d = _build([
      [0, 1],
      [],
    ]);
    expect(d.card.front, hasLength(2));
    expect(d.card.back, isEmpty);
  });
}
