import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/statistics/bloc/statistics_cubit.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/review_stats.dart';

void main() {
  test('defaults to all decks and 30 days, aggregating exact dates', () async {
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a'), _deck('b')],
      loadReviewStats: (deckId, days) async =>
          _series(days, deckId == 'a' ? 1 : 2),
    );
    await _waitForLoaded(cubit);

    expect(cubit.state.selectedDeckId, isNull);
    expect(cubit.state.rangeDays, 30);
    expect(cubit.state.series?.days, hasLength(30));
    expect(cubit.state.series?.days.first.count, 3);
    await cubit.close();
  });

  test('limits all-deck requests to four concurrent calls', () async {
    var active = 0;
    var maximum = 0;
    final cubit = StatisticsCubit(
      loadDecks: () async => List.generate(9, (index) => _deck('$index')),
      loadReviewStats: (deckId, days) async {
        active++;
        maximum = active > maximum ? active : maximum;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active--;
        return _series(days, 1);
      },
    );
    await _waitForLoaded(cubit);

    expect(maximum, 4);
    await cubit.close();
  });

  test('does not expose a partial aggregate when one deck fails', () async {
    var shouldFail = true;
    final calls = <String>[];
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a'), _deck('b')],
      loadReviewStats: (deckId, days) async {
        calls.add(deckId);
        if (deckId == 'b' && shouldFail) throw Exception('failed deck');
        return _series(days, 1);
      },
    );
    await cubit.stream.firstWhere(
      (state) => state.status == StatisticsStatus.error,
    );

    expect(cubit.state.series, isNull);
    expect(cubit.state.error, 'failed deck');

    shouldFail = false;
    await cubit.loadInitial();
    expect(calls.where((id) => id == 'a'), hasLength(2));
    expect(cubit.state.status, StatisticsStatus.loaded);
    await cubit.close();
  });

  test('keeps old data and marks a failed refresh', () async {
    var fail = false;
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) async {
        if (fail) throw Exception('offline');
        return _series(days, 2);
      },
    );
    await _waitForLoaded(cubit);
    final before = cubit.state.series;

    fail = true;
    await cubit.refresh();

    expect(cubit.state.status, StatisticsStatus.loaded);
    expect(cubit.state.series, same(before));
    expect(cubit.state.refreshError, 'offline');
    await cubit.close();
  });

  test('ignores an older response after the range changes again', () async {
    final pendingSeven = Completer<ReviewStatsSeries>();
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) {
        if (days == 7) return pendingSeven.future;
        return Future.value(_series(days, days));
      },
    );
    await _waitForLoaded(cubit);

    final sevenRequest = cubit.selectRange(7);
    await Future<void>.delayed(Duration.zero);
    await cubit.selectRange(90);
    pendingSeven.complete(_series(7, 7));
    await sevenRequest;

    expect(cubit.state.rangeDays, 90);
    expect(cubit.state.series?.days, hasLength(90));
    await cubit.close();
  });

  test('keeps existing data available while a range change loads', () async {
    final pendingSeven = Completer<ReviewStatsSeries>();
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) =>
          days == 7 ? pendingSeven.future : Future.value(_series(days, 1)),
    );
    await _waitForLoaded(cubit);
    final existingSeries = cubit.state.series;

    final request = cubit.selectRange(7);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.rangeDays, 7);
    expect(cubit.state.series, same(existingSeries));
    expect(cubit.state.isRefreshing, isTrue);

    pendingSeven.complete(_series(7, 1));
    await request;
    await cubit.close();
  });
}

Future<void> _waitForLoaded(StatisticsCubit cubit) async {
  if (cubit.state.status == StatisticsStatus.loaded) return;
  await cubit.stream.firstWhere(
    (state) => state.status == StatisticsStatus.loaded,
  );
}

Deck _deck(String id) => Deck.fromJson({
  'id': id,
  'name': 'Deck $id',
  'rate': 10,
  'fields': ['Front', 'Back'],
});

ReviewStatsSeries _series(int days, int count) {
  final end = DateTime.utc(2026, 9, 19);
  return ReviewStatsSeries(
    timezone: 'UTC',
    days: List.generate(
      days,
      (index) => ReviewDay(
        day: end.subtract(Duration(days: days - index - 1)),
        count: count,
      ),
    ),
  );
}
