import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 本地收藏仓库，以 source_deck_id 为主键，存储于 SharedPreferences。
class DiscoveryFavoritesRepository {
  static const _key = 'discovery_favorite_ids';

  Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final decoded = json.decode(raw);
    if (decoded is! List) return {};
    return Set<String>.from(decoded.whereType<String>());
  }

  Future<void> _save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(ids.toList()));
  }

  Future<Set<String>> addFavorite(String sourceDeckId) async {
    final ids = await loadFavorites();
    ids.add(sourceDeckId);
    await _save(ids);
    return ids;
  }

  Future<Set<String>> removeFavorite(String sourceDeckId) async {
    final ids = await loadFavorites();
    ids.remove(sourceDeckId);
    await _save(ids);
    return ids;
  }

  Future<Set<String>> toggle(String sourceDeckId) async {
    final ids = await loadFavorites();
    if (ids.contains(sourceDeckId)) {
      ids.remove(sourceDeckId);
    } else {
      ids.add(sourceDeckId);
    }
    await _save(ids);
    return ids;
  }
}
