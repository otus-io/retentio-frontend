import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordupx/providers/theme_provider.dart';
import 'package:wordupx/services/storage/hydrated_storage.dart';
import '../helpers/in_memory_hydrated_storage.dart';

void main() {
  setUpAll(() {
    HydratedStorage.instance = InMemoryHydratedStorage();
  });

  tearDownAll(() {
    HydratedStorage.instance = null;
  });

  group('ThemeModeNotifier', () {
    test('toJson serializes ThemeMode to index', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      notifier.setThemeMode(ThemeMode.dark);

      final json = notifier.toJson(ThemeMode.dark);
      expect(json, isNotNull);
      expect(json!['mode'], ThemeMode.dark.index);
    });

    test('fromJson deserializes valid index to ThemeMode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      final result = notifier.fromJson({'mode': 0});
      expect(result, ThemeMode.system);
    });

    test('fromJson returns null for invalid index', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      expect(notifier.fromJson({'mode': 99}), isNull);
      expect(notifier.fromJson({'mode': -1}), isNull);
      expect(notifier.fromJson({}), isNull);
    });

    test('toggle cycles through theme modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      notifier.setThemeMode(ThemeMode.light);
      notifier.toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      notifier.toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('setThemeMode updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
