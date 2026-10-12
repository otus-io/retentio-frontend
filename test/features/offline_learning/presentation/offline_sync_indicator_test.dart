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

  testWidgets('shows nothing without a session', (tester) async {
    await pump(tester, withSession: false);
    expect(find.byType(TextButton), findsNothing);
  });
}
