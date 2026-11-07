import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/screen/decks/bloc/deck_create_cubit.dart';

void main() {
  group('deck field helpers', () {
    test('normalizeDeckFieldNames trims whitespace', () {
      expect(normalizeDeckFieldNames([' Front ', 'Back  ']), ['Front', 'Back']);
    });

    test('hasBlankDeckFieldNames detects empty or whitespace-only fields', () {
      expect(hasBlankDeckFieldNames(['Front', '   ']), isTrue);
      expect(hasBlankDeckFieldNames(['Front', '']), isTrue);
      expect(hasBlankDeckFieldNames(['Front', 'Back']), isFalse);
    });
  });

  group('DeckCreateCubit.submit validation', () {
    DeckCreateCubit buildCubit(String name) => DeckCreateCubit(
      name: name,
      rate: kDeckEditorRateDefault,
      deckId: '',
      cardType: DeckCardType.add,
    );

    test('empty name reports a typed error, not an English message', () async {
      final cubit = buildCubit('   ');
      addTearDown(cubit.close);

      final result = await cubit.submit(fieldNames: ['Front']);

      expect(result.success, isFalse);
      expect(result.error, DeckCreateError.nameEmpty);
      // A raw message here would bypass localization at the call-site.
      expect(result.message, isNull);
    });

    test('blank column header reports a typed error', () async {
      final cubit = buildCubit('Japanese');
      addTearDown(cubit.close);
      cubit.descriptionController.text = 'A helpful deck';

      final result = await cubit.submit(fieldNames: ['Front', '   ']);

      expect(result.success, isFalse);
      expect(result.error, DeckCreateError.blankFieldName);
      expect(result.message, isNull);
    });

    test('empty description reports a typed error', () async {
      final cubit = buildCubit('Japanese');
      addTearDown(cubit.close);
      cubit.descriptionController.text = '   ';

      final result = await cubit.submit(fieldNames: ['Front', 'Back']);

      expect(result.success, isFalse);
      expect(result.error, DeckCreateError.descriptionEmpty);
      expect(result.message, isNull);
    });
  });

  group('buildDeckEditorSubmitParams', () {
    test('imported edit deck sends rate only', () {
      final params = buildDeckEditorSubmitParams(
        cardType: DeckCardType.edit,
        isImported: true,
        rate: 45,
        name: 'Ignored name',
        description: 'Ignored description',
        fields: ['field-a', 'field-b'],
      );

      expect(params, {'rate': 45});
    });

    test(
      'non-imported edit deck sends name, description, fields, and rate',
      () {
        final params = buildDeckEditorSubmitParams(
          cardType: DeckCardType.edit,
          isImported: false,
          rate: 45,
          name: 'My deck',
          description: 'A helpful deck',
          fields: ['field-a', 'field-b'],
        );

        expect(params, {
          'name': 'My deck',
          'description': 'A helpful deck',
          'fields': ['field-a', 'field-b'],
          'rate': 45,
        });
      },
    );

    test('create deck sends name, description, fields, and rate', () {
      final params = buildDeckEditorSubmitParams(
        cardType: DeckCardType.add,
        isImported: false,
        rate: 2000,
        name: 'New deck',
        description: '',
        fields: ['front'],
      );

      expect(params, {
        'name': 'New deck',
        'description': '',
        'fields': ['front'],
        'rate': 1000,
      });
    });
  });

  group('DeckCreateCubit.submit description request', () {
    late _DeckWriteAdapter adapter;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      adapter = _DeckWriteAdapter();
      networkDioClient.dio.httpClientAdapter = adapter;
    });

    tearDown(() {
      networkDioClient.dio.httpClientAdapter = IOHttpClientAdapter();
    });

    test('create posts the trimmed description', () async {
      final cubit = DeckCreateCubit(
        name: 'Japanese',
        rate: kDeckEditorRateDefault,
        deckId: '',
        cardType: DeckCardType.add,
      );
      addTearDown(cubit.close);
      cubit.descriptionController.text = '  A helpful deck  ';

      final result = await cubit.submit(fieldNames: ['Front', 'Back']);

      expect(result.success, isTrue);
      expect(adapter.writes, hasLength(1));
      final write = adapter.writes.single;
      expect(write.method, 'POST');
      expect(write.path, '/api/decks');
      expect(write.body, {
        'name': 'Japanese',
        'description': 'A helpful deck',
        'fields': ['Front', 'Back'],
        'rate': kDeckEditorRateDefault,
      });
    });

    test('edit patches the trimmed description', () async {
      final cubit = DeckCreateCubit(
        name: 'Japanese',
        rate: 45,
        deckId: 'deck-1',
        cardType: DeckCardType.edit,
      );
      addTearDown(cubit.close);
      cubit.descriptionController.text = '  Updated blurb  ';

      final result = await cubit.submit(fieldNames: ['Front', 'Back']);

      expect(result.success, isTrue);
      expect(result.updatedDescription, 'Updated blurb');
      expect(adapter.writes, hasLength(1));
      final write = adapter.writes.single;
      expect(write.method, 'PATCH');
      expect(write.path, '/api/decks/deck-1');
      expect(write.body, {
        'name': 'Japanese',
        'description': 'Updated blurb',
        'fields': ['Front', 'Back'],
        'rate': 45,
      });
    });
  });
}

class _DeckWrite {
  const _DeckWrite({
    required this.method,
    required this.path,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic> body;
}

class _DeckWriteAdapter implements HttpClientAdapter {
  final writes = <_DeckWrite>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    writes.add(
      _DeckWrite(
        method: options.method,
        path: options.uri.path,
        body: options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : <String, dynamic>{},
      ),
    );
    return ResponseBody.fromString(
      jsonEncode({
        'code': 0,
        'msg': 'ok',
        'data': {'deck_id': 'deck-1'},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
