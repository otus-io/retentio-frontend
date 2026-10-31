import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/offline_learning/data/offline_deck_catalog.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_sharing_status_cubit.dart';
import 'package:retentio/screen/decks/widgets/deck_screen_body.dart';

import '../../../helpers/test_wrapper.dart';

class _UnusedStore implements OfflineLearningStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Holds every request until [gate] completes, then fails it, so a download
/// stays running and then fails.
class _HeldApi extends Interceptor {
  _HeldApi(this.gate);

  final Completer<void> gate;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await gate.future;
    handler.reject(DioException(requestOptions: options));
  }
}

class _Catalog implements OfflineDeckCatalog {
  @override
  Future<List<Deck>> decks(Future<List<Deck>> Function() fetchRemote) async => [
    Deck.fromJson({'id': 'd1', 'name': 'Just imported'}),
  ];

  @override
  Future<Set<String>> readyDeckIds() async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Runs [act] on the real event loop (Dio needs it), then lets the async
/// work it starts finish and rebuilds.
Future<void> _settle(
  WidgetTester tester, [
  FutureOr<void> Function()? act,
]) async {
  await tester.runAsync(() async {
    await act?.call();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pump();
}

void main() {
  late Completer<void> gate;
  late OfflineLearningSessions sessions;

  setUp(() async {
    await setupTestEnvironment();
    gate = Completer<void>();
    networkDioClient.dio.interceptors.add(_HeldApi(gate));
    sessions = OfflineLearningSessions(
      readUsername: () async => 'user',
      openStore: (_) async => _UnusedStore(),
      documentsDir: () async => Directory.systemTemp.path,
    );
  });

  tearDown(() {
    networkDioClient.dio.interceptors.clear();
    tearDownTestEnvironment();
  });

  Future<DeckListCubit> showList(WidgetTester tester) async {
    late DeckListCubit cubit;
    await tester.runAsync(() async {
      cubit = DeckListCubit(offlineCatalog: _Catalog(), sessions: sessions);
    });
    addTearDown(cubit.close);
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        MultiBlocProvider(
          providers: [
            BlocProvider<DeckListCubit>.value(value: cubit),
            BlocProvider(create: (_) => DeckSharingStatusCubit()),
          ],
          child: const Scaffold(body: DeckScreenBody()),
        ),
      ),
    );
    return cubit;
  }

  Future<void> startDownload() async {
    final session = await sessions.current();
    unawaited(session!.downloader.download('d1'));
  }

  final ring = find.byTooltip('Downloading for offline study…');
  final retry = find.byTooltip('Download failed. Tap to retry');

  testWidgets('a download started before the list loads shows its ring', (
    tester,
  ) async {
    await tester.runAsync(startDownload);

    await showList(tester);
    await _settle(tester);

    expect(find.text('Just imported'), findsOneWidget);
    expect(ring, findsOneWidget);
  });

  testWidgets('the ring appears on a listed deck when its download starts, '
      'then gives way to retry when it fails', (tester) async {
    await showList(tester);
    await _settle(tester);
    expect(find.text('Just imported'), findsOneWidget);
    expect(ring, findsNothing);
    expect(retry, findsNothing);

    await _settle(tester, startDownload);
    expect(ring, findsOneWidget);

    await _settle(tester, gate.complete);
    expect(ring, findsNothing);
    expect(retry, findsOneWidget);
  });
}
