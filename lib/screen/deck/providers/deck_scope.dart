import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/models/deck.dart';

final currentDeckProvider = Provider.autoDispose<Deck>(
  (ref) => throw UnimplementedError(
    'currentDeckProvider must be overridden in DeckViewScreen',
  ),
);
