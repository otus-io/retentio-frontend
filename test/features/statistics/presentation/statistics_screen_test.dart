import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/statistics/bloc/statistics_cubit.dart';
import 'package:retentio/features/statistics/presentation/statistics_screen.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/review_stats.dart';

import '../../../helpers/test_wrapper.dart';

void main() {
  setUpAll(setupTestEnvironment);
  tearDownAll(tearDownTestEnvironment);

  testWidgets('shows the default all-decks 30-day dashboard', (tester) async {
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a'), _deck('b')],
      loadReviewStats: (deckId, days) async => _series(days, 1),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('All decks'), findsOneWidget);
    expect(find.byKey(const Key('statistics_deck_filter')), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.text('Reviews in period'), findsOneWidget);
    expect(find.text('Daily activity'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Reviews by weekday'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Reviews by weekday'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('switches to a single deck and a different range', (
    tester,
  ) async {
    final calls = <(String, int)>[];
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a'), _deck('b')],
      loadReviewStats: (deckId, days) async {
        calls.add((deckId, days));
        return _series(days, 1);
      },
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('All decks'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('statistics_deck_picker')),
      const Offset(0, -44),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('statistics_deck_picker_done')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();

    expect(cubit.state.selectedDeckId, 'a');
    expect(cubit.state.rangeDays, 7);
    expect(calls, contains(('a', 7)));
    await cubit.close();
  });

  testWidgets('keeps filters visible and replaces only content while loading', (
    tester,
  ) async {
    final pendingRange = Completer<ReviewStatsSeries>();
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) =>
          days == 7 ? pendingRange.future : Future.value(_series(days, 1)),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('7 days'));
    await tester.pump();

    expect(find.byKey(const Key('statistics_deck_filter')), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);
    expect(find.byKey(const Key('statistics_content_loading')), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Reviews in period'), findsNothing);

    pendingRange.complete(_series(7, 1));
    await tester.pumpAndSettle();
    await cubit.close();
  });

  testWidgets('shows a localized empty state when there are no decks', (
    tester,
  ) async {
    final cubit = StatisticsCubit(
      loadDecks: () async => [],
      loadReviewStats: (deckId, days) async => _series(days, 0),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('创建卡组后即可开始记录复习活动。'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('shows a zero-activity state without charts', (tester) async {
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) async => _series(days, 0),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No review activity in this period.'), findsOneWidget);
    expect(find.text('Daily activity'), findsNothing);
    await cubit.close();
  });

  testWidgets('fits a narrow dark screen without layout exceptions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) async => _series(days, 1),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
        locale: const Locale('ja'),
        themeMode: ThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('統計'), findsOneWidget);
    await cubit.close();
  });
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
