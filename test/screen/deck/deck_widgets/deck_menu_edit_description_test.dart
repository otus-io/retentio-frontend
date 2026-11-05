import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/bloc/deck_study_context_cubit.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_menu.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';

import '../../../helpers/test_wrapper.dart';

class _OkAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final Object data;
    if (options.method == 'PATCH') {
      data = {'deck_id': 'deck-1'};
    } else if (path.contains('tags')) {
      data = {'tags': <Object>[]};
    } else {
      data = {'decks': <Object>[]};
    }
    return ResponseBody.fromString(
      jsonEncode({'code': 0, 'msg': 'ok', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Deck _deck() => Deck.fromJson({
  'id': 'deck-1',
  'name': 'Deck one',
  'description': 'Old blurb',
  'rate': 30,
  'fields': ['Front', 'Back'],
  'min_interval': 60,
  'def_interval': 300,
  'max_interval': 86400,
});

void main() {
  late DeckStudyContextCubit contextCubit;

  setUp(() async {
    await setupTestEnvironment();
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
    networkDioClient.dio.httpClientAdapter = _OkAdapter();
    contextCubit = DeckStudyContextCubit(_deck());
  });

  tearDown(() {
    networkDioClient.dio.httpClientAdapter = IOHttpClientAdapter();
    tearDownTestEnvironment();
  });

  Future<void> pumpMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: contextCubit),
            BlocProvider(create: (_) => DeckListCubit()),
          ],
          child: Scaffold(body: DeckMenu(deck: _deck())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.byType(DeckMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Deck'));
    await tester.pumpAndSettle();
  }

  testWidgets('edit save keeps the new description in study context', (
    tester,
  ) async {
    await pumpMenu(tester);
    await openEditor(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.last, 'New blurb');
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(contextCubit.state.deck.name, 'Deck one');
    expect(contextCubit.state.deck.description, 'New blurb');
    expect(find.text('Edit Deck'), findsNothing);
  });

  testWidgets('leaving the editor keeps the previous description', (
    tester,
  ) async {
    await pumpMenu(tester);
    await openEditor(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(contextCubit.state.deck.description, 'Old blurb');
  });
}
