import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/services/apis/deck_service.dart';

/// Inclusive bounds for the rate field when creating or editing a deck.
const int kDeckEditorRateMin = 1;
const int kDeckEditorRateMax = 1000;
const int kDeckEditorRateDefault = 30;

int clampDeckEditorRate(int rate) =>
    rate.clamp(kDeckEditorRateMin, kDeckEditorRateMax);

enum DeckCardType { add, edit }

enum DeckCreateLoadingState { initial, loading, loaded, error }

class DeckCreateState {
  const DeckCreateState({
    required this.name,
    required this.rate,
    required this.deckId,
    required this.cardType,
    this.loadingState = DeckCreateLoadingState.initial,
  });

  final String name;
  final int rate;
  final String deckId;
  final DeckCardType cardType;
  final DeckCreateLoadingState loadingState;

  DeckCreateState copyWith({
    String? name,
    int? rate,
    String? deckId,
    DeckCardType? cardType,
    DeckCreateLoadingState? loadingState,
  }) {
    return DeckCreateState(
      name: name ?? this.name,
      rate: rate ?? this.rate,
      deckId: deckId ?? this.deckId,
      cardType: cardType ?? this.cardType,
      loadingState: loadingState ?? this.loadingState,
    );
  }

  factory DeckCreateState.createMode() {
    return const DeckCreateState(
      name: '',
      rate: kDeckEditorRateDefault,
      deckId: '',
      cardType: DeckCardType.add,
    );
  }
}

class DeckCreateResult {
  const DeckCreateResult({
    required this.success,
    this.message,
    this.updatedDeckName,
  });

  final bool success;
  final String? message;
  final String? updatedDeckName;
}

class DeckCreateCubit extends Cubit<DeckCreateState> {
  DeckCreateCubit({
    required String name,
    required int rate,
    required String deckId,
    required DeckCardType cardType,
  }) : super(
         DeckCreateState(
           name: name,
           rate: clampDeckEditorRate(rate),
           deckId: deckId,
           cardType: cardType,
         ),
       ) {
    nameController.text = name;
  }

  final TextEditingController nameController = TextEditingController();

  @override
  Future<void> close() {
    nameController.dispose();
    return super.close();
  }

  void setMode({
    required String name,
    required int rate,
    required DeckCardType cardType,
    required String deckId,
  }) {
    if (nameController.text != name) {
      nameController.text = name;
    }
    emit(
      state.copyWith(
        name: name,
        rate: clampDeckEditorRate(rate),
        deckId: deckId,
        cardType: cardType,
        loadingState: DeckCreateLoadingState.initial,
      ),
    );
  }

  void changeRate(int rate) {
    emit(
      state.copyWith(
        rate: clampDeckEditorRate(rate),
        loadingState: DeckCreateLoadingState.initial,
      ),
    );
  }

  Future<DeckCreateResult> submit({
    required List<String> fieldNames,
  }) async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      return const DeckCreateResult(
        success: false,
        message: 'Please enter a deck name',
      );
    }

    final fields = fieldNames
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final params = {
      'name': name,
      'fields': fields,
      'rate': clampDeckEditorRate(state.rate),
    };

    emit(state.copyWith(loadingState: DeckCreateLoadingState.loading));

    if (state.cardType == DeckCardType.add) {
      final res = await DeckService.of.createDeck(params);
      if (res?.isSuccess == true) {
        emit(state.copyWith(loadingState: DeckCreateLoadingState.loaded));
        return const DeckCreateResult(success: true);
      }

      emit(state.copyWith(loadingState: DeckCreateLoadingState.error));
      return DeckCreateResult(success: false, message: res?.msg);
    }

    final res = await DeckService.of.updateDeck(
      deckId: state.deckId,
      params: params,
    );
    if (res?.isSuccess == true) {
      emit(state.copyWith(loadingState: DeckCreateLoadingState.loaded));
      return DeckCreateResult(success: true, updatedDeckName: name);
    }

    emit(state.copyWith(loadingState: DeckCreateLoadingState.error));
    return DeckCreateResult(success: false, message: res?.msg);
  }
}
