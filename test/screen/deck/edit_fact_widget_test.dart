import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_edit.dart';
import 'package:retentio/screen/deck/providers/deck_scope.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';
import 'package:retentio/widgets/app_button.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_deck_study_bloc.dart';
import '../../helpers/fake_fact_api_interceptor.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  group('FactEdit', () {
    testWidgets('loads fact and saves edits', (tester) async {
      await setupTestEnvironment();
      final interceptor = attachFakeFactApiInterceptor();
      var saved = false;
      final harness = FakeDeckStudyBlocHarness(
        deckId: sampleDeck().id,
        loadResults: [DeckStudyLoadResult(cardDetail: sampleCardDetail())],
      );
      addTearDown(() async {
        detachFakeFactApiInterceptor(interceptor);
        await harness.dispose();
        tearDownTestEnvironment();
      });

      final router = GoRouter(
        initialLocation: '/base',
        routes: [
          GoRoute(
            path: '/base',
            builder: (_, _) => const Scaffold(body: Text('base')),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, _) => Scaffold(
              body: FactEdit(
                deck: sampleDeck(),
                factId: 'fact-test-1',
                onSaved: () async {
                  saved = true;
                },
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeckProvider.overrideWithValue(sampleDeck()),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
          child: BlocProvider(
            create: (_) => DeckCreateCubit(
              name: '',
              rate: kDeckEditorRateDefault,
              deckId: '',
              cardType: DeckCardType.add,
            ),
            child: MaterialApp.router(
              locale: const Locale('en'),
              supportedLocales: const [Locale('en'), Locale('zh')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
              ),
              routerConfig: router,
            ),
          ),
        ),
      );

      router.push('/edit');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('FieldA'), findsOneWidget);
      expect(find.text('FieldB'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      final alphaField = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == 'Alpha',
      );
      expect(alphaField, findsOneWidget);
      await tester.enterText(alphaField, 'Alpha updated');
      await tester.pump();

      final saveButton = find.byType(AppButton);
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(interceptor.patchFactCount, 1);
      expect(saved, isTrue);
    });
  });
}
