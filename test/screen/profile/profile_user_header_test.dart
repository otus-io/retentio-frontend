import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/l10n/app_localizations_en.dart';
import 'package:retentio/screen/profile/bloc/profile_cubit.dart';
import 'package:retentio/screen/profile/widgets/profile_user_header.dart';

import '../../helpers/test_wrapper.dart';

/// Answers GET /api/profile with the given [emailVerified].
class _ProfileInterceptor extends Interceptor {
  _ProfileInterceptor(this.emailVerified);

  final bool emailVerified;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'GET' && options.uri.path.endsWith('/api/profile')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'code': 0,
            'msg': 'ok',
            'data': {
              'email': 'test@example.com',
              'username': 'tester',
              'email_verified': emailVerified,
            },
          },
        ),
      );
      return;
    }
    handler.next(options);
  }
}

void main() {
  final en = AppLocalizationsEn();
  _ProfileInterceptor? interceptor;

  setUpAll(setupTestEnvironment);
  tearDownAll(tearDownTestEnvironment);
  tearDown(() {
    if (interceptor != null) {
      networkDioClient.dio.interceptors.remove(interceptor);
    }
    interceptor = null;
  });

  Future<void> pumpHeader(
    WidgetTester tester, {
    required bool emailVerified,
  }) async {
    interceptor = _ProfileInterceptor(emailVerified);
    networkDioClient.dio.interceptors.add(interceptor!);
    await tester.pumpWidget(
      buildTestableWidget(
        BlocProvider(
          create: (_) => ProfileCubit(
            wipeOfflineData: () async {},
            isOnline: () async => true,
          ),
          child: const Scaffold(body: ProfileUserHeader()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('verified email shows the verified badge and no resend', (
    tester,
  ) async {
    await pumpHeader(tester, emailVerified: true);

    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.byIcon(LucideIcons.badgeCheck), findsOneWidget);
    expect(find.byTooltip(en.emailVerifiedBadge), findsOneWidget);
    expect(find.text(en.resendVerification), findsNothing);
  });

  testWidgets('unverified email shows resend and no badge', (tester) async {
    await pumpHeader(tester, emailVerified: false);

    expect(find.byIcon(LucideIcons.badgeCheck), findsNothing);
    expect(find.text(en.emailNotVerified), findsOneWidget);
    expect(find.text(en.resendVerification), findsOneWidget);
  });
}
