import 'package:equatable/equatable.dart';

sealed class DeckStudyEvent extends Equatable {
  const DeckStudyEvent();

  @override
  List<Object?> get props => const [];
}

class DeckStudyStarted extends DeckStudyEvent {
  const DeckStudyStarted();
}

class DeckStudyShowAnswerToggled extends DeckStudyEvent {
  const DeckStudyShowAnswerToggled();
}

class DeckStudyShowAnswerRequested extends DeckStudyEvent {
  const DeckStudyShowAnswerRequested();
}

class DeckStudyIntervalSelected extends DeckStudyEvent {
  const DeckStudyIntervalSelected(this.intervalSeconds);

  final double intervalSeconds;

  @override
  List<Object?> get props => [intervalSeconds];
}

class DeckStudyNextCardRequested extends DeckStudyEvent {
  const DeckStudyNextCardRequested({this.hideCurrentCard = false});

  final bool hideCurrentCard;

  @override
  List<Object?> get props => [hideCurrentCard];
}

class DeckStudyReviewAgainRequested extends DeckStudyEvent {
  const DeckStudyReviewAgainRequested();
}

class DeckStudyReloadRequested extends DeckStudyEvent {
  const DeckStudyReloadRequested();
}

class DeckStudyDeleteCurrentCardRequested extends DeckStudyEvent {
  const DeckStudyDeleteCurrentCardRequested();
}
