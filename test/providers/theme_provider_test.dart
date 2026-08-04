import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/services/storage/hydrated_storage.dart';
import '../helpers/in_memory_hydrated_storage.dart';

void main() {
  late InMemoryHydratedStorage storage;

  // Fresh storage per test: assigning the instance also drops the in-memory
  // cache, so persisted state from one test cannot leak into the next.
  setUp(() {
    storage = InMemoryHydratedStorage();
    HydratedStorage.instance = storage;
  });

  tearDown(() {
    HydratedStorage.instance = null;
  });

  group('ThemeModeNotifier', () {
    test('defaults to dark when nothing is hydrated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), AppThemeMode.dark);
    });

    test('a persisted theme wins over the dark default', () {
      final first = ProviderContainer();
      first.read(themeModeProvider.notifier).setThemeMode(AppThemeMode.light);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);

      expect(second.read(themeModeProvider), AppThemeMode.light);
    });

    test('a persisted system theme is not overridden by the dark default', () {
      final first = ProviderContainer();
      first.read(themeModeProvider.notifier).setThemeMode(AppThemeMode.system);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);

      expect(second.read(themeModeProvider), AppThemeMode.system);
    });

    test('toJson serializes AppThemeMode by name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      for (final mode in AppThemeMode.values) {
        final json = notifier.toJson(mode);
        expect(json, isNotNull);
        expect(json!['mode'], mode.name);
        expect(notifier.fromJson(json), mode);
      }
    });

    test('fromJson maps legacy ThemeMode indices to their old meaning', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      // Flutter's ThemeMode: system = 0, light = 1, dark = 2.
      expect(notifier.fromJson({'mode': 0}), AppThemeMode.system);
      expect(notifier.fromJson({'mode': 1}), AppThemeMode.light);
      expect(notifier.fromJson({'mode': 2}), AppThemeMode.dark);
    });

    test('a legacy dark preference survives the upgrade', () async {
      await storage.write('ThemeModeNotifier', {'mode': 2, '__version__': 1});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), AppThemeMode.dark);
    });

    test('fromJson returns null for unusable values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      expect(notifier.fromJson({'mode': 99}), isNull);
      expect(notifier.fromJson({'mode': -1}), isNull);
      expect(notifier.fromJson({'mode': 'ultraviolet'}), isNull);
      expect(notifier.fromJson({'mode': null}), isNull);
      expect(notifier.fromJson({}), isNull);
    });

    test('toggle cycles through theme modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      notifier.setThemeMode(AppThemeMode.light);
      notifier.toggle();
      expect(container.read(themeModeProvider), AppThemeMode.dark);

      notifier.toggle();
      expect(container.read(themeModeProvider), AppThemeMode.sepia);

      notifier.toggle();
      expect(container.read(themeModeProvider), AppThemeMode.light);
    });

    test('toggle from system goes to dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      notifier.setThemeMode(AppThemeMode.system);
      notifier.toggle();

      expect(container.read(themeModeProvider), AppThemeMode.dark);
    });

    test('setThemeMode updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      notifier.setThemeMode(AppThemeMode.dark);
      expect(container.read(themeModeProvider), AppThemeMode.dark);

      notifier.setThemeMode(AppThemeMode.light);
      expect(container.read(themeModeProvider), AppThemeMode.light);
    });
  });
}
