import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
import 'package:retentio/screen/deck/bloc/fact_submit_guard_cubit.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_add.dart';
import 'package:retentio/screen/decks/providers/deck_list.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_toast.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/connectivity_mock.dart';
import '../../helpers/fake_deck_list_notifier.dart';
import '../../helpers/fake_fact_api_interceptor.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  group('FactAdd', () {
    testWidgets(
      'save fact calls API and shows success when deckListProvider is available',
      (tester) async {
        await setupTestEnvironment();
        final interceptor = attachFakeFactApiInterceptor();
        addTearDown(() {
          detachFakeFactApiInterceptor(interceptor);
          tearDownTestEnvironment();
        });

        final deck = sampleDeck();

        await tester.pumpWidget(
          buildTestableWidgetWithOverrides(
            Scaffold(body: FactAdd(deck: deck)),
            overrides: [
              deckListProvider.overrideWith(() => FakeDeckListNotifier([deck])),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Front'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(find.byTooltip('Add row'), findsNothing);
        expect(find.byTooltip('Remove row'), findsNothing);

        final textFields = find.byType(TextField);
        expect(textFields, findsNWidgets(2));

        await tester.enterText(textFields.at(0), 'Hello');
        await tester.enterText(textFields.at(1), 'World');
        await tester.pump();

        await tester.tap(find.text('Save fact'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(interceptor.addFactsCount, 1);
        expect(find.text('Fact added'), findsOneWidget);

        AppToast.dismiss();
        await tester.pumpAndSettle();
      },
    );

    group('verified checkbox', () {
      Future<FakeFactApiInterceptor> pumpComposer(
        WidgetTester tester, {
        String sourceDeckId = '',
      }) async {
        await setupTestEnvironment();
        final interceptor = attachFakeFactApiInterceptor();
        addTearDown(() {
          detachFakeFactApiInterceptor(interceptor);
          tearDownTestEnvironment();
        });
        final deck = sampleDeck(sourceDeckId: sourceDeckId);
        await tester.pumpWidget(
          buildTestableWidgetWithOverrides(
            Scaffold(body: FactAdd(deck: deck)),
            overrides: [
              deckListProvider.overrideWith(() => FakeDeckListNotifier([deck])),
            ],
          ),
        );
        await tester.pumpAndSettle();
        return interceptor;
      }

      Future<void> saveFact(WidgetTester tester) async {
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Hello');
        await tester.enterText(textFields.at(1), 'World');
        await tester.tap(find.text('Save fact'));
        await tester.pumpAndSettle();
        AppToast.dismiss();
        await tester.pumpAndSettle();
      }

      bool isChecked(WidgetTester tester) =>
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value!;

      testWidgets('is off by default and sends no sign-off', (tester) async {
        final interceptor = await pumpComposer(tester);

        expect(isChecked(tester), isFalse);
        await saveFact(tester);

        expect(interceptor.addFactsCount, 1);
        expect(
          (interceptor.lastAddFactsBody as Map).containsKey('verified'),
          isFalse,
        );
      });

      testWidgets('ticked sends the sign-off, then clears for the next fact', (
        tester,
      ) async {
        final interceptor = await pumpComposer(tester);

        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        expect(isChecked(tester), isTrue);
        await saveFact(tester);

        expect((interceptor.lastAddFactsBody as Map)['verified'], isTrue);
        expect(isChecked(tester), isFalse);
      });

      testWidgets('is hidden on an imported deck', (tester) async {
        final interceptor = await pumpComposer(tester, sourceDeckId: 'src-1');

        expect(find.byType(CheckboxListTile), findsNothing);
        await saveFact(tester);

        expect(
          (interceptor.lastAddFactsBody as Map).containsKey('verified'),
          isFalse,
        );
      });
    });

    group('imported deck staging', () {
      Future<({List<String?> unsent, List<String?> sent, String toast})>
      addOnImport(
        WidgetTester tester,
        List<List<String>?> factIdsResponses, {
        bool sendFails = false,
      }) async {
        await setupTestEnvironment();
        final interceptor = attachFakeFactApiInterceptor();
        interceptor.factIdsResponses.addAll(factIdsResponses);
        interceptor.contributionAddFails = sendFails;
        addTearDown(() {
          detachFakeFactApiInterceptor(interceptor);
          tearDownTestEnvironment();
        });
        final deck = sampleDeck(sourceDeckId: 'src-1');
        await tester.pumpWidget(
          buildTestableWidgetWithOverrides(
            Scaffold(body: FactAdd(deck: deck)),
            overrides: [
              deckListProvider.overrideWith(() => FakeDeckListNotifier([deck])),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Hello');
        await tester.enterText(textFields.at(1), 'World');
        await tester.tap(find.text('Save fact'));
        await tester.pumpAndSettle();
        expect(interceptor.addFactsCount, 1);
        final toasts = [
          'Fact added',
          'Fact added and sent to the author',
          "Fact added. Couldn't send it to the author yet; "
              'retry from Unsent contributions.',
        ].where((t) => find.text(t).evaluate().isNotEmpty).toList();
        final store = PendingContributionsStore.of;
        final unsent = await tester.runAsync(() => store.listPending(deck.id));
        final sent = await tester.runAsync(() => store.listSent(deck.id));
        AppToast.dismiss();
        await tester.pumpAndSettle();
        return (
          unsent: [for (final item in unsent!) item.factId],
          sent: [for (final item in sent!) item.factId],
          toast: toasts.single,
        );
      }

      testWidgets('sends the new fact to the author', (tester) async {
        final r = await addOnImport(tester, [
          ['old'],
          ['old', 'new'],
        ]);

        expect(r.sent, ['new']);
        expect(r.unsent, isEmpty);
        expect(r.toast, 'Fact added and sent to the author');
      });

      testWidgets('keeps it unsent when sending fails', (tester) async {
        final r = await addOnImport(tester, [
          ['old'],
          ['old', 'new'],
        ], sendFails: true);

        expect(r.unsent, ['new']);
        expect(r.sent, isEmpty);
        expect(r.toast, startsWith("Fact added. Couldn't send it"));
      });

      testWidgets('sends nothing when no new fact appears', (tester) async {
        final r = await addOnImport(tester, [
          ['old'],
          ['old'],
        ]);

        expect(r.unsent, isEmpty);
        expect(r.sent, isEmpty);
        expect(r.toast, 'Fact added');
      });

      testWidgets('sends nothing when the baseline list fails', (tester) async {
        final r = await addOnImport(tester, [
          null,
          ['old', 'new'],
        ]);

        expect(r.unsent, isEmpty);
        expect(r.sent, isEmpty);
      });

      testWidgets('sends nothing when the follow-up list fails', (
        tester,
      ) async {
        final r = await addOnImport(tester, [
          ['old'],
          null,
        ]);

        expect(r.unsent, isEmpty);
        expect(r.sent, isEmpty);
      });
    });

    testWidgets('offline shows a network message and skips the API', (
      tester,
    ) async {
      await setupTestEnvironment();
      ConnectivityMock.interfaces = const ['none'];
      final interceptor = attachFakeFactApiInterceptor();
      addTearDown(() {
        detachFakeFactApiInterceptor(interceptor);
        tearDownTestEnvironment();
      });

      final deck = sampleDeck();
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(body: FactAdd(deck: deck)),
          overrides: [
            deckListProvider.overrideWith(() => FakeDeckListNotifier([deck])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Hello');
      await tester.enterText(textFields.at(1), 'World');
      await tester.pump();

      await tester.tap(find.text('Save fact'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(interceptor.addFactsCount, 0);
      expect(
        find.text(
          'No network connection. Please check your internet settings.',
        ),
        findsOneWidget,
      );

      AppToast.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('a pending connectivity check blocks a second submit', (
      tester,
    ) async {
      await setupTestEnvironment();
      final interceptor = attachFakeFactApiInterceptor();
      final gate = Completer<bool>();
      var checks = 0;
      final guard = FactSubmitGuardCubit(
        isOnline: () {
          checks++;
          return gate.future;
        },
      );
      addTearDown(() async {
        detachFakeFactApiInterceptor(interceptor);
        await guard.close();
        tearDownTestEnvironment();
      });

      final deck = sampleDeck();
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: FactAdd(deck: deck, submitGuard: guard),
          ),
          overrides: [
            deckListProvider.overrideWith(() => FakeDeckListNotifier([deck])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Hello');
      await tester.enterText(textFields.at(1), 'World');
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(checks, 1);

      gate.complete(true);
      await tester.pumpAndSettle();
      expect(interceptor.addFactsCount, 1);

      AppToast.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('unmounting during the connectivity check skips the API', (
      tester,
    ) async {
      await setupTestEnvironment();
      final interceptor = attachFakeFactApiInterceptor();
      final gate = Completer<bool>();
      final guard = FactSubmitGuardCubit(isOnline: () => gate.future);
      addTearDown(() async {
        detachFakeFactApiInterceptor(interceptor);
        await guard.close();
        tearDownTestEnvironment();
      });

      final deck = sampleDeck();
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: FactAdd(deck: deck, submitGuard: guard),
          ),
          overrides: [
            deckListProvider.overrideWith(() => FakeDeckListNotifier([deck])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Hello');
      await tester.enterText(textFields.at(1), 'World');
      await tester.pump();

      await tester.tap(find.text('Save fact'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      gate.complete(true);
      await tester.pumpAndSettle();

      expect(interceptor.addFactsCount, 0);
    });

    testWidgets('saving resets the media target to the first row', (
      tester,
    ) async {
      await setupTestEnvironment();
      final interceptor = attachFakeFactApiInterceptor();
      addTearDown(() {
        detachFakeFactApiInterceptor(interceptor);
        tearDownTestEnvironment();
      });

      final deck = sampleDeck();
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(body: FactAdd(deck: deck)),
          overrides: [
            deckListProvider.overrideWith(() => FakeDeckListNotifier([deck])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Hello');
      // Focusing the second row makes it the sticky media target.
      await tester.enterText(textFields.at(1), 'World');
      await tester.pump();

      await tester.tap(find.text('Save fact'));
      await tester.pumpAndSettle();
      expect(interceptor.addFactsCount, 1);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      final dynamic state = tester.state(find.byType(FactAdd));
      expect(state.targetRowIndexForMedia(), 0);

      AppToast.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'tap outside only unfocuses and does not clear form while recording',
      (tester) async {
        await setupTestEnvironment();
        addTearDown(tearDownTestEnvironment);

        final deck = sampleDeck();

        await tester.pumpWidget(
          buildTestableWidgetWithOverrides(
            Scaffold(body: FactAdd(deck: deck)),
            overrides: [
              deckListProvider.overrideWith(() => FakeDeckListNotifier([deck])),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Hello');
        await tester.enterText(textFields.at(1), 'World');
        await tester.tap(textFields.at(0));
        await tester.pumpAndSettle();

        final dynamic state = tester.state(find.byType(FactAdd));
        state.isRecordingVoice = true;

        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();

        expect(find.text('Hello'), findsOneWidget);
        expect(find.text('World'), findsOneWidget);
      },
    );
  });
}
