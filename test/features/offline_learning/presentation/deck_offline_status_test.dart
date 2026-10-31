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

  setUp(() => downloader = _FakeDownloader());

  Widget status({OfflinePackageDownloader? downloader}) => buildTestableWidget(
    Scaffold(
      body: DeckOfflineStatus(deckId: 'd1', downloader: downloader),
    ),
  );

  final alert = find.byIcon(LucideIcons.cloudAlert);

  testWidgets('shows nothing without a downloader', (tester) async {
    await tester.pumpWidget(status());

    expect(find.byType(Icon), findsNothing);
    expect(find.byType(ProgressRing), findsNothing);
  });

  testWidgets('shows nothing when idle, so a downloaded deck has no marker', (
    tester,
  ) async {
    await tester.pumpWidget(status(downloader: downloader));

    expect(find.byType(Icon), findsNothing);
    expect(find.byType(ProgressRing), findsNothing);
  });

  testWidgets('shows a ring without a number while downloading', (
    tester,
  ) async {
    await tester.pumpWidget(status(downloader: downloader));

    downloader.progress.value = 0.4;
    await tester.pump();

    expect(find.byType(ProgressRing), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.byTooltip('Downloading for offline study…'), findsOneWidget);

    downloader.progress.value = null;
    await tester.pump();
    expect(find.byType(ProgressRing), findsNothing);
  });

  testWidgets('shows retry after a failure, which downloads again', (
    tester,
  ) async {
    await tester.pumpWidget(status(downloader: downloader));

    downloader.failed.value = true;
    await tester.pump();
    expect(alert, findsOneWidget);
    expect(find.byTooltip('Download failed. Tap to retry'), findsOneWidget);

    await tester.tap(alert);
    expect(downloader.downloads, ['d1']);

    downloader.failed.value = false;
    await tester.pump();
    expect(alert, findsNothing);
  });

  testWidgets('progress wins over a stale failure', (tester) async {
    await tester.pumpWidget(status(downloader: downloader));

    downloader.failed.value = true;
    downloader.progress.value = 0.1;
    await tester.pump();

    expect(find.byType(ProgressRing), findsOneWidget);
    expect(alert, findsNothing);
  });
}
