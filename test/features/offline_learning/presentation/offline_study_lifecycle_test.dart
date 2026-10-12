import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_sync_service.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/features/offline_learning/presentation/offline_study_lifecycle.dart';

class _FakeStore implements OfflineLearningStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSync implements OfflineSyncService {
  final calls = <bool>[];
  bool fail = false;

  @override
  Future<OfflineSyncResult> flush({
    bool force = false,
    bool retryNow = false,
  }) async {
    calls.add(force);
    if (fail) throw StateError('offline');
    return const OfflineSyncResult(OfflineSyncStatus.synced);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDownloader implements OfflinePackageDownloader {
  final decks = <String>[];

  @override
  Future<bool> download(String deckId) async {
    decks.add(deckId);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeSync sync;
  late _FakeDownloader downloader;
  late StreamController<void> network;
  late OfflineLearningSession session;

  setUp(() {
    sync = _FakeSync();
    downloader = _FakeDownloader();
    network = StreamController<void>.broadcast();
    session = OfflineLearningSession(
      accountId: 'alice',
      store: _FakeStore(),
      downloader: downloader,
      sync: sync,
      mediaRootDir: '/tmp/none',
    );
  });

  Widget lifecycle(Future<OfflineLearningSession?> s, {Stream<void>? net}) =>
      OfflineStudyLifecycle(
        session: s,
        deckId: 'd1',
        networkRestored: net ?? network.stream,
        child: const SizedBox(key: Key('child')),
      );

  testWidgets('flushes and downloads on open, then flushes on events', (
    tester,
  ) async {
    await tester.pumpWidget(lifecycle(Future.value(session)));
    await tester.pump();

    expect(find.byKey(const Key('child')), findsOneWidget);
    expect(sync.calls, [true]);
    expect(downloader.decks, ['d1']);

    network.add(null);
    await tester.pump();
    expect(sync.calls, hasLength(2));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(sync.calls, hasLength(2));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(sync.calls, hasLength(4));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(sync.calls, [true, true, true, true, true]);
    expect(network.hasListener, isFalse);
  });

  testWidgets('swallows sync and network errors', (tester) async {
    sync.fail = true;
    await tester.pumpWidget(lifecycle(Future.value(session)));
    network.addError(StateError('watch'));
    await tester.pump();

    expect(sync.calls, [true]);
    expect(downloader.decks, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does nothing without a session', (tester) async {
    await tester.pumpWidget(lifecycle(Future.value(null)));
    await tester.pump();
    final failing = Completer<OfflineLearningSession?>();
    await tester.pumpWidget(Center(child: lifecycle(failing.future)));
    failing.completeError(StateError('no account'));
    await tester.pump();

    expect(sync.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
