import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/deck_widgets/import_updates_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('shows before/after description text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DeckUpdatesDescriptionChange(
          before: 'Old blurb',
          after: 'New blurb',
        ),
      ),
    );

    expect(find.text('Description changed'), findsOneWidget);
    expect(find.text('Before update'), findsOneWidget);
    expect(find.text('After update'), findsOneWidget);
    expect(find.text('Old blurb'), findsOneWidget);
    expect(find.text('New blurb'), findsOneWidget);
  });

  testWidgets('renders empty placeholder when a side is blank', (tester) async {
    await tester.pumpWidget(
      _wrap(const DeckUpdatesDescriptionChange(before: '', after: 'New blurb')),
    );

    expect(find.text('(empty)'), findsOneWidget);
    expect(find.text('New blurb'), findsOneWidget);
  });
}
