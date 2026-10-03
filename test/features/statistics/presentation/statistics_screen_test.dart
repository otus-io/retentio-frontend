import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/statistics/bloc/statistics_cubit.dart';
import 'package:retentio/features/statistics/presentation/statistics_screen.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/review_stats.dart';

import '../../../helpers/fake_statistics_api_interceptor.dart';
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

  testWidgets('loads statistics through the app services', (tester) async {
    final interceptor = attachFakeStatisticsApiInterceptor();
    addTearDown(() => detachFakeStatisticsApiInterceptor(interceptor));

    await tester.pumpWidget(buildTestableWidget(StatisticsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('All decks'), findsOneWidget);
    expect(find.text('Reviews in period'), findsOneWidget);
  });

  testWidgets('shows a load error and retries it', (tester) async {
    var fail = true;
    final cubit = StatisticsCubit(
      loadDecks: () async {
        if (fail) throw Exception('offline');
        return [_deck('a')];
      },
      loadReviewStats: (deckId, days) async => _series(days, 1),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsNothing);
    expect(find.text('Reviews in period'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('shows the generic load failure when the error text is empty', (
    tester,
  ) async {
    final cubit = _PresetStatisticsCubit(
      const StatisticsState(status: StatisticsStatus.error),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider<StatisticsCubit>.value(
          value: cubit,
          child: const StatisticsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load review statistics.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Could not load review statistics.'), findsOneWidget);
  });

  testWidgets('shows a refresh failure and retries the current selection', (
    tester,
  ) async {
    var fail = false;
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) async {
        if (fail) throw Exception('offline');
        return _series(days, 1);
      },
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
      ),
    );
    await tester.pumpAndSettle();

    fail = true;
    await cubit.refresh();
    await tester.pumpAndSettle();

    expect(
      find.text('Update failed. Showing previously loaded data.'),
      findsOneWidget,
    );
    expect(find.text('Reviews in period'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('Update failed. Showing previously loaded data.'),
      findsNothing,
    );
    await cubit.close();
  });

  testWidgets('cancels the deck picker and keeps the selected deck', (
    tester,
  ) async {
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

    await tester.tap(find.text('All decks'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('statistics_deck_picker')),
      const Offset(0, -44),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('statistics_deck_picker_done')));
    await tester.pumpAndSettle();
    expect(cubit.state.selectedDeckId, 'a');

    await tester.tap(find.text('Deck a'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoPicker), findsNothing);
    expect(cubit.state.selectedDeckId, 'a');
    await cubit.close();
  });

  testWidgets('falls back to all decks when the selection is missing', (
    tester,
  ) async {
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) async => _series(days, 1),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
      ),
    );
    await tester.pumpAndSettle();

    await cubit.selectDeck('missing');
    await tester.pumpAndSettle();

    expect(cubit.state.selectedDeckId, 'missing');
    expect(find.text('All decks'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('draws longer ranges and chart tooltips', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = StatisticsCubit(
      loadDecks: () async => [_deck('a')],
      loadReviewStats: (deckId, days) async => _series(days, 1),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider.value(value: cubit, child: const StatisticsView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('90 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90 days'));
    await tester.pumpAndSettle();
    expect(cubit.state.rangeDays, 90);

    await tester.tap(find.text('365 days'));
    await tester.pumpAndSettle();
    expect(cubit.state.rangeDays, 365);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    await _pressChart(tester, 0);
    await _pressChart(tester, 1);
    expect(find.text('Daily activity'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('localizes statistics copy in every supported locale', (
    tester,
  ) async {
    for (final locale in const [Locale('en'), Locale('ja'), Locale('zh')]) {
      late AppLocalizations loc;
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              loc = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
          locale: locale,
        ),
      );

      expect(loc.statistics, isNotEmpty);
      expect(loc.statisticsAllDecks, isNotEmpty);
      expect(loc.statisticsDeckFilter, isNotEmpty);
      expect(loc.statisticsRangeDays(7), contains('7'));
      expect(loc.statisticsPeriodReviews, isNotEmpty);
      expect(loc.statisticsTodayReviews, isNotEmpty);
      expect(loc.statisticsActiveDays, isNotEmpty);
      expect(loc.statisticsDailyAverage, isNotEmpty);
      expect(loc.statisticsDailyActivity, isNotEmpty);
      expect(loc.statisticsWeekdayDistribution, isNotEmpty);
      expect(loc.statisticsUtcNote, isNotEmpty);
      expect(loc.statisticsNoDecks, isNotEmpty);
      expect(loc.statisticsNoActivity, isNotEmpty);
      expect(loc.statisticsLoadFailed, isNotEmpty);
      expect(loc.statisticsRefreshFailed, isNotEmpty);
      expect(loc.statisticsReviewsCount(3), contains('3'));
      expect(loc.statisticsDailyChartSemantics('monday'), contains('monday'));
      expect(loc.statisticsWeekdayChartSemantics('monday'), contains('monday'));
    }
  });
}

Future<void> _pressChart(WidgetTester tester, int index) async {
  final chart = find.byType(BarChart).at(index);
  await tester.ensureVisible(chart);
  await tester.pumpAndSettle();
  final rect = tester.getRect(chart);
  final y = rect.top + rect.height * 0.4;
  for (var step = 0; step < 24; step++) {
    final x = rect.left + 16 + (rect.width - 32) * step / 23;
    final gesture = await tester.startGesture(Offset(x, y));
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }
}

class _PresetStatisticsCubit extends StatisticsCubit {
  _PresetStatisticsCubit(StatisticsState preset)
    : super(
        loadDecks: () async => <Deck>[],
        loadReviewStats: (deckId, days) async => _series(days, 0),
      ) {
    emit(preset);
  }

  @override
  Future<void> loadInitial() async {}
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
