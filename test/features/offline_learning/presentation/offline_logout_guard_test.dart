import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_sync_service.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/features/offline_learning/presentation/offline_logout_guard.dart';
import 'package:retentio/widgets/app_button.dart';

import '../../../helpers/test_wrapper.dart';

const _op = StudySyncOperation(
  operationId: 'o1',
  sequence: 1,
  deckId: 'd1',
  cardId: 'c1',
  type: StudySyncType.hide,
  createdAt: 0,
  hidden: true,
);

class _Offline extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) =>
      handler.reject(DioException(requestOptions: options));
}

class _FakeStore implements OfflineLearningStore {
  final ops = <StudySyncOperation>[];
  int clears = 0;
  bool failReads = false;
  bool failClear = false;

  @override
  Future<List<StudySyncOperation>> getOperations() async {
    if (failReads) throw StateError('hive');
    return [...ops];
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('disk');
    clears++;
    ops.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSession implements OfflineLearningSession {
  _FakeSession(this.store, this.sync);

  @override
  final _FakeStore store;
  @override
  final _FakeSync sync;

  @override
  Future<void> clear() => store.clear();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSync implements OfflineSyncService {
  _FakeSync(this.store);

  final _FakeStore store;
  bool uploads = true;
  int flushes = 0;
  Completer<void>? gate;
  Object? error;

  @override
  Future<OfflineSyncResult> flush({
    bool force = false,
    bool retryNow = false,
  }) async {
    flushes++;
    await gate?.future;
    if (error case final e?) throw e;
    if (uploads) store.ops.clear();
    return const OfflineSyncResult(OfflineSyncStatus.synced);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeStore store;
  late _FakeSync sync;
  late OfflineLearningSession session;

  setUp(() {
    store = _FakeStore();
    sync = _FakeSync(store);
    session = _FakeSession(store, sync);
  });

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

  /// Starts the guard from a button and returns its eventual result.
  Future<List<bool>> start(
    WidgetTester tester,
    Future<OfflineLearningSession?>? s,
  ) async {
    final results = <bool>[];
    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await settleOfflineDataBeforeLogout(context, session: s),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await settle(tester);
    return results;
  }

  testWidgets('clears data without asking when nothing is queued', (
    tester,
  ) async {
    final results = await start(tester, Future.value(session));

    expect(results, [true]);
    expect(store.clears, 1);
  });

  testWidgets('continues logout without a session', (tester) async {
    expect(await start(tester, Future.value(null)), [true]);
    expect(
      await start(
        tester,
        Future<OfflineLearningSession?>(() => throw StateError('no storage')),
      ),
      [true],
    );
  });

  testWidgets('uses the current account by default', (tester) async {
    await setupTestEnvironment();
    addTearDown(tearDownTestEnvironment);
    networkDioClient.dio.interceptors.add(_Offline());
    addTearDown(networkDioClient.dio.interceptors.clear);

    expect(await start(tester, null), [true]);
  });

  testWidgets('cancel keeps the user logged in', (tester) async {
    store.ops.add(_op);
    final results = await start(tester, Future.value(session));

    expect(
      find.text('Some reviews have not been uploaded yet.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(results, [false]);
    expect(store.clears, 0);
  });

  testWidgets('keep logs out without deleting the queue', (tester) async {
    store.ops.add(_op);
    final results = await start(tester, Future.value(session));
    await tester.tap(find.text('Keep and log out'));
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(store.ops, hasLength(1));
  });

  testWidgets('discard deletes the queue', (tester) async {
    store.ops.add(_op);
    final results = await start(tester, Future.value(session));
    await tester.tap(find.text('Discard and log out'));
    await settle(tester);

    expect(results, [true]);
    expect(store.clears, 1);
  });

  testWidgets('sync uploads, then clears', (tester) async {
    store.ops.add(_op);
    final results = await start(tester, Future.value(session));
    await tester.tap(find.text('Sync and log out'));
    await settle(tester);

    expect(results, [true]);
    expect(sync.flushes, 1);
    expect(store.clears, 1);
  });

  testWidgets('shows a non-dismissible progress dialog while syncing', (
    tester,
  ) async {
    store.ops.add(_op);
    sync.gate = Completer<void>();
    final results = await start(tester, Future.value(session));
    await tester.tap(find.text('Sync and log out'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Uploading reviews…'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Uploading reviews…'), findsOneWidget);
    expect(results, isEmpty);

    sync.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Uploading reviews…'), findsNothing);
    expect(results, [true]);
    expect(store.clears, 1);
  });

  testWidgets('a sync error closes the progress dialog', (tester) async {
    store.ops.add(_op);
    sync.error = StateError('network');
    final results = await start(tester, Future.value(session));
    await tester.tap(find.text('Sync and log out'));
    await tester.pumpAndSettle();

    expect(find.text('Uploading reviews…'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(results, [true]);
    expect(store.ops, hasLength(1));
  });

  testWidgets('choices use the shared app buttons', (tester) async {
    store.ops.add(_op);
    await start(tester, Future.value(session));

    AppButtonVariant variantOf(String label) =>
        tester.widget<AppButton>(find.widgetWithText(AppButton, label)).variant;
    expect(variantOf('Cancel'), AppButtonVariant.ghost);
    expect(variantOf('Sync and log out'), AppButtonVariant.primary);
    expect(variantOf('Keep and log out'), AppButtonVariant.secondary);
    expect(variantOf('Discard and log out'), AppButtonVariant.danger);
  });

  testWidgets('a failed sync asks again', (tester) async {
    store.ops.add(_op);
    sync.uploads = false;
    final results = await start(tester, Future.value(session));
    await tester.tap(find.text('Sync and log out'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Some reviews could not be uploaded. Keep them or discard them?',
      ),
      findsOneWidget,
    );
    expect(find.text('Sync and log out'), findsNothing);
    await tester.tap(find.text('Keep and log out'));
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(store.ops, hasLength(1));
  });

  testWidgets('a screen closed during the sync keeps the data and logs out', (
    tester,
  ) async {
    store.ops.add(_op);
    sync
      ..uploads = false
      ..gate = Completer<void>();
    final showButton = ValueNotifier(true);
    final results = <bool>[];
    await tester.pumpWidget(
      buildTestableWidget(
        ValueListenableBuilder<bool>(
          valueListenable: showButton,
          builder: (_, show, _) => show
              ? Builder(
                  builder: (context) => TextButton(
                    onPressed: () async => results.add(
                      await settleOfflineDataBeforeLogout(
                        context,
                        session: Future.value(session),
                      ),
                    ),
                    child: const Text('go'),
                  ),
                )
              : const SizedBox(),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sync and log out'));
    await tester.pump();
    await tester.pump();

    showButton.value = false;
    await tester.pump();
    sync.gate!.complete();
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(store.clears, 0);
    expect(store.ops, hasLength(1));
  });

  testWidgets('a storage error does not block logout', (tester) async {
    store.failReads = true;

    expect(await start(tester, Future.value(session)), [true]);
  });

  testWidgets('a failed discard still logs out', (tester) async {
    store
      ..ops.add(_op)
      ..failClear = true;
    final results = await start(tester, Future.value(session));
    await tester.tap(find.text('Discard and log out'));
    await settle(tester);

    expect(results, [true]);
  });
}
