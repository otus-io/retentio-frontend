import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/providers/card_provider.dart';
import 'package:retentio/screen/deck/widgets/edit_fact_widget.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_fact_api_interceptor.dart';
import '../../helpers/test_card_notifiers.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  group('EditFactWidget', () {
    testWidgets('loads fact and can save', (tester) async {
      await setupTestEnvironment();
      addTearDown(tearDownTestEnvironment);

      final interceptor = attachFakeFactApiInterceptor();
      addTearDown(() => detachFakeFactApiInterceptor(interceptor));

      final router = GoRouter(
        initialLocation: '/base',
        routes: [
          GoRoute(
            path: '/base',
            builder: (_, __) => const Scaffold(body: Text('base')),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, __) => Scaffold(
              body: EditFactWidget(
                deck: sampleDeck(),
                factId: 'fact-test-1',
                onSaved: () async {},
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deckProvider.overrideWithValue(sampleDeck()),
            cardProvider.overrideWith(NoOpGetCardNotifier.new),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('zh')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
            ),
            routerConfig: router,
          ),
        ),
      );

      router.push('/edit');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('FieldA'), findsOneWidget);
      expect(find.text('FieldB'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    });
  });
}
