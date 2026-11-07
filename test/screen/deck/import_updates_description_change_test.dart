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
  testWidgets('shows that the description changed', (tester) async {
    await tester.pumpWidget(_wrap(const DeckUpdatesDescriptionChange()));

    expect(find.text('Description changed'), findsOneWidget);
    expect(find.text('Before update'), findsNothing);
    expect(find.text('After update'), findsNothing);
  });
}
