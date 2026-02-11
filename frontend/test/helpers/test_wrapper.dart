import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordupx/l10n/app_localizations.dart';
import 'package:wordupx/services/storage/hydrated_storage.dart';

import 'in_memory_hydrated_storage.dart';

/// Sets up the test environment for widget tests that use
/// HydratedStorage and SharedPreferences.
Future<void> setupTestEnvironment() async {
  SharedPreferences.setMockInitialValues({});
  HydratedStorage.instance = InMemoryHydratedStorage();
}

/// Tears down the test environment.
void tearDownTestEnvironment() {
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
