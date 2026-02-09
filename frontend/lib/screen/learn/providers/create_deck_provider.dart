import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wordupx/services/index.dart';

import '../../../main.dart';
import '../../../services/apis/api_service.dart';
import 'deck_provider.dart';

final createDeckProvider = NotifierProvider.autoDispose(CreateDeckNotifier.new);

enum Rate {
  slow(10),
  fast(20);

  final int value;

  const Rate(this.value);
}

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

  @override
  CreateDeckState build() {
    return CreateDeckState(
      fields: ['English', 'Chinese'],
      name: '',
      templates: 0,
    );
  }

  void changeRate(Rate rate) {
    state = state.copyWith(rate: rate);
  }

  void changeField(int index, String field) {
    state = state.copyWith(
      fields: [
        for (int i = 0; i < state.fields.length; i++)
          if (i == index) field else state.fields[i],
      ],
    );
  }

  void changeTemplate(int index) {
    state = state.copyWith(templates: index);
  }

  Future<void> createDeck() async {
    await ApiService.post(
      Api.decks,
      body: {
        'fields': state.fields,
        'name': nameController.text,
        'templates': [
          [0, 1],
          if (state.templates == 1) ...[1, 0],
        ],
        'rate': state.rate.value,
      },
    );
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
