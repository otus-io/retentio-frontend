import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/bloc/deck_sharing_status_cubit.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Deck _source({required String id, int publishedVersion = 2}) {
  return Deck.fromJson({
    'id': id,
    'name': 'S',
    'published_version': publishedVersion,
    'stats': <String, dynamic>{},
    'rate': 10,
    'fields': ['a'],
    'owner': {'username': 'u', 'email': 'u@t.com'},
  });
}

Deck _import({required String id}) {
  return Deck.fromJson({
    'id': id,
    'name': 'I',
    'source_deck_id': 'src',
    'stats': <String, dynamic>{},
    'rate': 10,
    'fields': ['a'],
    'owner': {'username': 'u', 'email': 'u@t.com'},
  });
}

class _SharingStatusAdapter implements HttpClientAdapter {
  _SharingStatusAdapter({
    this.unpublished = false,
    this.hasUpdates = false,
    this.openContributions = false,
    this.failPublish = false,
    this.failUpdates = false,
    this.failContributions = false,
  });

  final bool unpublished;
  final bool hasUpdates;
  final bool openContributions;
  final bool failPublish;
  final bool failUpdates;
  final bool failContributions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (path.contains('publish-preview')) {
      if (failPublish) return _error('preview failed');
      return _ok({
        'has_unpublished_changes': unpublished,
        'published_version': 1,
      });
    }
    if (path.contains('/updates')) {
      if (failUpdates) return _error('updates failed');
      return _ok({'source_version': 1, 'latest_version': hasUpdates ? 2 : 1});
    }
    if (path.contains('/contributions')) {
      if (failContributions) return _error('contributions failed');
      return _ok({
        'contributions': openContributions
            ? [
                {
                  'contribution_id': 'c1',
                  'type': 'fact_edit',
                  'status': 'open',
                  'reporter': 'bob',
                },
              ]
            : <Map<String, dynamic>>[],
      });
    }
    return _error('not found', 404);
  }

  ResponseBody _ok(Map<String, dynamic> data) => ResponseBody.fromString(
    jsonEncode({'code': 0, 'msg': 'ok', 'data': data}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  ResponseBody _error(String msg, [int status = 400]) =>
      ResponseBody.fromString(
        jsonEncode({'code': -1, 'msg': msg}),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.clearToken();
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
  });

  group('DeckSharingStatusCubit', () {
    test('markDirty and clear update flashing set', () {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);

      expect(cubit.state.shouldFlash('d1'), isFalse);
      cubit.markDirty('d1');
      expect(cubit.state.shouldFlash('d1'), isTrue);
      cubit.clear('d1');
      expect(cubit.state.shouldFlash('d1'), isFalse);
    });

    test('markOpenContributions and clearOpenContributions', () {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.markOpenContributions('');
      expect(cubit.state.openContributionDeckIds, isEmpty);
      cubit.markOpenContributions('d1');
      expect(cubit.state.hasOpenContributions('d1'), isTrue);
      cubit.clearOpenContributions('d1');
      expect(cubit.state.hasOpenContributions('d1'), isFalse);
      cubit.clearOpenContributions('');
      expect(cubit.state.openContributionDeckIds, isEmpty);
    });

    test('markDirty ignores empty id', () {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.markDirty('');
      expect(cubit.state.flashingDeckIds, isEmpty);
    });

    test('refresh with empty decks clears prior flashes', () async {
      networkDioClient.dio.httpClientAdapter = _SharingStatusAdapter(
        openContributions: true,
      );
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.setDecks([_source(id: 'stale')]);
      await cubit.refresh();
      expect(cubit.state.hasOpenContributions('stale'), isTrue);
      cubit.markDirty('stale');

      cubit.setDecks(const []);
      await cubit.refresh();
      expect(cubit.state.flashingDeckIds, isEmpty);
      expect(cubit.state.openContributionDeckIds, isEmpty);
    });

    test('startPolling and stopPolling do not throw', () {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.setDecks(const []);
      cubit.startPolling();
      cubit.stopPolling();
    });

    test('setDecks stores list for later refresh', () {
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      final decks = [_source(id: 'src1')];
      cubit.setDecks(decks);
      expect(decks.single.isPublishedSource, isTrue);
    });

    test('refresh marks unpublished source and open contributions', () async {
      networkDioClient.dio.httpClientAdapter = _SharingStatusAdapter(
        unpublished: true,
        openContributions: true,
      );
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.setDecks([_source(id: 'src1')]);

      await cubit.refresh();

      expect(cubit.state.shouldFlash('src1'), isTrue);
      expect(cubit.state.hasOpenContributions('src1'), isTrue);
    });

    test('refresh marks import updates without contribution badge', () async {
      networkDioClient.dio.httpClientAdapter = _SharingStatusAdapter(
        hasUpdates: true,
        openContributions: true,
      );
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.setDecks([_import(id: 'imp1')]);

      await cubit.refresh();

      expect(cubit.state.shouldFlash('imp1'), isTrue);
      expect(cubit.state.hasOpenContributions('imp1'), isFalse);
    });

    test('refresh keeps prior flags when poll requests fail', () async {
      networkDioClient.dio.httpClientAdapter = _SharingStatusAdapter(
        unpublished: true,
        hasUpdates: true,
        openContributions: true,
      );
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.setDecks([_source(id: 'src1'), _import(id: 'imp1')]);
      await cubit.refresh();
      expect(cubit.state.shouldFlash('src1'), isTrue);
      expect(cubit.state.shouldFlash('imp1'), isTrue);
      expect(cubit.state.hasOpenContributions('src1'), isTrue);

      networkDioClient.dio.httpClientAdapter = _SharingStatusAdapter(
        failPublish: true,
        failUpdates: true,
        failContributions: true,
      );
      await cubit.refresh();

      expect(cubit.state.shouldFlash('src1'), isTrue);
      expect(cubit.state.shouldFlash('imp1'), isTrue);
      expect(cubit.state.hasOpenContributions('src1'), isTrue);
    });

    test('refresh clears contribution badge when inbox is empty', () async {
      networkDioClient.dio.httpClientAdapter = _SharingStatusAdapter(
        openContributions: true,
      );
      final cubit = DeckSharingStatusCubit();
      addTearDown(cubit.close);
      cubit.setDecks([_source(id: 'src1', publishedVersion: 0)]);
      await cubit.refresh();
      expect(cubit.state.hasOpenContributions('src1'), isTrue);

      networkDioClient.dio.httpClientAdapter = _SharingStatusAdapter(
        openContributions: false,
      );
      await cubit.refresh();

      expect(cubit.state.hasOpenContributions('src1'), isFalse);
      expect(cubit.state.shouldFlash('src1'), isFalse);
    });
  });
}
