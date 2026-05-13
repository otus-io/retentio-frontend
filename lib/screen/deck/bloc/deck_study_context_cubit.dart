import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/models/deck.dart';

class DeckStudyContextState {
  const DeckStudyContextState({required this.deck});

  final Deck deck;

  DeckStudyContextState copyWith({Deck? deck}) {
    return DeckStudyContextState(deck: deck ?? this.deck);
  }
}

class DeckStudyContextCubit extends Cubit<DeckStudyContextState> {
  DeckStudyContextCubit(Deck deck) : super(DeckStudyContextState(deck: deck));

  void updateDeck(Deck deck) {
    emit(state.copyWith(deck: deck));
  }
}
