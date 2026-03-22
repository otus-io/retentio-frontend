import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/home/home_screen.dart';

import 'helpers/test_wrapper.dart';

void main() {
  testWidgets('smoke: HomeScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(const HomeScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Welcome to Retentio'), findsOneWidget);
  });
}
