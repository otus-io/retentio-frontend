import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:retentio/core/di/app_service_locator.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/pre_config.dart';
import 'package:retentio/providers/auth_provider.dart';
import 'package:retentio/routers/app_pages.dart';
import 'package:retentio/theme/app_theme.dart';

import 'firebase_options.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'features/discovery/presentation/discovery_screen.dart';
import 'providers/main_tab_provider.dart';
import 'screen/decks/deck_list_screen.dart';
import 'screen/profile/profile_screen.dart';
import 'widgets/app_navigation_bar.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ThemeData _lightTheme = AppTheme.light();
final ThemeData _darkTheme = AppTheme.dark();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await PreConfig.init();
  await registerCoreDependencies();
  final authBloc = sl<AuthBloc>();
  authBloc.add(const AuthRestoreSessionRequested());

  runApp(
    BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    // Initialize auth lifecycle side effects without subscribing this widget
    // to login-state changes.
    ref.read(isLoginProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: AppPages.routes,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeAnimationDuration: Duration.zero,
      themeAnimationCurve: Curves.linear,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        RefreshLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class MainTabScreen extends ConsumerWidget {
  const MainTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(selectedTabIndexProvider);
    final isLoggedIn = ref.watch(isLoginProvider);
    final pages = <Widget>[
      isLoggedIn
          ? const DeckListScreen()
          : const _AuthRequiredTabPlaceholder(tabLabelBuilder: _tabDecksLabel),
      const DiscoveryScreen(),
      isLoggedIn
          ? const ProfileScreen()
          : const _AuthRequiredTabPlaceholder(
              tabLabelBuilder: _tabProfileLabel,
            ),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(selectedTabIndexProvider.notifier).setIndex(index);
        },
      ),
    );
  }
}

String _tabDecksLabel(AppLocalizations loc) => loc.decks;
String _tabProfileLabel(AppLocalizations loc) => loc.profile;

class _AuthRequiredTabPlaceholder extends StatelessWidget {
  const _AuthRequiredTabPlaceholder({required this.tabLabelBuilder});

  final String Function(AppLocalizations loc) tabLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tabLabel = tabLabelBuilder(loc);
    final description = loc.discoveryLoginToAccessTab(tabLabel);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.lock, size: 48, color: scheme.outline),
              const SizedBox(height: 12),
              Text(tabLabel, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: Text(loc.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
