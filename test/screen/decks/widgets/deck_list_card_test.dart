import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/network/network.dart';
import 'package:retentio/features/offline_learning/data/offline_deck_catalog.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/bloc/deck_list_cubit.dart';
import 'package:retentio/screen/decks/bloc/deck_sharing_status_cubit.dart';
import 'package:retentio/screen/decks/widgets/badged_app_icon_button.dart';
import 'package:retentio/screen/decks/widgets/deck_list_card.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_wrapper.dart';

class _EmptyContributionsAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'code': 0,
        'msg': 'ok',
        'data': {'contributions': <Map<String, dynamic>>[]},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ProgressDownloader implements OfflinePackageDownloader {
  final progress = ValueNotifier<double?>(0.3);

  @override
  ValueListenable<double?> progressOf(String deckId) => progress;

  @override
  ValueListenable<bool> failedOf(String deckId) => ValueNotifier(false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReadyCatalog implements OfflineDeckCatalog {
  var readCount = 0;

  @override
  Future<List<Deck>> decks(Future<List<Deck>> Function() fetchRemote) async =>
      const [];

  @override
  Future<Set<String>> readyDeckIds() async {
    readCount++;
    return {'deck-dl'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapCard(Deck deck, {DeckSharingStatusCubit? cubit}) {
  return buildTestableWidgetWithoutProvider(
    BlocProvider(
      create: (_) => cubit ?? DeckSharingStatusCubit(),
      child: Scaffold(body: DeckListCard(deck: deck)),
    ),
  );
}

void main() {
  group('DeckListCard', () {
    testWidgets('shows two decimals when cumulative progress is below 1%', (
      tester,
    ) async {
      final deck = Deck.fromJson({
        'id': 'deck-test-1',
        'name': 'Tiny Progress',
        'stats': {
          'cards_count': 2387,
          'unseen_cards': 2381,
          'due_cards': 0,
          'facts_count': 10,
          'reviewed_cards': 6,
          'hidden_cards': 0,
          'new_cards_today': 0,
          'last_reviewed_at': 0,
        },
        'rate': 10,
        'min_interval': 60,
        'def_interval': 300,
        'max_interval': 86400,
        'owner': {'username': 'u', 'email': 'u@t.com'},
        'fields': ['Front', 'Back'],
      });

      await tester.pumpWidget(_wrapCard(deck));

      expect(find.text('6/2387 (0.25%)'), findsOneWidget);
      expect(find.byTooltip('Publish Deck'), findsOneWidget);
      expect(find.byTooltip('Contributions'), findsOneWidget);
    });

    testWidgets(
      'shows check-updates refresh for imported decks with an update',
      (tester) async {
        final deck = Deck.fromJson({
          'id': 'deck-imported-1',
          'name': 'Imported Deck',
          'source_deck_id': 'source-123',
          'stats': {
            'cards_count': 10,
            'unseen_cards': 5,
            'due_cards': 2,
            'facts_count': 4,
            'reviewed_cards': 5,
            'hidden_cards': 0,
            'new_cards_today': 0,
            'last_reviewed_at': 0,
          },
          'rate': 30,
          'min_interval': 60,
          'def_interval': 300,
          'max_interval': 86400,
          'owner': {'username': 'u', 'email': 'u@t.com'},
          'fields': ['Front', 'Back'],
        });

        await tester.pumpWidget(_wrapCard(deck));

        expect(find.byTooltip('Publish Deck'), findsNothing);
        expect(find.byTooltip('Contributions'), findsNothing);
        // The sync button only shows once the original deck has an update.
        expect(find.byTooltip('Check updates'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _wrapCard(deck, cubit: DeckSharingStatusCubit()..markDirty(deck.id)),
        );
        expect(find.byTooltip('Check updates'), findsOneWidget);
      },
    );

    testWidgets('marks decks that are available offline', (tester) async {
      final deck = Deck.fromJson({'id': 'deck-offline-1', 'name': 'Offline'});

      await tester.pumpWidget(_wrapCard(deck));
      expect(find.byTooltip('Available offline'), findsNothing);

      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          BlocProvider(
            create: (_) => DeckSharingStatusCubit(),
            child: Scaffold(
              body: DeckListCard(deck: deck, availableOffline: true),
            ),
          ),
        ),
      );
      expect(find.byTooltip('Available offline'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
    });

    testWidgets('rereads the offline-ready decks when its download ends', (
      tester,
    ) async {
      final deck = Deck.fromJson({'id': 'deck-dl', 'name': 'Downloading'});
      final downloader = _ProgressDownloader();
      final catalog = _ReadyCatalog();
      final cubit = DeckListCubit(offlineCatalog: catalog);
      addTearDown(cubit.close);
      await tester.pump();
      final before = catalog.readCount;

      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          MultiBlocProvider(
            providers: [
              BlocProvider<DeckListCubit>.value(value: cubit),
              BlocProvider(create: (_) => DeckSharingStatusCubit()),
            ],
            child: Scaffold(
              body: DeckListCard(deck: deck, downloader: downloader),
            ),
          ),
        ),
      );
      expect(find.byTooltip('Downloading for offline study…'), findsOneWidget);

      downloader.progress.value = null;
      await tester.pump();
      await tester.pump();

      expect(catalog.readCount, before + 1);
      expect(cubit.state.offlineReadyDeckIds, {'deck-dl'});
    });

    testWidgets('shows update publish tooltip for published source', (
      tester,
    ) async {
      final deck = Deck.fromJson({
        'id': 'deck-published-1',
        'name': 'Published Deck',
        'published_version': 2,
        'visibility': 'public',
        'stats': {
          'cards_count': 10,
          'unseen_cards': 5,
          'due_cards': 2,
          'facts_count': 4,
          'reviewed_cards': 5,
          'hidden_cards': 0,
          'new_cards_today': 0,
          'last_reviewed_at': 0,
        },
        'rate': 30,
        'min_interval': 60,
        'def_interval': 300,
        'max_interval': 86400,
        'owner': {'username': 'u', 'email': 'u@t.com'},
        'fields': ['Front', 'Back'],
      });

      final cubit = DeckSharingStatusCubit()..markDirty(deck.id);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          BlocProvider.value(
            value: cubit,
            child: Scaffold(body: DeckListCard(deck: deck)),
          ),
        ),
      );

      expect(find.byTooltip('Update Published Version'), findsOneWidget);
      expect(find.byTooltip('Contributions'), findsOneWidget);
      expect(find.byTooltip('Check updates'), findsNothing);
      await cubit.close();
    });

    testWidgets('badges contribution inbox when open contributions exist', (
      tester,
    ) async {
      final deck = Deck.fromJson({
        'id': 'deck-published-2',
        'name': 'Inbox Deck',
        'published_version': 1,
        'stats': {
          'cards_count': 1,
          'unseen_cards': 1,
          'due_cards': 0,
          'facts_count': 1,
          'reviewed_cards': 0,
          'hidden_cards': 0,
          'new_cards_today': 0,
          'last_reviewed_at': 0,
        },
        'rate': 10,
        'min_interval': 60,
        'def_interval': 300,
        'max_interval': 86400,
        'owner': {'username': 'u', 'email': 'u@t.com'},
        'fields': ['Front', 'Back'],
      });

      final cubit = DeckSharingStatusCubit()..markOpenContributions(deck.id);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          BlocProvider.value(
            value: cubit,
            child: Scaffold(body: DeckListCard(deck: deck)),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is BadgedAppIconButton &&
              w.icon == LucideIcons.inbox &&
              w.showBadge,
        ),
        findsOneWidget,
      );
    });

    testWidgets('opens contributions inbox sheet from list card', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await ApiService.clearToken();
      networkDioClient.configure(
        baseUrl: 'http://localhost',
        options: BaseOptions(),
      );
      networkDioClient.dio.httpClientAdapter = _EmptyContributionsAdapter();

      final deck = Deck.fromJson({
        'id': 'deck-inbox-open',
        'name': 'Open Inbox',
        'published_version': 1,
        'stats': {
          'cards_count': 1,
          'unseen_cards': 1,
          'due_cards': 0,
          'facts_count': 1,
          'reviewed_cards': 0,
          'hidden_cards': 0,
          'new_cards_today': 0,
          'last_reviewed_at': 0,
        },
        'rate': 10,
        'min_interval': 60,
        'def_interval': 300,
        'max_interval': 86400,
        'owner': {'username': 'u', 'email': 'u@t.com'},
        'fields': ['Front', 'Back'],
      });

      final cubit = DeckSharingStatusCubit(isOnline: () async => true)
        ..markOpenContributions(deck.id);
      cubit.setDecks([deck]);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          BlocProvider.value(
            value: cubit,
            child: Scaffold(body: DeckListCard(deck: deck)),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Contributions'));
      await tester.pumpAndSettle();

      expect(find.text('No open contributions'), findsOneWidget);

      // Dismiss sheet (barrier tap) so onPressed awaits refresh.
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(cubit.state.hasOpenContributions(deck.id), isFalse);
    });
  });
}
