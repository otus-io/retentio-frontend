import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_scheduler.dart';

OfflineCard _card(
  String id, {
  int last = 0,
  int due = 100,
  String? factId,
  bool hidden = false,
}) => OfflineCard(
  deckId: 'd1',
  id: id,
  factId: factId ?? 'f-$id',
  template: const [
    [0],
    [1],
  ],
  lastReview: last,
  dueDate: due,
  hidden: hidden,
);

void main() {
  group('selectNextCards', () {
    test('empty input yields empty selection', () {
      final s = selectNextCards(const [], nowSec: 10);
      expect(s.isEmpty, isTrue);
      expect(s.card, isNull);
      expect(s.nextCard, isNull);
    });

    test('picks highest urgency and second as lookahead', () {
      final s = selectNextCards([
        _card('a', due: 200),
        _card('b', due: 50),
        _card('c', due: 100),
      ], nowSec: 50);
      expect(s.isEmpty, isFalse);
      expect(s.card!.id, 'b');
      expect(s.urgency, 1.0);
      expect(s.nextCard!.id, 'c');
      expect(s.nextUrgency, 0.5);
    });

    test('urgency is rounded to float32', () {
      final s = selectNextCards([_card('a', due: 3)], nowSec: 1);
      final expected = (Float32List(1)..[0] = 1 / 3)[0];
      expect(s.urgency, expected);
      expect(s.urgency, isNot(1 / 3));
    });

    test('ties break by smaller card id for primary and lookahead', () {
      final s = selectNextCards([
        _card('c'),
        _card('b'),
        _card('a', due: 400),
      ], nowSec: 50);
      expect(s.card!.id, 'b');
      expect(s.nextCard!.id, 'c');

      final three = selectNextCards([
        _card('z'),
        _card('y'),
        _card('x'),
      ], nowSec: 50);
      expect(three.card!.id, 'x');
      expect(three.nextCard!.id, 'y');
    });

    test('skips hidden and corrupted cards', () {
      final s = selectNextCards([
        _card('a', hidden: true),
        _card('b', last: 100, due: 100),
        _card('c', last: 100, due: 90),
        _card('d', due: 1000),
      ], nowSec: 50);
      expect(s.card!.id, 'd');
      expect(s.nextCard, isNull);
      expect(s.nextUrgency, 0);
    });

    test('not-yet-due card can be picked', () {
      final s = selectNextCards([_card('a', due: 1000)], nowSec: 10);
      expect(s.card!.id, 'a');
      expect(s.urgency, closeTo(0.01, 1e-6));
    });

    test('filters by allowed fact ids', () {
      final cards = [
        _card('a', due: 50, factId: 'f1'),
        _card('b', due: 500, factId: 'f2'),
      ];
      final s = selectNextCards(cards, nowSec: 50, allowedFactIds: {'f2'});
      expect(s.card!.id, 'b');
      expect(s.nextCard, isNull);
      expect(
        selectNextCards(cards, nowSec: 50, allowedFactIds: {}).isEmpty,
        isTrue,
      );
    });
  });

  group('clampFutureLastReview', () {
    test('clamps future lastReview and preserves interval', () {
      final c = clampFutureLastReview(_card('a', last: 200, due: 201), 100);
      expect(c.lastReview, 100);
      expect(c.dueDate, 101);
    });

    test('returns same card when lastReview is not in the future', () {
      final card = _card('a', last: 100, due: 200);
      expect(identical(clampFutureLastReview(card, 100), card), isTrue);
    });
  });

  group('applyReview', () {
    test('sets due from last review and marks dirty', () {
      final c = applyReview(
        _card('a'),
        intervalSec: 60,
        lastReviewSec: 90,
        nowSec: 100,
      );
      expect(c.lastReview, 90);
      expect(c.dueDate, 150);
      expect(c.dirty, isTrue);
    });

    test('clamps future lastReview to now', () {
      final c = applyReview(
        _card('a'),
        intervalSec: 60,
        lastReviewSec: 500,
        nowSec: 100,
      );
      expect(c.lastReview, 100);
      expect(c.dueDate, 160);
    });
  });

  test('applyHide marks hidden and dirty', () {
    final c = applyHide(_card('a'));
    expect(c.hidden, isTrue);
    expect(c.dirty, isTrue);
  });
}
