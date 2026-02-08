import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/**
 * Created on 2026/2/8
 * Description:
 */
final createDeckProvider = NotifierProvider.autoDispose(CreateDeckNotifier.new);

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
      templates: [0],
    );
  }

  void changeName(String name) {
    state = state.copyWith(name: name);
  }

  void changeField(int index, String field) {
    state = state.copyWith(
      fields: [
        for (int i = 0; i < state.fields.length; i++)
          if (i == index) field else state.fields[i],
      ],
    );
  }

  void changeTemplate(int index, int template) {
    state = state.copyWith(
      templates: [
        for (int i = 0; i < state.templates.length; i++)
          if (i == index) template else state.templates[i],
      ],
    );
  }

  void createDeck() {}
}

class CreateDeckState {
  final List<String> fields;
  final String name;
  final List<int> templates;

  CreateDeckState({
    this.fields = const [],
    this.name = '',
    this.templates = const [],
  });

  CreateDeckState copyWith({
    List<String>? fields,
    String? name,
    List<int>? templates,
  }) => CreateDeckState(
    fields: fields ?? this.fields,
    name: name ?? this.name,
    templates: templates ?? this.templates,
  );
}
