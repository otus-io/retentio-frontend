import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordupx/l10n/app_localizations.dart';
import 'package:wordupx/pre_config.dart';
import 'package:wordupx/services/storage/hydrated_storage.dart';
import 'package:wordupx/utils/log.dart';

import 'in_memory_hydrated_storage.dart';
import 'path_provider_mock.dart';
import 'shared_preferences_mock.dart';

/// Sets up the test environment for widget tests that use
/// HydratedStorage, SharedPreferences, and path_provider.
Future<void> setupTestEnvironment() async {
  // Silence logger output during widget tests.
  Log.setLevel(Level.off);

  // Setup path_provider mock
  PathProviderMock.setup();

  // Setup shared_preferences mock
  SharedPreferencesMock.setup();

  // Setup shared preferences legacy mock values
  SharedPreferences.setMockInitialValues({});

  // Setup hydrated storage
  HydratedStorage.instance = InMemoryHydratedStorage();

  // Initialize pre-config (this will now work with mocked plugins)
  await PreConfig.init();
}

/// Tears down the test environment.
void tearDownTestEnvironment() {
  // Clear path_provider mock
  PathProviderMock.teardown();

  // Clear shared_preferences mock
  SharedPreferencesMock.teardown();

  // Clear hydrated storage
  HydratedStorage.instance = null;
}

/// Wraps a widget with MaterialApp, localization delegates,
/// and ProviderScope for testing Riverpod widgets.
Widget buildTestableWidget(
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: child,
    ),
  );
}

/// Wraps a widget with MaterialApp and localization delegates only
/// (no ProviderScope), for testing non-Riverpod widgets.
Widget buildTestableWidgetWithoutProvider(
  Widget child, {
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('zh')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    ),
    home: child,
  );
}
