import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_sync_service.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/features/offline_learning/presentation/offline_sync_indicator.dart';
import 'package:retentio/widgets/app_button.dart';

import '../../../helpers/test_wrapper.dart';

class _FakeStore implements OfflineLearningStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDownloader implements OfflinePackageDownloader {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSync implements OfflineSyncService {
  @override
  final phase = ValueNotifier(OfflineSyncPhase.synced);
  final retries = <bool>[];
  bool fail = false;

  @override
  Future<OfflineSyncResult> flush({
    bool force = false,
    bool retryNow = false,
  }) async {
    retries.add(retryNow);
    if (fail) throw StateError('disk');
    return const OfflineSyncResult(OfflineSyncStatus.synced);
  }

  final calls = <String>[];
  Completer<int>? countGate;

  @override
  Future<int> failedCount() async {
    calls.add('count');
    await countGate?.future;
    return 2;
  }

  @override
  Future<OfflineSyncResult> retryFailed() async {
    calls.add('retry');
    if (fail) throw StateError('disk');
    return const OfflineSyncResult(OfflineSyncStatus.synced);
  }

  @override
  Future<void> discardFailed() async => calls.add('discard');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeSync sync;

  setUp(() => sync = _FakeSync());

  Future<void> pump(WidgetTester tester, {bool withSession = true}) async {
    final session = OfflineLearningSession(
      accountId: 'a',
      store: _FakeStore(),
      downloader: _FakeDownloader(),
      sync: sync,
      mediaRootDir: '/tmp/none',
    );
    await tester.pumpWidget(
      buildTestableWidget(
        Scaffold(
          body: OfflineSyncIndicator(
            session: Future.value(withSession ? session : null),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows each phase and hides when synced', (tester) async {
    await pump(tester);
    expect(find.byType(TextButton), findsNothing);

    for (final (phase, label) in [
      (OfflineSyncPhase.offline, 'Offline'),
      (OfflineSyncPhase.pending, 'Pending sync'),
      (OfflineSyncPhase.syncing, 'Syncing'),
      (OfflineSyncPhase.failed, 'Sync failed'),
      (OfflineSyncPhase.needsLogin, 'Re-login required'),
    ]) {
      sync.phase.value = phase;
      await tester.pump();
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('tapping retries now, but not while syncing', (tester) async {
    await pump(tester);
    sync.phase.value = OfflineSyncPhase.syncing;
    await tester.pump();
    await tester.tap(find.text('Syncing'));
    expect(sync.retries, isEmpty);

    sync.phase.value = OfflineSyncPhase.pending;
    await tester.pump();
    await tester.tap(find.text('Pending sync'));
    sync.fail = true;
    await tester.tap(find.text('Pending sync'));
    await tester.pump();

    expect(sync.retries, [true, true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the shared compact AppButton', (tester) async {
    await pump(tester);
    sync.phase.value = OfflineSyncPhase.pending;
    await tester.pump();

    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.size, AppButtonSize.sm);
    expect(button.variant, AppButtonVariant.ghost);
    expect(button.leading, isA<Icon>());
  });

  group('failed phase', () {
    Future<void> openDialog(WidgetTester tester) async {
      await pump(tester);
      sync.phase.value = OfflineSyncPhase.failed;
      await tester.pump();
      await tester.tap(find.text('Sync failed'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows how many reviews were rejected; cancel keeps them', (
      tester,
    ) async {
      await openDialog(tester);

      expect(find.text('The server rejected 2 reviews.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(sync.calls, ['count']);
      expect(sync.retries, isEmpty);
    });

    testWidgets('retry sends the rejected reviews again', (tester) async {
      await openDialog(tester);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(sync.calls, ['count', 'retry']);
    });

    testWidgets('discard removes the rejected reviews', (tester) async {
      await openDialog(tester);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(sync.calls, ['count', 'discard']);
    });

    testWidgets('a failing retry is logged, not thrown', (tester) async {
      sync.fail = true;
      await openDialog(tester);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(sync.calls, ['count', 'retry']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no dialog once the indicator is gone', (tester) async {
      sync.countGate = Completer<int>();
      await pump(tester);
      sync.phase.value = OfflineSyncPhase.failed;
      await tester.pump();
      await tester.tap(find.text('Sync failed'));
      await tester.pumpWidget(const SizedBox());
      sync.countGate!.complete(0);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(sync.calls, ['count']);
    });
  });

  testWidgets('shows nothing without a session', (tester) async {
    await pump(tester, withSession: false);
    expect(find.byType(TextButton), findsNothing);
  });
}
