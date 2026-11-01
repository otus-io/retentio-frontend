import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/di/app_service_locator.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';
import 'package:retentio/features/discovery/presentation/discovery_detail_screen.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/routers/app_pages.dart';
import 'package:retentio/screen/login/login_screen.dart';

import '../../helpers/test_wrapper.dart';

class _Api extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final Object? data = switch (options.uri.path) {
      '/auth/login' => {'token': 'server-token-123'},
      '/api/decks/catalog/src-1' => {
        'id': 'src-1',
        'name': 'N5',
        'owner': 'o',
        'published_version': 1,
        'fact_count': 1,
      },
      _ => null,
    };
    if (data == null) {
      handler.reject(DioException(requestOptions: options));
      return;
    }
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {'code': 0, 'msg': 'ok', 'data': data},
      ),
    );
  }
}

void main() {
  setUp(() async {
    await setupTestEnvironment();
    networkDioClient.dio.interceptors.add(_Api());
    await registerCoreDependencies();
  });

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  testWidgets('logging in from a deck page returns to that deck page', (
    tester,
  ) async {
    final authBloc = sl<AuthBloc>()..add(const AuthRestoreSessionRequested());
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: AppPages.routes,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );
    AppPages.routes.go('/discovery/src-1');
    await tester.pumpAndSettle();
    expect(authBloc.state.status, AuthStatus.unauthenticated);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Login'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'valid-user');
    await tester.enterText(find.byType(TextField).last, 'valid-password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(DiscoveryDetailScreen), findsOneWidget);
    expect(find.text('N5'), findsOneWidget);

    AppPages.routes.go('/login?from=/discovery/src-1');
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(DiscoveryDetailScreen), findsOneWidget);

    AppPages.routes.go('/login?from=/study');
    await tester.pump();

    expect(
      AppPages.routes.routerDelegate.currentConfiguration.uri.toString(),
      '/',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
