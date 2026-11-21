import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/decks/widgets/deck_create.dart';
import 'package:retentio/widgets/app_toast.dart';
import 'package:retentio/widgets/number_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_wrapper.dart';

class _FakeTagManagerCubit extends TagManagerCubit {
  _FakeTagManagerCubit([this.tags = const []]);

  /// The user's own tag list.
  final List<Tag> tags;

  @override
  Future<void> loadTags() async {
    emit(state.copyWith(status: TagManagerStatus.loaded, tags: tags));
  }
}

class _FakeDeckListCubit extends DeckListCubit {
  @override
  Future<void> onRefresh() async {}
}

/// Answers every request with a failure that carries no `msg`, the shape a
/// server error can take when nothing explains it.
class _MessagelessFailureAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'code': -1}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// An imported deck without tags: answers the deck save and the
/// `description` and `fields/rename` contributions.
class _DescriptionAdapter implements HttpClientAdapter {
  _DescriptionAdapter({required this.sendFails});

  final bool sendFails;
  final List<dynamic> contributionBodies = [];
  final List<dynamic> renameBodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Map<String, dynamic> body = {'code': 0, 'msg': 'ok', 'data': {}};
    if (options.uri.path.endsWith('/contributions/fields/rename')) {
      renameBodies.add(options.data);
      if (sendFails) body = {'code': -1, 'msg': 'Error saving contribution'};
    } else if (options.uri.path.endsWith('/contributions/description')) {
      contributionBodies.add(options.data);
      if (sendFails) body = {'code': -1, 'msg': 'Error saving contribution'};
    } else if (options.method == 'GET' && options.uri.path.endsWith('/tags')) {
      body['data'] = {'tags': []};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// An imported deck with one tag: answers the tag list, the deck save, the
/// tag removal and the `deck-tags` contribution.
class _DeckTagsAdapter implements HttpClientAdapter {
  _DeckTagsAdapter({required this.sendFails, this.removeFails = false});

  final bool sendFails;

  /// When true, removing the tag answers a malformed body, which throws.
  final bool removeFails;
  final List<dynamic> contributionBodies = [];
  final List<dynamic> descriptionBodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    Map<String, dynamic> body = {'code': 0, 'msg': 'ok', 'data': {}};
    if (path.endsWith('/contributions/deck-tags')) {
      contributionBodies.add(options.data);
      if (sendFails) body = {'code': -1, 'msg': 'Error saving contribution'};
    } else if (path.endsWith('/contributions/description')) {
      descriptionBodies.add(options.data);
    } else if (options.method == 'DELETE' && removeFails) {
      return ResponseBody.fromString(
        jsonEncode(['not', 'a', 'map']),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    } else if (options.method == 'GET' && path.endsWith('/tags')) {
      body['data'] = {
        'tags': [
          {'id': 't1', 'name': 'Verbs', 'description': ''},
        ],
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Widget buildDeckCreateHarness(
    Widget child, {
    Locale locale = const Locale('en'),
    List<Tag> tags = const [],
  }) {
    return buildTestableWidget(
      locale: locale,
      MultiBlocProvider(
        providers: [
          BlocProvider<TagManagerCubit>(
            create: (_) => _FakeTagManagerCubit(tags),
          ),
          BlocProvider<DeckListCubit>(create: (_) => _FakeDeckListCubit()),
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
      'shows name, description, two default column inputs, and save button',
      (tester) async {
        await tester.pumpWidget(buildDeckCreateHarness(const DeckCreate()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // 1 name + 2 column fields + 1 description = 4 text fields.
        expect(find.byType(TextField), findsNWidgets(4));
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    testWidgets('deletes a field when its remove button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildDeckCreateHarness(const DeckCreate()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Initially: 1 name + 2 field + 1 description TextField.
      expect(find.byType(TextField), findsNWidgets(4));

      // Add one more field so that delete is enabled.
      // Use the localized English text from deckCreateAddField.
      final addFieldButton = find.text('Add a new field');
      expect(addFieldButton, findsOneWidget);
      await tester.tap(addFieldButton);
      await tester.pumpAndSettle();

      // Now: 1 name + 3 field + 1 description TextField.
      expect(find.byType(TextField), findsNWidgets(5));
      final textFields = find.byType(TextField);

      // Focus one field first so the delete button becomes visible.
      await tester.tap(textFields.at(1));
      await tester.pumpAndSettle();

      // Tap the remove button for the focused field.
      final removeButtons = find.byTooltip('Remove column header');
      expect(removeButtons, findsWidgets);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Back to 1 name + 2 field + 1 description TextField (or fewer visible).
      expect(find.byType(TextField).evaluate().length <= 4, isTrue);
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
              BlocProvider<DeckListCubit>(create: (_) => _FakeDeckListCubit()),
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

    testWidgets('edit deck seeds the description field', (tester) async {
      final deck = Deck.fromJson({
        'id': 'd1',
        'name': 'My deck',
        'description': 'Seeded summary',
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
              BlocProvider<DeckListCubit>(create: (_) => _FakeDeckListCubit()),
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

      expect(find.text('Seeded summary'), findsOneWidget);
      // Only imports send suggestions, so only they get a note box.
      expect(find.text('Optional message for the author'), findsNothing);
    });

    testWidgets('imported deck lets the importer suggest a description', (
      tester,
    ) async {
      final imported = Deck.fromJson({
        'id': 'd1',
        'name': 'Imported deck',
        'description': 'Author summary',
        'rate': 20,
        'source_deck_id': 'src-1',
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
              BlocProvider<DeckListCubit>(create: (_) => _FakeDeckListCubit()),
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
              body: SingleChildScrollView(child: DeckCreate(deck: imported)),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextField, 'Author summary');
      expect(field, findsOneWidget);
      expect(tester.widget<TextField>(field).enabled, isTrue);
      expect(
        find.text(
          "Suggest a better description; it's sent to the author for review",
        ),
        findsOneWidget,
      );
      expect(find.text('Optional message for the author'), findsOneWidget);
    });

    testWidgets('shows validation error when any field name is blank', (
      tester,
    ) async {
      await tester.pumpWidget(buildDeckCreateHarness(const DeckCreate()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final textFields = find.byType(TextField);
      // Order: name, field1, field2, description.
      await tester.enterText(textFields.at(0), 'Japanese');
      await tester.enterText(textFields.at(1), 'Front');
      await tester.enterText(textFields.at(2), '');
      await tester.enterText(textFields.at(3), 'A helpful deck');

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Fill in every column header'), findsOneWidget);
    });

    testWidgets('shows validation error when description is blank', (
      tester,
    ) async {
      await tester.pumpWidget(buildDeckCreateHarness(const DeckCreate()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Japanese');
      await tester.enterText(textFields.at(1), 'Front');
      await tester.enterText(textFields.at(2), 'Back');
      await tester.enterText(textFields.at(3), '   ');

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a deck description'), findsOneWidget);
    });

    testWidgets('validation errors are localized', (tester) async {
      await tester.pumpWidget(
        buildDeckCreateHarness(const DeckCreate(), locale: const Locale('ja')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Japanese');
      await tester.enterText(textFields.at(1), 'Front');
      await tester.enterText(textFields.at(2), '');
      await tester.enterText(textFields.at(3), '説明');

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('すべての列見出しを入力してください'), findsOneWidget);
      expect(find.text('Fill in every column header'), findsNothing);
    });

    testWidgets('missing deck name error is localized', (tester) async {
      await tester.pumpWidget(
        buildDeckCreateHarness(const DeckCreate(), locale: const Locale('ja')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), 'Front');
      await tester.enterText(textFields.at(2), 'Back');

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('デッキ名を入力してください'), findsOneWidget);
      expect(find.text('Please enter a deck name'), findsNothing);
    });

    testWidgets(
      'a server failure without a message is not blamed on the name',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        networkDioClient.configure(
          baseUrl: 'http://localhost',
          options: BaseOptions(),
        );
        networkDioClient.dio.httpClientAdapter = _MessagelessFailureAdapter();

        await tester.pumpWidget(buildDeckCreateHarness(const DeckCreate()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Japanese');
        await tester.enterText(textFields.at(1), 'Front');
        await tester.enterText(textFields.at(2), 'Back');
        await tester.enterText(textFields.at(3), 'A helpful deck');

        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(find.text('An unexpected error occurred'), findsOneWidget);
        expect(find.text('Please enter a deck name'), findsNothing);
      },
    );

    group('imported deck tag changes', () {
      Future<_DeckTagsAdapter> removeTagAndSave(
        WidgetTester tester, {
        required bool sendFails,
        bool removeFails = false,
        String? description,
      }) async {
        // An earlier test may have left its own adapter on the shared client.
        networkDioClient.dio.httpClientAdapter = IOHttpClientAdapter();
        await setupTestEnvironment();
        addTearDown(() {
          networkDioClient.dio.httpClientAdapter = IOHttpClientAdapter();
          tearDownTestEnvironment();
        });
        networkDioClient.configure(
          baseUrl: 'http://localhost',
          options: BaseOptions(),
        );
        final adapter = _DeckTagsAdapter(
          sendFails: sendFails,
          removeFails: removeFails,
        );
        networkDioClient.dio.httpClientAdapter = adapter;
        final imported = Deck.fromJson({
          'id': 'imp-tags-${sendFails ? 'unsent' : 'sent'}',
          'name': 'Imported deck',
          'description': 'Author summary',
          'rate': 20,
          'source_deck_id': 'src-1',
          'owner': {'username': 'u', 'email': 'u@e.com'},
          'fields': ['Front', 'Back'],
        });

        // An import's tags are also in the importer's own tag list.
        await tester.pumpWidget(
          buildDeckCreateHarness(
            DeckCreate(deck: imported),
            tags: [Tag(id: 't1', name: 'Verbs', description: '')],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Verbs'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();
        if (description != null) {
          await tester.enterText(
            find.widgetWithText(TextField, 'Author summary'),
            description,
          );
        }
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        return adapter;
      }

      testWidgets('a removed tag is sent to the author', (tester) async {
        final adapter = await removeTagAndSave(tester, sendFails: false);

        expect(adapter.contributionBodies, hasLength(1));
        expect((adapter.contributionBodies.single as Map)['remove_tags'], [
          'Verbs',
        ]);
        expect(find.text('Deck tags sent to the author'), findsOneWidget);
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });

      testWidgets('a failed tag sync still sends the description', (
        tester,
      ) async {
        final adapter = await removeTagAndSave(
          tester,
          sendFails: false,
          removeFails: true,
          description: 'Everyday verbs',
        );

        expect(adapter.descriptionBodies.single, {
          'proposed_description': 'Everyday verbs',
        });
        expect(adapter.contributionBodies, isEmpty);
        // The editor stays open on the tag error.
        expect(find.byType(DeckCreate), findsOneWidget);
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });

      testWidgets('a failed send says the change is saved but unsent', (
        tester,
      ) async {
        await removeTagAndSave(tester, sendFails: true);

        expect(
          find.textContaining("Couldn't send them to the author yet"),
          findsOneWidget,
        );
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });
    });

    group('imported deck description', () {
      /// Opens the editor in a route, types [text] and saves. Returns the
      /// adapter and the value the editor popped.
      Future<(_DescriptionAdapter, (String, String)?)> editAndSave(
        WidgetTester tester, {
        required String text,
        bool sendFails = false,
        bool imported = true,
        String? firstField,
        String? note,
        List<String> fields = const ['Front', 'Back'],
        bool doubleTap = false,
      }) async {
        networkDioClient.dio.httpClientAdapter = IOHttpClientAdapter();
        await setupTestEnvironment();
        addTearDown(() {
          networkDioClient.dio.httpClientAdapter = IOHttpClientAdapter();
          tearDownTestEnvironment();
        });
        networkDioClient.configure(
          baseUrl: 'http://localhost',
          options: BaseOptions(),
        );
        final adapter = _DescriptionAdapter(sendFails: sendFails);
        networkDioClient.dio.httpClientAdapter = adapter;
        final deck = Deck.fromJson({
          'id': 'imp-desc-${sendFails ? 'unsent' : 'sent'}',
          'name': 'Imported deck',
          'description': 'Author summary',
          'rate': 20,
          if (imported) 'source_deck_id': 'src-1',
          'owner': {'username': 'u', 'email': 'u@e.com'},
          'fields': fields,
        });

        (String, String)? popped;
        await tester.pumpWidget(
          buildDeckCreateHarness(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final cubits = (
                    context.read<TagManagerCubit>(),
                    context.read<DeckListCubit>(),
                  );
                  popped = await Navigator.of(context).push<(String, String)?>(
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: cubits.$1),
                          BlocProvider.value(value: cubits.$2),
                          BlocProvider(
                            create: (_) => DeckCreateCubit(
                              name: deck.name,
                              rate: deck.rate,
                              description: deck.description,
                              deckId: deck.id,
                              cardType: DeckCardType.edit,
                              isImported: imported,
                            ),
                          ),
                        ],
                        child: Scaffold(
                          body: SingleChildScrollView(
                            child: DeckCreate(deck: deck),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Author summary'),
          text,
        );
        if (firstField != null) {
          await tester.enterText(
            find.widgetWithText(TextField, 'Front'),
            firstField,
          );
        }
        if (note != null) {
          await tester.enterText(
            find.widgetWithText(TextField, 'Optional message for the author'),
            note,
          );
        }
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        if (doubleTap) {
          await tester.pump();
          await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        }
        await tester.pumpAndSettle();
        return (adapter, popped);
      }

      testWidgets('a changed description is sent to the author', (
        tester,
      ) async {
        final (adapter, popped) = await editAndSave(
          tester,
          text: '  Everyday verbs  ',
        );

        expect(adapter.contributionBodies.single, {
          'proposed_description': 'Everyday verbs',
        });
        expect(
          find.text('Description suggestion sent to the author'),
          findsOneWidget,
        );
        // The deck keeps the author's text until they accept.
        expect(popped, ('Imported deck', 'Author summary'));
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });

      testWidgets('a second tap during a save sends nothing more', (
        tester,
      ) async {
        final (adapter, _) = await editAndSave(
          tester,
          text: 'Everyday verbs',
          doubleTap: true,
        );

        expect(adapter.contributionBodies, hasLength(1));
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });

      testWidgets('a failed send says the suggestion is unsent', (
        tester,
      ) async {
        await editAndSave(tester, text: 'Everyday verbs', sendFails: true);

        expect(
          find.textContaining("Couldn't send your description suggestion"),
          findsOneWidget,
        );
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });

      testWidgets('a renamed field is sent to the author', (tester) async {
        final (adapter, _) = await editAndSave(
          tester,
          text: 'Author summary',
          firstField: ' Word ',
        );

        expect(adapter.contributionBodies, isEmpty);
        expect(adapter.renameBodies.single, {
          'proposed_fields': ['Word', 'Back'],
        });
        expect(
          find.text('Field name suggestion sent to the author'),
          findsOneWidget,
        );
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });

      testWidgets('the note goes with each suggestion', (tester) async {
        final (adapter, _) = await editAndSave(
          tester,
          text: 'Everyday verbs',
          firstField: 'Word',
          note: '  Clearer for beginners  ',
        );

        expect(adapter.contributionBodies.single, {
          'proposed_description': 'Everyday verbs',
          'message': 'Clearer for beginners',
        });
        expect(adapter.renameBodies.single, {
          'proposed_fields': ['Word', 'Back'],
          'message': 'Clearer for beginners',
        });
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });

      testWidgets('a failed rename says the suggestion is unsent', (
        tester,
      ) async {
        await editAndSave(
          tester,
          text: 'Author summary',
          firstField: 'Word',
          sendFails: true,
        );

        expect(
          find.textContaining("Couldn't send your field name suggestion"),
          findsOneWidget,
        );
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });

      testWidgets('an own deck saves its description directly', (tester) async {
        final (adapter, popped) = await editAndSave(
          tester,
          text: 'Everyday verbs',
          imported: false,
        );

        expect(adapter.contributionBodies, isEmpty);
        expect(popped, ('Imported deck', 'Everyday verbs'));
      });

      testWidgets('an unchanged or blank description sends nothing', (
        tester,
      ) async {
        final (unchanged, _) = await editAndSave(
          tester,
          text: 'Author summary ',
        );
        expect(unchanged.contributionBodies, isEmpty);
        expect(unchanged.renameBodies, isEmpty);

        final (spaced, _) = await editAndSave(
          tester,
          text: 'Author summary',
          fields: const ['Front ', 'Back'],
        );
        expect(spaced.renameBodies, isEmpty);

        final (blank, _) = await editAndSave(tester, text: '   ');
        expect(blank.contributionBodies, isEmpty);
        // Clearing the description is not a suggestion; say so.
        expect(find.text('Please enter a deck description'), findsOneWidget);
        AppToast.dismiss();
        await tester.pumpAndSettle();
      });
    });
  });
}
