import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_sync_service.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/features/offline_learning/presentation/offline_download_indicator.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/progress_ring.dart';

import '../../../helpers/test_wrapper.dart';

class _FakeStore implements OfflineLearningStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSync implements OfflineSyncService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDownloader implements OfflinePackageDownloader {
  final progress = ValueNotifier<double?>(null);
  final failed = ValueNotifier(false);
  final downloads = <String>[];

  @override
  ValueListenable<double?> progressOf(String deckId) => progress;

  @override
  ValueListenable<bool> failedOf(String deckId) => failed;

  @override
  Future<bool> download(String deckId, {bool fresh = false}) async {
    downloads.add(deckId);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeDownloader downloader;

  setUp(() => downloader = _FakeDownloader());

  Future<void> pump(WidgetTester tester, {bool withSession = true}) async {
    final session = OfflineLearningSession(
      accountId: 'a',
      store: _FakeStore(),
      downloader: downloader,
      sync: _FakeSync(),
      mediaRootDir: '/tmp/none',
    );
    await tester.pumpWidget(
      buildTestableWidget(
        Scaffold(
          body: OfflineDownloadIndicator(
            session: Future.value(withSession ? session : null),
            deckId: 'd1',
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows nothing when idle', (tester) async {
    await pump(tester);

    expect(find.byType(ProgressRing), findsNothing);
    expect(find.byType(AppButton), findsNothing);
  });

  testWidgets('shows nothing without a session', (tester) async {
    await pump(tester, withSession: false);

    expect(find.byType(ProgressRing), findsNothing);
    expect(find.byType(AppButton), findsNothing);
  });

  testWidgets('shows the ring with the percent while downloading', (
    tester,
  ) async {
    await pump(tester);

    downloader.progress.value = 0.42;
    await tester.pump();
    expect(find.text('Downloading for offline study…'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);

    downloader.progress.value = null;
    await tester.pump();
    expect(find.byType(ProgressRing), findsNothing);
  });

  testWidgets('failed shows retry, which downloads again', (tester) async {
    await pump(tester);

    downloader.failed.value = true;
    await tester.pump();
    expect(find.text('Download failed. Tap to retry'), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    expect(downloader.downloads, ['d1']);
  });

  testWidgets('progress wins over a stale failure', (tester) async {
    await pump(tester);
    downloader.failed.value = true;
    downloader.progress.value = 0.1;
    await tester.pump();

    expect(find.byType(ProgressRing), findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
  });
}
