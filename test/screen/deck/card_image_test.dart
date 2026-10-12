import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/card_widgets/card_image.dart';
import 'package:retentio/widgets/common_net_image.dart';

import '../../helpers/test_wrapper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });
  tearDownAll(tearDownTestEnvironment);

  testWidgets('shows a downloaded local file without the network', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('card_image');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/img1')..writeAsBytesSync([0]);

    await tester.pumpWidget(
      buildTestableWidgetWithOverrides(CardImage(url: file.path)),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CommonNetImage), findsNothing);
  });

  testWidgets('loads remote urls and missing local paths from the network', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidgetWithOverrides(
        const Column(
          children: [
            CardImage(url: 'https://host/api/media/img1'),
            CardImage(url: '/missing/img1'),
          ],
        ),
      ),
    );

    expect(find.byType(CommonNetImage), findsNWidgets(2));
  });
}
