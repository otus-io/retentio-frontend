import 'dart:async';

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

/// Holds every request until [release] is completed, then accepts it.
class _HeldApi extends Interceptor {
  final release = Completer<void>();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await release.future;
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 201,
        data: {
          'code': 0,
          'msg': 'contribution submitted',
          'data': {'contribution_id': 'cont-1'},
        },
      ),
    );
  }
}

Future<AppLocalizations> _pumpSheet(WidgetTester tester) async {
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

  testWidgets('a typed note stays with a row whose send failed', (
    tester,
  ) async {
    await tester.runAsync(
      () => PendingContributionsStore.of.upsert(
        deckId: 'imp-1',
        kind: PendingContributionKind.deckTags,
        addTags: ['verbs'],
        message: 'old note',
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
    await tester.enterText(find.byType(TextField).last, 'new note');
    await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
    await tester.pumpAndSettle();

    final pending = await tester.runAsync(
      () => PendingContributionsStore.of.listPending('imp-1'),
    );
    expect(pending!.single.message, 'new note');
    expect(pending.single.addTags, ['verbs']);
  });

  testWidgets('closing the sheet during a send does not throw', (tester) async {
    networkDioClient.dio.interceptors.clear();
    final api = _HeldApi();
    networkDioClient.dio.interceptors.add(api);
    await tester.runAsync(
      () => PendingContributionsStore.of.upsert(
        deckId: 'imp-1',
        kind: PendingContributionKind.deckTags,
        addTags: ['verbs'],
      ),
    );
    final loc = await _pumpSheet(tester);

    await tester.tap(find.text('+verbs'));
    await tester.pump();
    await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
    await tester.pump();
    await tester.pumpWidget(buildTestableWidget(const SizedBox()));
    api.release.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      await tester.runAsync(
        () => PendingContributionsStore.of.listPending('imp-1'),
      ),
      isEmpty,
    );
  });

  testWidgets('dismiss counts only rows that were still pending', (
    tester,
  ) async {
    for (final factId in ['f1', 'f2']) {
      await tester.runAsync(
        () => PendingContributionsStore.of.upsert(
          deckId: 'imp-1',
          kind: PendingContributionKind.edit,
          factId: factId,
          preview: 'Fact $factId',
        ),
      );
    }
    final loc = await _pumpSheet(tester);
    await tester.runAsync(
      () => PendingContributionsStore.of.remove(
        'imp-1',
        PendingContributionsStore.of.itemId(
          PendingContributionKind.edit,
          factId: 'f1',
        ),
      ),
    );

    await tester.tap(find.text(loc.pendingSelectAll(2)));
    await tester.pump();
    await tester.tap(find.text(loc.pendingDismissSelected));
    await tester.pumpAndSettle();

    expect(find.text(loc.pendingDismissed(1)), findsOneWidget);
    expect(find.text(loc.pendingSkippedGone(1)), findsOneWidget);
  });

  testWidgets('dismissing only rows already gone says so', (tester) async {
    await tester.runAsync(
      () => PendingContributionsStore.of.upsert(
        deckId: 'imp-1',
        kind: PendingContributionKind.edit,
        factId: 'f1',
        preview: 'Fact f1',
      ),
    );
    final loc = await _pumpSheet(tester);
    await tester.runAsync(
      () => PendingContributionsStore.of.clearPending('imp-1'),
    );

    await tester.tap(find.text(loc.pendingSelectAll(1)));
    await tester.pump();
    await tester.tap(find.text(loc.pendingDismissSelected));
    await tester.pumpAndSettle();

    expect(find.textContaining('Dismissed'), findsNothing);
    expect(find.text(loc.pendingSkippedGone(1)), findsOneWidget);
  });

  testWidgets('clear all replaces an earlier skipped notice', (tester) async {
    for (final factId in ['f1', 'f2']) {
      await tester.runAsync(
        () => PendingContributionsStore.of.upsert(
          deckId: 'imp-1',
          kind: PendingContributionKind.edit,
          factId: factId,
          preview: 'Fact $factId',
        ),
      );
    }
    final loc = await _pumpSheet(tester);
    await tester.runAsync(
      () => PendingContributionsStore.of.remove(
        'imp-1',
        PendingContributionsStore.of.itemId(
          PendingContributionKind.edit,
          factId: 'f1',
        ),
      ),
    );
    await tester.tap(find.textContaining('Fact f1'));
    await tester.pump();
    await tester.tap(find.text(loc.pendingDismissSelected));
    await tester.pumpAndSettle();
    expect(find.text(loc.pendingSkippedGone(1)), findsOneWidget);

    await tester.tap(find.text(loc.pendingClearAll));
    await tester.pumpAndSettle();

    expect(find.text(loc.pendingCleared(1)), findsOneWidget);
    expect(find.text(loc.pendingSkippedGone(1)), findsNothing);
  });

  _descriptionProposalTests();
  _fieldRenameProposalTests();

  testWidgets('report rows stay visible but cannot be sent', (tester) async {
    await tester.runAsync(
      () => PendingContributionsStore.of.upsert(
        deckId: 'imp-1',
        kind: PendingContributionKind.report,
        factId: 'fact-1',
        preview: 'Wrong reading',
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

    expect(find.textContaining('Wrong reading'), findsOneWidget);
    expect(find.textContaining(loc.pendingNotSubmittable), findsOneWidget);
  });
}

void _descriptionProposalTests() {
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

    testWidgets('a row changed since the sheet opened sends its new text', (
      tester,
    ) async {
      final loc = await pumpOutbox(tester, description: 'Old');
      await tester.runAsync(
        () => PendingContributionsStore.of.upsert(
          deckId: 'imp-1',
          kind: PendingContributionKind.description,
          preview: 'New',
          proposedDescription: 'New',
        ),
      );

      await tester.tap(find.text('Everyday verbs'));
      await tester.pump();
      await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
      await tester.pumpAndSettle();

      expect(api.bodies.single, {'proposed_description': 'New'});
    });

    for (final note in ['', 'clearer']) {
      testWidgets('a row removed since the sheet opened is not sent '
          '(note: "$note")', (tester) async {
        final loc = await pumpOutbox(tester, description: 'Everyday verbs');
        await tester.runAsync(
          () => PendingContributionsStore.of.clearPending('imp-1'),
        );

        await tester.tap(find.text('Everyday verbs'));
        await tester.pump();
        await tester.enterText(find.byType(TextField).last, note);
        await tester.tap(find.text(loc.pendingSendSelectedCount(1)));
        await tester.pumpAndSettle();

        expect(api.bodies, isEmpty);
        expect(find.text(loc.pendingSkippedGone(1)), findsOneWidget);
        expect(
          await tester.runAsync(
            () => PendingContributionsStore.of.listPending('imp-1'),
          ),
          isEmpty,
        );
      });
    }

    testWidgets('a skipped row is noted beside the ones that were sent', (
      tester,
    ) async {
      await tester.runAsync(
        () => PendingContributionsStore.of.upsert(
          deckId: 'imp-1',
          kind: PendingContributionKind.fieldRename,
          preview: 'Word · Meaning',
          proposedFields: ['Word', 'Meaning'],
        ),
      );
      final loc = await pumpOutbox(tester, description: 'Everyday verbs');
      await tester.runAsync(
        () => PendingContributionsStore.of.remove(
          'imp-1',
          PendingContributionsStore.of.itemId(
            PendingContributionKind.description,
          ),
        ),
      );

      await tester.tap(find.text(loc.pendingSelectAll(2)));
      await tester.pump();
      await tester.tap(find.text(loc.pendingSendSelectedCount(2)));
      await tester.pumpAndSettle();

      expect(api.bodies, hasLength(1));
      await tester.tap(find.text(loc.pendingTabPending(0)));
      await tester.pumpAndSettle();
      expect(find.text(loc.pendingSendSuccess(1)), findsOneWidget);
      expect(find.text(loc.pendingSkippedGone(1)), findsOneWidget);
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
}

void _fieldRenameProposalTests() {
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
