import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  @override
  CreateDeckParams build() {
    return CreateDeckParams(
      fields: ['English', 'Chinese'],
      name: '',
      rate: 10,
      templates: [
        [0, 1],
      ],
      type: DeckCardType.add,
      id: '',
    );
  }
}

class CreateDeckParams {
  final List<String> fields;
  final String name;
  final int rate;
  final String id;
  final List<List<int>> templates;
  final DeckCardType type;

  CreateDeckParams({
    required this.fields,
    required this.name,
    required this.templates,
    required this.rate,
    required this.type,
    required this.id,
  });
}

enum Rate {
  slow(10),
  fast(20);

  final int value;

  const Rate(this.value);

  static Rate fromValue(int value) {
    return Rate.values.firstWhere((element) => element.value == value);
  }
}

enum DeckCardType { add, edit }

class CreateDeckNotifier extends Notifier<CreateDeckState> {
  final List<String> languages = [
    'English',
    'Chinese',
    'Spanish',
    'Arabic',
    'French',
    'Russian',
    'Portuguese',
    'German',
    'Japanese',
  ];
  final TextEditingController nameController = TextEditingController();
  DeckCardType cardType = DeckCardType.add;
  String deckId = '';

  @override
  CreateDeckState build() {
    final params = ref.read(createDeckParamsProvider);
    var fields = params.fields;
    var name = params.name;
    var template = 0;
    var rate = Rate.fromValue(params.rate);
    nameController.text = name;
    deckId = params.id;
    if (params.templates.length == 1) {
      template = 0;
    } else {
      template = 1;
    }
    cardType = params.type;

    return CreateDeckState(
      fields: fields,
      name: name,
      rate: rate,
      templates: template,
    );
  }

  void changeRate(Rate rate) {
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

  void changeTemplate(int index) {
    state = state.copyWith(templates: index);
  }

  Future<void> createDeck() async {
    final params = {
      'fields': state.fields,
      'name': nameController.text,
      'templates': [
        [0, 1],
        if (state.templates == 1) ...[1, 0],
      ],
      'rate': state.rate.value,
    };
    if (cardType == DeckCardType.add) {
      await DeckService.of.createDeck(params);
    } else {
      await DeckService.of.updateDeck(deckId: deckId, params: params);
    }
    await ref.read(deckListProvider.notifier).onRefresh();
    navigatorKey.currentContext?.pop();
  }
}

class CreateDeckState {
  final List<String> fields;
  final String name;
  final int templates;
  final Rate rate;

  CreateDeckState({
    this.fields = const [],
    this.name = '',
    this.templates = 0,
    this.rate = Rate.slow,
  });

  CreateDeckState copyWith({
    List<String>? fields,
    String? name,
    int? templates,
    Rate? rate,
  }) => CreateDeckState(
    fields: fields ?? this.fields,
    name: name ?? this.name,
    templates: templates ?? this.templates,
    rate: rate ?? this.rate,
  );
}
