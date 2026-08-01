import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/screen/decks/widgets/badged_app_icon_button.dart';

import '../../../helpers/test_wrapper.dart';

void main() {
  testWidgets('BadgedAppIconButton renders tooltip and icon', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        Scaffold(
          body: BadgedAppIconButton(
            icon: LucideIcons.share2,
            tooltip: 'Publish Deck',
            showBadge: false,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Publish Deck'), findsOneWidget);
    await tester.tap(find.byTooltip('Publish Deck'));
    expect(pressed, isTrue);
  });

  testWidgets('BadgedAppIconButton shows corner dot when badged', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        Scaffold(
          body: BadgedAppIconButton(
            icon: LucideIcons.refreshCw,
            tooltip: 'Check updates',
            showBadge: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Check updates'), findsOneWidget);
    expect(find.byType(Stack), findsWidgets);
    final dots = tester.widgetList<Container>(find.byType(Container)).where((
      c,
    ) {
      final d = c.decoration;
      return d is BoxDecoration && d.shape == BoxShape.circle;
    });
    expect(dots, isNotEmpty);
  });
}
