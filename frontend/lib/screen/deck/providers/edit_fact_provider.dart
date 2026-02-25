import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final editFactProvider = NotifierProvider.autoDispose(EditFactNotifier.new);

class EditFactNotifier extends Notifier {
  final TextEditingController answerController = TextEditingController();
  final TextEditingController questionController = TextEditingController();

  @override
  build() {
    ref.onDispose(() {
      answerController.dispose();
      questionController.dispose();
    });
  }
}
