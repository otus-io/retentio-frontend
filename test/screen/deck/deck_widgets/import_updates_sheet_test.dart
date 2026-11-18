import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/screen/deck/deck_widgets/import_updates_sheet.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/widgets/app_toast.dart';

import '../../../helpers/test_wrapper.dart';

/// Serves an update summary from v1 to v2; the sync answers [syncStatus].
class _SyncAdapter implements HttpClientAdapter {
  _SyncAdapter({this.syncStatus = 200});

  final int syncStatus;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final syncing = options.path.endsWith('/sync');
    final status = syncing ? syncStatus : 200;
    final data = syncing
        ? {'source_version': 2}
        : {'source_version': 1, 'latest_version': 2};
    return ResponseBody.fromString(
      jsonEncode({'code': status == 200 ? 0 : 1, 'msg': 'boom', 'data': data}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<String> refreshed;
  late int synced;

  setUp(() async {
    await setupTestEnvironment();
    await ApiService.clearToken();
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
    refreshed = [];
    synced = 0;
  });

  tearDown(() {
    AppToast.dismiss();
    networkDioClient.dio.httpClientAdapter = IOHttpClientAdapter();
    tearDownTestEnvironment();
  });

  Future<void> syncNow(
    WidgetTester tester, {
    int syncStatus = 200,
    Future<void> Function(String deckId)? refreshOffline,
  }) async {
    networkDioClient.dio.httpClientAdapter = _SyncAdapter(
      syncStatus: syncStatus,
    );
    final sheet = refreshOffline == null
        ? ImportUpdatesSheet(deckId: 'd1', onSynced: () async => synced++)
        : ImportUpdatesSheet(
            deckId: 'd1',
            onSynced: () async => synced++,
            refreshOffline: refreshOffline,
          );
    await tester.pumpWidget(buildTestableWidget(Scaffold(body: sheet)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();
  }

  // Lets the toast's dismiss timer fire before the test ends.
  Future<void> outlastToast(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 3));

  testWidgets('a sync re-downloads the offline copy', (tester) async {
    await syncNow(tester, refreshOffline: (id) async => refreshed.add(id));

    expect(refreshed, ['d1']);
    expect(synced, 1);
    expect(find.text('Deck synced'), findsOneWidget);
    await outlastToast(tester);
  });

  testWidgets('a failing offline refresh does not fail the sync', (
    tester,
  ) async {
    await syncNow(tester, refreshOffline: (_) async => throw StateError('x'));

    expect(synced, 1);
    expect(find.text('Deck synced'), findsOneWidget);
    await outlastToast(tester);
  });

  testWidgets('a failed sync starts no offline refresh', (tester) async {
    await syncNow(
      tester,
      syncStatus: 500,
      refreshOffline: (id) async => refreshed.add(id),
    );

    expect(refreshed, isEmpty);
    expect(synced, 0);
    await outlastToast(tester);
  });

  testWidgets('syncs without an offline session by default', (tester) async {
    await syncNow(tester);

    expect(synced, 1);
    expect(find.text('Deck synced'), findsOneWidget);
    await outlastToast(tester);
  });
}
