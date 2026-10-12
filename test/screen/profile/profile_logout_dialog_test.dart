import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/profile/bloc/profile_cubit.dart';
import 'package:retentio/screen/profile/profile_settings_dialogs.dart';

import '../../helpers/test_wrapper.dart';

class _Offline extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) =>
      handler.reject(DioException(requestOptions: options));
}

class _FakeProfileCubit extends ProfileCubit {
  int logouts = 0;

  @override
  Future<void> getProfile() async {}

  @override
  Future<void> logout() async => logouts++;
}

void main() {
  setUp(() async {
    await setupTestEnvironment();
    networkDioClient.dio.interceptors.add(_Offline());
  });

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  testWidgets('confirming logs out once offline data is settled', (
    tester,
  ) async {
    final cubit = _FakeProfileCubit();
    addTearDown(cubit.close);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showProfileLogoutDialog(
                context,
                cubit,
                AppLocalizations.of(context)!,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(cubit.logouts, 1);
  });
}
