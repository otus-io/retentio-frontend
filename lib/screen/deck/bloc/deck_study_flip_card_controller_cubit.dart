import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/screen/deck/card_widgets/card_flip_controller.dart';

class DeckStudyFlipCardControllerCubit extends Cubit<CardFlipController> {
  DeckStudyFlipCardControllerCubit() : super(CardFlipController());

  @override
  Future<void> close() {
    state.dispose();
    return super.close();
  }
}
