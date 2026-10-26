import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/presentation/deck_offline_status.dart';
import 'package:retentio/widgets/progress_ring.dart';

import '../../../helpers/test_wrapper.dart';

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
  late int downloaded;

  setUp(() {
    downloader = _FakeDownloader();
    downloaded = 0;
  });

  Widget status({
    String deckId = 'd1',
    bool availableOffline = false,
    OfflinePackageDownloader? downloader,
  }) => buildTestableWidget(
    Scaffold(
      body: DeckOfflineStatus(
        deckId: deckId,
        availableOffline: availableOffline,
        downloader: downloader,
        onDownloaded: () => downloaded++,
      ),
    ),
  );

  final check = find.byIcon(LucideIcons.circleCheck);
  final alert = find.byIcon(LucideIcons.cloudAlert);

  testWidgets('shows nothing by default', (tester) async {
    await tester.pumpWidget(status(downloader: downloader));

    expect(check, findsNothing);
    expect(alert, findsNothing);
    expect(find.byType(ProgressRing), findsNothing);
  });

  testWidgets('shows a check for a downloaded deck, without a downloader', (
    tester,
  ) async {
    await tester.pumpWidget(status(availableOffline: true));

    expect(check, findsOneWidget);
    expect(find.byTooltip('Available offline'), findsOneWidget);
  });

  testWidgets('shows a ring without a number while downloading', (
    tester,
  ) async {
    await tester.pumpWidget(
      status(availableOffline: true, downloader: downloader),
    );
    expect(check, findsOneWidget);

    downloader.progress.value = 0.4;
    await tester.pump();

    expect(find.byType(ProgressRing), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.byTooltip('Downloading for offline study…'), findsOneWidget);
    expect(check, findsNothing);
    expect(downloaded, 0);
  });

  testWidgets('reports when a running download stops', (tester) async {
    downloader.progress.value = 0.2;
    await tester.pumpWidget(status(downloader: downloader));
    expect(find.byType(ProgressRing), findsOneWidget);

    downloader.progress.value = 0.9;
    await tester.pump();
    expect(downloaded, 0);

    downloader.progress.value = null;
    await tester.pump();
    expect(downloaded, 1);
    expect(find.byType(ProgressRing), findsNothing);

    downloader.failed.value = true;
    await tester.pump();
    expect(downloaded, 1);
  });

  testWidgets('shows retry for a failed deck that was never ready', (
    tester,
  ) async {
    await tester.pumpWidget(status(downloader: downloader));

    downloader.failed.value = true;
    await tester.pump();
    expect(alert, findsOneWidget);
    expect(find.byTooltip('Download failed. Tap to retry'), findsOneWidget);

    await tester.tap(alert);
    expect(downloader.downloads, ['d1']);
  });

  testWidgets('a ready deck keeps its check after a failed refresh', (
    tester,
  ) async {
    await tester.pumpWidget(
      status(availableOffline: true, downloader: downloader),
    );

    downloader.failed.value = true;
    await tester.pump();

    expect(check, findsOneWidget);
    expect(alert, findsNothing);
  });

  testWidgets('follows a replaced downloader', (tester) async {
    final other = _FakeDownloader();
    await tester.pumpWidget(status(downloader: downloader));
    await tester.pumpWidget(status(downloader: other));

    downloader.progress.value = 0.5;
    await tester.pump();
    expect(find.byType(ProgressRing), findsNothing);

    other.progress.value = 0.5;
    await tester.pump();
    expect(find.byType(ProgressRing), findsOneWidget);
    other.progress.value = null;
    await tester.pump();
    expect(downloaded, 1);
  });

  testWidgets('follows a replaced deck id', (tester) async {
    await tester.pumpWidget(status(downloader: downloader));
    await tester.pumpWidget(status(deckId: 'd2', downloader: downloader));

    downloader.progress.value = 0.5;
    await tester.pump();
    expect(find.byType(ProgressRing), findsOneWidget);
  });

  testWidgets('stops listening once removed', (tester) async {
    downloader.progress.value = 0.5;
    await tester.pumpWidget(status(downloader: downloader));
    await tester.pumpWidget(const SizedBox());

    downloader.progress.value = null;
    expect(downloaded, 0);
  });
}
