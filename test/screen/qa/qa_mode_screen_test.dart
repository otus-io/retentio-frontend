import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/qa/qa_mode_screen.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/widgets/app_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_qa_api_adapter.dart';
import '../../helpers/test_wrapper.dart';

Deck _importedDeck() => Deck.fromJson({
  'id': 'imp-1',
  'name': 'Imported deck',
  'rate': 30,
  'fields': ['日文', '中文'],
  'min_interval': 60,
  'def_interval': 300,
  'max_interval': 86400,
  'source_deck_id': 'src-1',
  'source_version': 15,
});

void main() {
  late FakeQaApiAdapter adapter;

  setUp(() async {
    await setupTestEnvironment();
    await ApiService.clearToken();
    SharedPreferences.setMockInitialValues({});
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
  });

  tearDown(() {
    AppToast.dismiss();
    networkDioClient.dio.httpClientAdapter = IOHttpClientAdapter();
    tearDownTestEnvironment();
  });

  void useAdapter({
    List<String> factIds = const ['fact-1', 'fact-2'],
    Map<String, dynamic>? stats,
    bool qualityPutFails = false,
    bool contributionFails = false,
  }) {
    adapter = FakeQaApiAdapter(
      factIds: factIds,
      entriesByFactId: {
        'fact-1': [
          {'text': 'headword'},
          {'text': 'meaning'},
        ],
        'fact-2': [
          {'text': 'second'},
          {'image': 'img-1'},
        ],
      },
      qualityByFactId: {
        'fact-1': {
          '0': {
            'text': {'score': 10, 'model': 'human'},
          },
        },
      },
      stats: stats,
      qualityPutFails: qualityPutFails,
      contributionFails: contributionFails,
    );
    networkDioClient.dio.httpClientAdapter = adapter;
  }

  Future<void> startQaWalk(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Start QA'));
    await tester.pumpAndSettle();
  }

  Future<void> pumpQaMode(
    WidgetTester tester, {
    Deck? deck,
    bool startWalk = true,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => QaModeScreen(deck: deck ?? _importedDeck()),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (startWalk) await startQaWalk(tester);
  }

  group('qaAudioUrl', () {
    test('builds a snapshot media URL and passes absolute ones through', () {
      expect(qaAudioUrl(audioId: ' ', sourceVersion: 15), isNull);
      expect(
        qaAudioUrl(audioId: 'aud1', sourceVersion: 15),
        '/api/media/aud1?v=15',
      );
      expect(qaAudioUrl(audioId: 'aud1', sourceVersion: 0), '/api/media/aud1');
      expect(
        qaAudioUrl(audioId: '/api/media/aud1', sourceVersion: 15),
        '/api/media/aud1',
      );
      expect(
        qaAudioUrl(audioId: 'https://cdn/aud1', sourceVersion: 15),
        'https://cdn/aud1',
      );
      expect(
        qaAudioUrl(audioId: 'http://cdn/aud1', sourceVersion: 15),
        'http://cdn/aud1',
      );
    });

    test('prefers pinned media_versions over deck sourceVersion', () {
      expect(
        qaAudioUrl(
          audioId: 'eloc-00gqha52-2-21359-6677192576',
          sourceVersion: 19,
          mediaVersions: {'eloc-00gqha52-2-21359-6677192576': 1},
        ),
        '/api/media/eloc-00gqha52-2-21359-6677192576?v=1',
      );
    });
  });

  group('QaModeScreen', () {
    testWidgets('lists deck columns all unchecked by default', (tester) async {
      useAdapter(
        stats: {
          'verified_aspects': 1,
          'total_aspects': 3,
          'columns': {
            '0': {'verified_aspects': 1, 'total_aspects': 2},
            '1': {'verified_aspects': 0, 'total_aspects': 2},
          },
        },
      );
      await pumpQaMode(tester);

      expect(find.text('日文'), findsOneWidget);
      expect(find.text('中文'), findsOneWidget);
      expect(find.text('headword'), findsOneWidget);
      expect(find.text('日文 50%'), findsOneWidget);
      expect(find.text('中文 0%'), findsOneWidget);
      expect(find.textContaining('Fact 1 / 2'), findsOneWidget);

      final checkboxes = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(checkboxes.map((c) => c.value), [false, false]);
    });

    testWidgets('Next stays disabled until every scoreable column is checked', (
      tester,
    ) async {
      useAdapter();
      await pumpQaMode(tester);

      expect(find.widgetWithText(OutlinedButton, 'Next'), findsOneWidget);

      await tester.tap(find.text('日文'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'Next'), findsOneWidget);

      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Previous'), findsNothing);
    });

    testWidgets('Previous is disabled when every scoreable column is checked', (
      tester,
    ) async {
      useAdapter();
      await pumpQaMode(tester);

      await tester.tap(find.text('日文'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Previous'), findsOneWidget);

      await tester.tap(find.text('日文'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Previous'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Previous'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('Next sends quality for checked columns and advances', (
      tester,
    ) async {
      useAdapter();
      await pumpQaMode(tester);

      await tester.tap(find.text('日文'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(adapter.qualityPuts, hasLength(1));
      expect(
        (adapter.qualityPuts.first['entries'] as Map).keys,
        containsAll(<String>['0', '1']),
      );
      expect(find.text('second'), findsOneWidget);
      expect(find.textContaining('Fact 2 / 2'), findsOneWidget);
    });

    testWidgets('Next verifies the last fact without requiring hasNext', (
      tester,
    ) async {
      useAdapter(factIds: const ['fact-1']);
      await pumpQaMode(tester);

      expect(find.textContaining('Fact 1 / 1'), findsOneWidget);

      await tester.tap(find.text('日文'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();

      final next = find.widgetWithText(FilledButton, 'Next');
      expect(next, findsOneWidget);
      expect(tester.widget<FilledButton>(next).onPressed, isNotNull);

      await tester.tap(next);
      await tester.pumpAndSettle();

      expect(adapter.qualityPuts, hasLength(1));
      expect(find.textContaining('Fact 1 / 1'), findsOneWidget);
    });

    testWidgets('Verified is not tappable and fills when all columns checked', (
      tester,
    ) async {
      useAdapter();
      await pumpQaMode(tester);

      expect(find.widgetWithText(OutlinedButton, 'Verified'), findsOneWidget);

      await tester.tap(find.text('日文'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'Verified'), findsOneWidget);

      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Verified'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Verified'));
      await tester.pumpAndSettle();
      expect(adapter.qualityPuts, isEmpty);
    });

    testWidgets('shows the API message when the PUT fails on Next', (
      tester,
    ) async {
      useAdapter(qualityPutFails: true);
      await pumpQaMode(tester);

      await tester.tap(find.text('日文'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Fact is not in the pinned snapshot'), findsOneWidget);
      expect(find.textContaining('Fact 1 / 2'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Next walks to the next fact and disables empty columns', (
      tester,
    ) async {
      useAdapter();
      await pumpQaMode(tester);

      await tester.tap(find.text('日文'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(find.textContaining('Fact 2 / 2'), findsOneWidget);
      expect(find.text('Nothing to verify in this column'), findsOneWidget);
      final checkboxes = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(checkboxes.last.onChanged, isNull);
    });

    testWidgets('editing a column sends a fact_edit contribution', (
      tester,
    ) async {
      useAdapter();
      await pumpQaMode(tester);

      await tester.tap(find.byIcon(LucideIcons.pencil).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save fact'));
      await tester.pumpAndSettle();

      expect(adapter.factPatches, contains('fact-1'));
      expect(adapter.contributionPosts, hasLength(1));
      expect(adapter.contributionPosts.first['entry_index'], 0);
      expect(find.text('Edit sent to the author'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('falls back to a numbered label for undeclared columns', (
      tester,
    ) async {
      useAdapter();
      await pumpQaMode(
        tester,
        deck: Deck.fromJson({
          'id': 'imp-1',
          'name': 'Imported deck',
          'rate': 30,
          'fields': ['', ''],
          'min_interval': 60,
          'def_interval': 300,
          'max_interval': 86400,
          'source_deck_id': 'src-1',
          'source_version': 15,
        }),
      );

      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
    });

    testWidgets('column picker shows completion percent for every column', (
      tester,
    ) async {
      useAdapter(
        stats: {
          'columns': {
            '0': {'verified_aspects': 1, 'total_aspects': 2},
            '1': {'verified_aspects': 0, 'total_aspects': 2},
          },
        },
      );
      await pumpQaMode(tester, startWalk: false);

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('column picker limits the walk to selected columns', (
      tester,
    ) async {
      useAdapter(
        stats: {
          'verified_aspects': 1,
          'total_aspects': 2,
          'columns': {
            '0': {'verified_aspects': 1, 'total_aspects': 2},
          },
        },
      );
      await pumpQaMode(tester, startWalk: false);

      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();
      await startQaWalk(tester);

      expect(find.text('日文'), findsOneWidget);
      expect(find.text('中文'), findsNothing);
      expect(find.text('日文 50%'), findsOneWidget);
    });

    testWidgets('shows the API message when the fact_edit POST fails', (
      tester,
    ) async {
      useAdapter(contributionFails: true);
      await pumpQaMode(tester);

      await tester.tap(find.byIcon(LucideIcons.pencil).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save fact'));
      await tester.pumpAndSettle();

      expect(
        find.text('Daily contribution limit reached. Try again tomorrow.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('shows an empty message when the deck has no facts', (
      tester,
    ) async {
      useAdapter(factIds: const []);
      await pumpQaMode(tester);

      expect(
        find.text('This imported deck has no facts to review.'),
        findsOneWidget,
      );
    });

    testWidgets('shows a failure message when the fact cannot load', (
      tester,
    ) async {
      useAdapter(factIds: const ['missing']);
      await pumpQaMode(tester);

      expect(find.text('Could not load this fact.'), findsOneWidget);
    });
  });
}
