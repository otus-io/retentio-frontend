import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/providers/loading_state_provider.dart';
import '../../../main.dart';
import '../../../mixins/notifier_mixin.dart';
import '../../../services/apis/deck_service.dart';
import 'deck_provider.dart';

final createDeckProvider = NotifierProvider.autoDispose(CreateDeckNotifier.new);
final createDeckParamsProvider =
    NotifierProvider<DeckParamsNotifier, CreateDeckParams>(
      DeckParamsNotifier.new,
    );

class DeckParamsNotifier extends Notifier<CreateDeckParams> with NotifierMixin {
  DeckParamsNotifier();

  @override
  CreateDeckParams build() {
    return CreateDeckParams(
      name: '',
      rate: 10,
      type: DeckCardType.add,
      id: '',
    );
  }
}

class CreateDeckParams {
  final String name;
  final int rate;
  final String id;
  final DeckCardType type;

  CreateDeckParams({
    required this.name,
    required this.rate,
    required this.type,
    required this.id,
  });

  CreateDeckParams copyWith({
    List<String>? fields,
    String? name,
    List<List<int>>? templates,
    int? rate,
    DeckCardType? type,
    String? id,
  }) => CreateDeckParams(
    name: name ?? this.name,
    rate: rate ?? this.rate,
    type: type ?? this.type,
    id: id ?? this.id,
  );
}

enum DeckCardType { add, edit }

class CreateDeckNotifier extends Notifier<CreateDeckState> {
  // final List<String> languages = [
  //   'English',
  //   'Chinese',
  //   'Spanish',
  //   'Arabic',
  //   'French',
  //   'Russian',
  //   'Portuguese',
  //   'German',
  //   'Japanese',
  // ];
  final TextEditingController nameController = TextEditingController();
  DeckCardType cardType = DeckCardType.add;
  String deckId = '';

  @override
  CreateDeckState build() {
    final params = ref.watch(createDeckParamsProvider);
    var name = params.name;
    var rate = params.rate;
    nameController.text = name;
    deckId = params.id;
    cardType = params.type;

    return CreateDeckState(
      name: name,
      rate: rate,
    );
  }

  void changeRate(int rate) {
    state = state.copyWith(rate: rate);
  }

  void changeField(int index, String field) {
    final fields = [
      for (int i = 0; i < state.fields.length; i++)
        if (i == index) field else state.fields[i],
    ];
    if (fields.first == fields.last) {
      return;
    }
    state = state.copyWith(fields: fields);
  }

  Future<void> createDeck(BuildContext context) async {
    final name = nameController.text;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'name cannot be empty',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (state.fields.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'At least two fields are required',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final params = {
      'name': name,
      'fields': state.fields,
      'rate': state.rate,
    };
    ref.read(loadingStateProvider.notifier).showLoading();
    if (cardType == DeckCardType.add) {
      final res = await DeckService.of.createDeck(params);
      if (res?.isSuccess == true) {
        ref.read(loadingStateProvider.notifier).showLoading();
        await ref.read(deckListProvider.notifier).onRefresh();
        navigatorKey.currentContext?.pop();
      } else {
        ref.read(loadingStateProvider.notifier).showInitial();
        if (res?.msg.isNotEmpty == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res!.msg,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      final res = await DeckService.of.updateDeck(
        deckId: deckId,
        params: params,
      );
      if (res?.isSuccess == true) {
        ref.read(loadingStateProvider.notifier).showLoading();
        await ref.read(deckListProvider.notifier).onRefresh();
        navigatorKey.currentContext?.pop(name);
      } else {
        ref.read(loadingStateProvider.notifier).showInitial();
        if (res?.msg.isNotEmpty == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res!.msg,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class CreateDeckState {
  final List<String> fields;
  final String name;
  final int rate;

  CreateDeckState({
    this.fields = const [],
    this.name = '',
    this.rate = 10,
  });

  CreateDeckState copyWith({
    List<String>? fields,
    String? name,
    int? rate,
  }) => CreateDeckState(
    fields: fields ?? this.fields,
    name: name ?? this.name,
    rate: rate ?? this.rate,
  );
}
