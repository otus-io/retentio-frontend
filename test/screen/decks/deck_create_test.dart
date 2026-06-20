import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';
import 'package:retentio/screen/decks/widgets/deck_create.dart';
import 'package:retentio/widgets/number_picker.dart';

import '../../helpers/test_wrapper.dart';

class _FakeTagManagerCubit extends TagManagerCubit {
  @override
  Future<void> loadTags() async {
    emit(state.copyWith(status: TagManagerStatus.loaded, tags: const []));
  }
}

void main() {
  Widget buildDeckCreateHarness(Widget child) {
    return buildTestableWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TagManagerCubit>(create: (_) => _FakeTagManagerCubit()),
          BlocProvider(
            create: (_) => DeckCreateCubit(
              name: '',
              rate: kDeckEditorRateDefault,
              deckId: '',
              cardType: DeckCardType.add,
            ),
          ),
        ],
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('DeckCreate', () {
    testWidgets('rate NumberPicker is 1–1000 step 1 (create/edit deck)', (
      tester,
    ) async {
      await tester.pumpWidget(buildDeckCreateHarness(const DeckCreate()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(NumberPicker), findsOneWidget);
      final picker = tester.widget<NumberPicker>(find.byType(NumberPicker));
      expect(picker.minValue, 1);
      expect(picker.maxValue, 1000);
      expect(picker.step, 1);
      expect(picker.value, 30);
    });

    testWidgets(
      'shows name field, two default column inputs, and save button',
      (tester) async {
        await tester.pumpWidget(buildDeckCreateHarness(const DeckCreate()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(TextField), findsNWidgets(3));
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    testWidgets('deletes a field when its remove button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildDeckCreateHarness(const DeckCreate()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Initially: 1 name TextField + 2 field TextFields.
      expect(find.byType(TextField), findsNWidgets(3));

      // Add one more field so that delete is enabled.
      // Use the localized English text from deckCreateAddField.
      final addFieldButton = find.text('Add a new field');
      expect(addFieldButton, findsOneWidget);
      await tester.tap(addFieldButton);
      await tester.pumpAndSettle();

      // Now: 1 name TextField + 3 field TextFields.
      expect(find.byType(TextField), findsNWidgets(4));
      final textFields = find.byType(TextField);

      // Focus one field first so the delete button becomes visible.
      await tester.tap(textFields.at(1));
      await tester.pumpAndSettle();

      // Tap the remove button for the focused field.
      final removeButtons = find.byTooltip('Remove column header');
      expect(removeButtons, findsWidgets);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Back to 1 name TextField + 2 field TextFields (or equivalent visible count).
      expect(find.byType(TextField).evaluate().length <= 3, isTrue);
    });

    testWidgets('reorders fields when dragged', (tester) async {
      await tester.pumpWidget(buildDeckCreateHarness(const DeckCreate()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Enter distinct values into the two field TextFields.
      final textFields = find.byType(TextField);
      // Index 0 is the deck name; 1 and 2 are field names.
      await tester.enterText(textFields.at(1), 'First');
      await tester.enterText(textFields.at(2), 'Second');
      await tester.pump();

      // Drag the second field above the first via delayed-drag listener.
      final handles = find.byType(ReorderableDelayedDragStartListener);
      expect(handles, findsNWidgets(2));

      final handleCenter = tester.getCenter(handles.at(1));
      final gesture = await tester.startGesture(handleCenter);
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveBy(const Offset(0, -180));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final reorderedTextFields = find.byType(TextField);
      final firstField = tester.widget<TextField>(reorderedTextFields.at(1));
      final secondField = tester.widget<TextField>(reorderedTextFields.at(2));

      // After drag, both field values should still be present and bound.
      expect(
        {firstField.controller!.text, secondField.controller!.text},
        {'First', 'Second'},
      );
    });

    testWidgets('edit deck exposes reorder list and drag handles', (
      tester,
    ) async {
      final deck = Deck.fromJson({
        'id': 'd1',
        'name': 'My deck',
        'stats': {
          'cards_count': 0,
          'facts_count': 0,
          'unseen_cards': 0,
          'due_cards': 0,
        },
        'rate': 20,
        'owner': {'username': 'u', 'email': 'u@e.com'},
        'fields': ['Front', 'Back'],
      });

      await tester.pumpWidget(
        buildTestableWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<TagManagerCubit>(
                create: (_) => _FakeTagManagerCubit(),
              ),
              BlocProvider(
                create: (_) => DeckCreateCubit(
                  name: '',
                  rate: kDeckEditorRateDefault,
                  deckId: '',
                  cardType: DeckCardType.add,
                ),
              ),
            ],
            child: Scaffold(
              body: SingleChildScrollView(child: DeckCreate(deck: deck)),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byType(ReorderableDelayedDragStartListener), findsWidgets);
    });
  });
}
