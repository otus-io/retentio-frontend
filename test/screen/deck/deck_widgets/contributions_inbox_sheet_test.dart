import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/models/deck_contribution.dart';
import 'package:retentio/screen/deck/deck_widgets/contributions_inbox_sheet.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/widgets/app_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_wrapper.dart';

class _InboxAdapter implements HttpClientAdapter {
  _InboxAdapter({required this.contributions, this.failIds = const {}});

  final List<Map<String, dynamic>> contributions;
  final Set<String> failIds;
  final List<String> acceptedIds = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final method = options.method;

    if (method == 'GET' && path.contains('/contributions')) {
      // After accepts, return only remaining open rows.
      final open = contributions
          .where((c) => !acceptedIds.contains(c['contribution_id']))
          .toList();
      return _ok({'contributions': open});
    }

    if (method == 'POST' && path.contains('/accept')) {
      final id = path.split('/contributions/').last.split('/').first;
      if (failIds.contains(id)) {
        return _error('accept failed for $id');
      }
      acceptedIds.add(id);
      return _ok({
        'contribution_id': id,
        'type': 'fact_edit',
        'status': 'accepted',
        'working_copy_updated': true,
      });
    }

    if (method == 'PATCH' && path.contains('/contributions/')) {
      return _ok({
        'contribution': {
          'contribution_id': 'patched',
          'type': 'report',
          'status': 'dismissed',
        },
      });
    }

    return _error('not found', 404);
  }

  ResponseBody _ok(Map<String, dynamic> data) => ResponseBody.fromString(
    jsonEncode({'code': 0, 'msg': 'ok', 'data': data}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  ResponseBody _error(String msg, [int status = 400]) =>
      ResponseBody.fromString(
        jsonEncode({'code': -1, 'msg': msg}),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _row({
  required String id,
  required String type,
  String reporter = 'bob',
}) => {
  'contribution_id': id,
  'type': type,
  'status': 'open',
  'reporter': reporter,
  'fact_id': 'fact-1',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _InboxAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.clearToken();
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
  });

  tearDown(() {
    AppToast.dismiss();
  });

  Future<void> pumpInbox(WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        const Scaffold(body: ContributionsInboxSheet(sourceDeckId: 'src-1')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  group('contributionCanAccept', () {
    test('rejects reports only', () {
      expect(
        contributionCanAccept(
          const DeckContribution(id: '1', type: 'fact_edit', status: 'open'),
        ),
        isTrue,
      );
      expect(
        contributionCanAccept(
          const DeckContribution(id: '2', type: 'report', status: 'open'),
        ),
        isFalse,
      );
    });
  });

  group('ContributionsInboxSheet', () {
    testWidgets('shows empty state when inbox has no open rows', (
      tester,
    ) async {
      adapter = _InboxAdapter(contributions: []);
      networkDioClient.dio.httpClientAdapter = adapter;

      await pumpInbox(tester);

      expect(find.text('No open contributions'), findsOneWidget);
      expect(find.textContaining('Accept all'), findsNothing);
    });

    testWidgets('shows Accept all for accept-able rows and skips reports', (
      tester,
    ) async {
      adapter = _InboxAdapter(
        contributions: [
          _row(id: 'c1', type: 'fact_edit'),
          _row(id: 'c2', type: 'report'),
        ],
      );
      networkDioClient.dio.httpClientAdapter = adapter;

      await pumpInbox(tester);

      expect(find.text('Accept all (1)'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('fact edit'), findsOneWidget);
      expect(find.text('report'), findsOneWidget);
    });

    testWidgets('hides Accept all when only reports are open', (tester) async {
      adapter = _InboxAdapter(
        contributions: [_row(id: 'c2', type: 'report')],
      );
      networkDioClient.dio.httpClientAdapter = adapter;

      await pumpInbox(tester);

      expect(find.textContaining('Accept all'), findsNothing);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('Accept all confirm cancel leaves rows unchanged', (
      tester,
    ) async {
      adapter = _InboxAdapter(
        contributions: [
          _row(id: 'c1', type: 'fact_edit'),
          _row(id: 'c2', type: 'fact_add'),
        ],
      );
      networkDioClient.dio.httpClientAdapter = adapter;

      await pumpInbox(tester);
      await tester.tap(find.text('Accept all (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Accept all?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(adapter.acceptedIds, isEmpty);
      expect(find.text('Accept all (2)'), findsOneWidget);
    });

    testWidgets('Accept all accepts every accept-able row', (tester) async {
      adapter = _InboxAdapter(
        contributions: [
          _row(id: 'c1', type: 'fact_edit'),
          _row(id: 'c2', type: 'fact_add'),
          _row(id: 'c3', type: 'report'),
        ],
      );
      networkDioClient.dio.httpClientAdapter = adapter;

      await pumpInbox(tester);
      await tester.tap(find.text('Accept all (2)'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Accept'),
        ),
      );
      await tester.pumpAndSettle();

      expect(adapter.acceptedIds, ['c1', 'c2']);
      expect(find.text('Accepted 2 contributions'), findsOneWidget);
      expect(find.text('Accept all'), findsNothing);
      expect(find.text('report'), findsOneWidget);
      AppToast.dismiss();
    });

    testWidgets('Accept all reports partial failures', (tester) async {
      adapter = _InboxAdapter(
        contributions: [
          _row(id: 'c1', type: 'fact_edit'),
          _row(id: 'c2', type: 'fact_add'),
        ],
        failIds: {'c2'},
      );
      networkDioClient.dio.httpClientAdapter = adapter;

      await pumpInbox(tester);
      await tester.tap(find.text('Accept all (2)'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Accept'),
        ),
      );
      await tester.pumpAndSettle();

      expect(adapter.acceptedIds, ['c1']);
      expect(find.text('Accepted 1; 1 failed'), findsOneWidget);
      AppToast.dismiss();
    });

    testWidgets('Accept all shows error when every accept fails', (
      tester,
    ) async {
      adapter = _InboxAdapter(
        contributions: [_row(id: 'c1', type: 'fact_edit')],
        failIds: {'c1'},
      );
      networkDioClient.dio.httpClientAdapter = adapter;

      await pumpInbox(tester);
      await tester.tap(find.text('Accept all (1)'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Accept'),
        ),
      );
      await tester.pumpAndSettle();

      expect(adapter.acceptedIds, isEmpty);
      expect(find.textContaining('accept failed'), findsOneWidget);
      expect(find.text('Accept all (1)'), findsOneWidget);
      AppToast.dismiss();
    });

    testWidgets('single Accept still works one-by-one', (tester) async {
      adapter = _InboxAdapter(
        contributions: [
          _row(id: 'c1', type: 'fact_edit'),
          _row(id: 'c2', type: 'fact_add'),
        ],
      );
      networkDioClient.dio.httpClientAdapter = adapter;

      await pumpInbox(tester);
      await tester.tap(find.text('Accept').first);
      await tester.pumpAndSettle();

      expect(adapter.acceptedIds, ['c1']);
      expect(find.text('Contribution accepted'), findsOneWidget);
      expect(find.text('Accept all (1)'), findsOneWidget);
      AppToast.dismiss();
    });
  });
}
