import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Per-deck QA column selection (`SharedPreferences`).
class QaColumnPrefs {
  QaColumnPrefs._();

  static String _key(String deckId) => 'qa_columns_$deckId';

  static Future<Set<int>?> load(String deckId) async {
    final raw = (await SharedPreferences.getInstance()).getString(_key(deckId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return {
        for (final value in decoded)
          if (value is int) value else int.tryParse('$value'),
      }.whereType<int>().where((i) => i >= 0).toSet();
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String deckId, Set<int> indexes) async {
    final sorted = indexes.toList()..sort();
    await (await SharedPreferences.getInstance()).setString(
      _key(deckId),
      jsonEncode(sorted),
    );
  }
}
