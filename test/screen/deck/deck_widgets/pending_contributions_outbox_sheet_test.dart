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

/// Accepts every `POST …/contributions/description` and records its body.
class _DescriptionApi extends Interceptor {
  final List<dynamic> bodies = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    bodies.add(options.data);
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 201,
        data: {
          'code': 0,
          'msg': 'contribution submitted',
          'data': {'contribution_id': 'cont-desc-1'},
        },
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

  group('description proposals', () {
    late _DescriptionApi api;

    setUp(() {
      networkDioClient.dio.interceptors.clear();
      api = _DescriptionApi();
      networkDioClient.dio.interceptors.add(api);
    });

    Future<AppLocalizations> pumpOutbox(
      WidgetTester tester, {
      String? description,
    }) async {
      await tester.runAsync(
        () => PendingContributionsStore.of.upsert(
          deckId: 'imp-1',
          kind: PendingContributionKind.description,
          preview: 'Everyday verbs',
          proposedDescription: description,
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
      return AppLocalizations.of(
        tester.element(find.byType(PendingContributionsOutboxSheet)),
      )!;
    }

    testWidgets('an unsent description can be sent with a message', (
      tester,
    ) async {
      final loc = await pumpOutbox(tester, description: 'Everyday verbs');

      expect(find.text(loc.pendingKindDescription), findsOneWidget);
      await tester.tap(find.text('Everyday verbs'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'clearer');
      await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
      await tester.pumpAndSettle();

      expect(api.bodies.single, {
        'proposed_description': 'Everyday verbs',
        'message': 'clearer',
      });
      expect(
        await tester.runAsync(
          () => PendingContributionsStore.of.listPending('imp-1'),
        ),
        isEmpty,
      );
    });

    testWidgets('a note saved with the row is sent when none is typed', (
      tester,
    ) async {
      await tester.runAsync(
        () => PendingContributionsStore.of.upsert(
          deckId: 'imp-1',
          kind: PendingContributionKind.description,
          preview: 'Everyday verbs',
          proposedDescription: 'Everyday verbs',
          message: 'saved note',
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

      await tester.tap(find.text('Everyday verbs'));
      await tester.pump();
      await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
      await tester.pumpAndSettle();

      expect(api.bodies.single, {
        'proposed_description': 'Everyday verbs',
        'message': 'saved note',
      });
    });

    testWidgets('a row without its text is not sent', (tester) async {
      final loc = await pumpOutbox(tester);

      await tester.tap(find.text('Everyday verbs'));
      await tester.pump();
      await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
      await tester.pumpAndSettle();

      expect(api.bodies, isEmpty);
      expect(find.textContaining(loc.pendingKindDescription), findsNWidgets(2));
    });
  });

  group('field rename proposals', () {
    late _DescriptionApi api;

    setUp(() {
      networkDioClient.dio.interceptors.clear();
      api = _DescriptionApi();
      networkDioClient.dio.interceptors.add(api);
    });

    Future<AppLocalizations> pumpOutbox(
      WidgetTester tester, {
      List<String>? fields,
    }) async {
      await tester.runAsync(
        () => PendingContributionsStore.of.upsert(
          deckId: 'imp-1',
          kind: PendingContributionKind.fieldRename,
          preview: 'Word · Meaning',
          proposedFields: fields,
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
      return AppLocalizations.of(
        tester.element(find.byType(PendingContributionsOutboxSheet)),
      )!;
    }

    testWidgets('an unsent field rename can be sent with a message', (
      tester,
    ) async {
      final loc = await pumpOutbox(tester, fields: ['Word', 'Meaning']);

      await tester.tap(find.text('Word · Meaning'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'clearer');
      await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
      await tester.pumpAndSettle();

      expect(api.bodies.single, {
        'proposed_fields': ['Word', 'Meaning'],
        'message': 'clearer',
      });
    });

    testWidgets('a row without its fields is not sent', (tester) async {
      final loc = await pumpOutbox(tester);

      await tester.tap(find.text('Word · Meaning'));
      await tester.pump();
      await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
      await tester.pumpAndSettle();

      expect(api.bodies, isEmpty);
      expect(find.textContaining(loc.pendingKindFieldRename), findsNWidgets(2));
    });
  });
}
