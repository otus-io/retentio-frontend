import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/statistics/bloc/statistics_cubit.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/review_stats.dart';

void main() {
  test('copyWith keeps omitted fields and replaces nullable ones', () {
    final decks = [_deck('a')];
    final series = _series(7, 1);
    final original = StatisticsState(
      decks: decks,
      selectedDeckId: 'a',
      rangeDays: 7,
      series: series,
      status: StatisticsStatus.loaded,
      isRefreshing: true,
      error: 'load',
      refreshError: 'refresh',
    );

    final unchanged = original.copyWith();
    expect(unchanged.decks, same(decks));
    expect(unchanged.selectedDeckId, 'a');
    expect(unchanged.rangeDays, 7);
    expect(unchanged.series, same(series));
    expect(unchanged.status, StatisticsStatus.loaded);
    expect(unchanged.isRefreshing, isTrue);
    expect(unchanged.error, 'load');
    expect(unchanged.refreshError, 'refresh');

    final replaced = original.copyWith(
      decks: [_deck('b')],
      selectedDeckId: 'b',
      rangeDays: 30,
      series: _series(30, 2),
      status: StatisticsStatus.error,
      isRefreshing: false,
      error: 'offline',
      refreshError: 'stale',
    );
    expect(replaced.decks.single.id, 'b');
    expect(replaced.selectedDeckId, 'b');
    expect(replaced.rangeDays, 30);
    expect(replaced.series?.days, hasLength(30));
    expect(replaced.status, StatisticsStatus.error);
    expect(replaced.isRefreshing, isFalse);
    expect(replaced.error, 'offline');
    expect(replaced.refreshError, 'stale');

    final cleared = replaced.copyWith(
      selectedDeckId: null,
      series: null,
      error: null,
      refreshError: null,
    );
    expect(cleared.selectedDeckId, isNull);
    expect(cleared.series, isNull);
    expect(cleared.error, isNull);
    expect(cleared.refreshError, isNull);
    expect(cleared.decks.single.id, 'b');
  });

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

  test(
    'restores the visible range and retries a failed range change',
    () async {
      var failSevenDays = true;
      final cubit = StatisticsCubit(
        loadDecks: () async => [_deck('a')],
        loadReviewStats: (deckId, days) async {
          if (days == 7 && failSevenDays) throw Exception('offline');
          return _series(days, 2);
        },
      );
      await _waitForLoaded(cubit);
      final previousSeries = cubit.state.series;

      await cubit.selectRange(7);

      expect(cubit.state.status, StatisticsStatus.loaded);
      expect(cubit.state.rangeDays, 30);
      expect(cubit.state.series, same(previousSeries));
      expect(cubit.state.refreshError, 'offline');

      failSevenDays = false;
      await cubit.retry();

      expect(cubit.state.rangeDays, 7);
      expect(cubit.state.series?.days, hasLength(7));
      expect(cubit.state.refreshError, isNull);
      await cubit.close();
    },
  );

  test('restores the visible deck and retries a failed deck change', () async {
    var failDeckB = false;
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a'), _deck('b')],
      loadReviewStats: (deckId, days) async {
        if (deckId == 'b' && failDeckB) throw Exception('offline');
        return _series(days, deckId == 'a' ? 1 : 2);
      },
    );
    await _waitForLoaded(cubit);
    final previousSeries = cubit.state.series;

    failDeckB = true;
    await cubit.refresh();
    await cubit.selectDeck('b');

    expect(cubit.state.selectedDeckId, isNull);
    expect(cubit.state.series, same(previousSeries));
    expect(cubit.state.refreshError, 'offline');

    failDeckB = false;
    await cubit.retry();

    expect(cubit.state.selectedDeckId, 'b');
    expect(cubit.state.series?.days.first.count, 2);
    expect(cubit.state.refreshError, isNull);
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

  test('reloads when retrying before any series exists', () async {
    var decks = <Deck>[];
    final cubit = StatisticsCubit(
      loadDecks: () async => decks,
      loadReviewStats: (deckId, days) async => _series(days, 2),
    );
    await _waitForLoaded(cubit);
    expect(cubit.state.series, isNull);

    decks = [_deck('a')];
    await cubit.retry();

    expect(cubit.state.status, StatisticsStatus.loaded);
    expect(cubit.state.series?.days, hasLength(30));
    expect(cubit.state.series?.days.first.count, 2);
    await cubit.close();
  });

  test('refreshes the selected deck and replaces cached counts', () async {
    var count = 1;
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a'), _deck('b')],
      loadReviewStats: (deckId, days) async => _series(days, count),
    );
    await _waitForLoaded(cubit);
    await cubit.selectDeck('b');

    count = 5;
    await cubit.refresh();

    expect(cubit.state.selectedDeckId, 'b');
    expect(cubit.state.rangeDays, 30);
    expect(cubit.state.isRefreshing, isFalse);
    expect(cubit.state.refreshError, isNull);
    expect(cubit.state.series?.days.first.count, 5);
    await cubit.close();
  });

  test('leaves an in-flight selection change running', () async {
    final pendingSeven = Completer<ReviewStatsSeries>();
    var loads = 0;
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) {
        loads++;
        if (days == 7) return pendingSeven.future;
        return Future.value(_series(days, 1));
      },
    );
    await _waitForLoaded(cubit);
    final loadsAfterInitial = loads;

    final rangeRequest = cubit.selectRange(7);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isRefreshing, isTrue);

    await cubit.refresh();
    expect(loads, loadsAfterInitial + 1);
    expect(cubit.state.rangeDays, 7);

    pendingSeven.complete(_series(7, 4));
    await rangeRequest;

    expect(cubit.state.rangeDays, 7);
    expect(cubit.state.series?.days, hasLength(7));
    expect(cubit.state.series?.days.first.count, 4);
    expect(cubit.state.isRefreshing, isFalse);
    await cubit.close();
  });

  test('ignores a refresh that finishes after a newer request', () async {
    final refreshGate = Completer<ReviewStatsSeries>();
    var phase = 'initial';
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) {
        if (phase == 'refresh') return refreshGate.future;
        return Future.value(_series(days, days == 7 ? 4 : 1));
      },
    );
    await _waitForLoaded(cubit);

    phase = 'refresh';
    final refreshRequest = cubit.refresh();
    await Future<void>.delayed(Duration.zero);
    phase = 'range';
    await cubit.selectRange(7);
    refreshGate.complete(_series(30, 9));
    await refreshRequest;

    expect(cubit.state.rangeDays, 7);
    expect(cubit.state.series?.days.first.count, 4);
    expect(cubit.state.isRefreshing, isFalse);
    await cubit.close();
  });

  test('drops a refresh result after the cubit is closed', () async {
    final refreshGate = Completer<ReviewStatsSeries>();
    var refreshing = false;
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) =>
          refreshing ? refreshGate.future : Future.value(_series(days, 1)),
    );
    await _waitForLoaded(cubit);

    refreshing = true;
    final refreshRequest = cubit.refresh();
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    refreshGate.complete(_series(30, 9));
    await refreshRequest;

    expect(cubit.isClosed, isTrue);
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
