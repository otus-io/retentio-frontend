import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/contributions/pending_contributions_store.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/deck_widgets/pending_contributions_outbox_sheet.dart';

import '../../../helpers/test_wrapper.dart';

class _UnverifiedApi extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 403,
          data: {
            'msg': 'Email verification required',
            'code': 'email_not_verified',
          },
        ),
      ),
    );
  }
}

void main() {
  setUp(() async {
    await setupTestEnvironment();
    networkDioClient.dio.interceptors.add(_UnverifiedApi());
  });

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  testWidgets('a send blocked by email verification explains what to do', (
    tester,
  ) async {
    await tester.runAsync(
      () => PendingContributionsStore.of.upsert(
        deckId: 'imp-1',
        kind: PendingContributionKind.deckTags,
        addTags: ['verbs'],
      ),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        const Scaffold(
          body: SingleChildScrollView(
            child: PendingContributionsOutboxSheet(importDeckId: 'imp-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final loc = AppLocalizations.of(
      tester.element(find.byType(PendingContributionsOutboxSheet)),
    )!;
    await tester.tap(find.text('+verbs'));
    await tester.pump();
    await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
    await tester.pumpAndSettle();

    expect(
      find.text('${loc.pendingKindDeckTags}: ${loc.emailVerificationRequired}'),
      findsOneWidget,
    );
  });
}
