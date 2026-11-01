import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/discovery/presentation/discovery_detail_screen.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/providers/main_tab_provider.dart';

import '../../helpers/test_wrapper.dart';

class _CatalogApi extends Interceptor {
  final paths = <String>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    paths.add(options.uri.path);
    if (options.uri.path != '/api/decks/catalog/src-1') {
      handler.reject(DioException(requestOptions: options));
      return;
    }
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'code': 0,
          'msg': 'ok',
          'data': {
            'id': 'src-1',
            'name': 'N5',
            'owner': 'o',
            'published_version': 1,
            'fact_count': 1,
          },
        },
      ),
    );
  }
}

void main() {
  late _CatalogApi api;

  setUp(() async {
    await setupTestEnvironment();
    api = _CatalogApi();
    networkDioClient.dio.interceptors.add(api);
  });

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    String initialLocation = '/discovery/src-1',
  }) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Text('main')),
        GoRoute(
          path: '/discovery/:id',
          builder: (context, state) =>
              DiscoveryDetailScreen(sourceDeckId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              Text('login from=${state.uri.queryParameters['from']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> pumpGuestImportDialog(WidgetTester tester) async {
    await pumpRouter(tester);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
  }

  int selectedTab(WidgetTester tester, Finder finder) =>
      ProviderScope.containerOf(
        tester.element(finder),
      ).read(selectedTabIndexProvider);

  testWidgets('guest import shows a not-logged-in dialog', (tester) async {
    await pumpGuestImportDialog(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text("You're not logged in"), findsOneWidget);
    expect(find.text('Sign in to import'), findsOneWidget);
  });

  testWidgets('cancel keeps the guest on the deck page', (tester) async {
    await pumpGuestImportDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('login from='), findsNothing);
    expect(find.byType(DiscoveryDetailScreen), findsOneWidget);
    expect(api.paths, isNot(contains('/api/decks/import')));
  });

  testWidgets('login opens the login page with the deck as return path', (
    tester,
  ) async {
    await pumpGuestImportDialog(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Login'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('login from=/discovery/src-1'), findsOneWidget);
    expect(api.paths, isNot(contains('/api/decks/import')));
  });

  testWidgets('back from a root deck page opens the discovery tab', (
    tester,
  ) async {
    await pumpRouter(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('main'), findsOneWidget);
    expect(selectedTab(tester, find.text('main')), 1);
  });

  testWidgets('back from a pushed deck page pops normally', (tester) async {
    final router = await pumpRouter(tester, initialLocation: '/');
    router.push('/discovery/src-1');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('main'), findsOneWidget);
    expect(selectedTab(tester, find.text('main')), 0);
  });
}
