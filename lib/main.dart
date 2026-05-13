import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retentio/core/di/app_service_locator.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/pre_config.dart';
import 'package:retentio/providers/auth_provider.dart';
import 'package:retentio/routers/app_pages.dart';
import 'package:retentio/theme/app_theme.dart';

import 'extensions/context_extension.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screen/decks/deck_list_screen.dart';
import 'screen/home/home_screen.dart';
import 'screen/profile/profile_screen.dart';
import 'widgets/app_navigation_bar.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ThemeData _lightTheme = AppTheme.light();
final ThemeData _darkTheme = AppTheme.dark();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeAnimationDuration: Duration.zero,
      themeAnimationCurve: Curves.linear,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  static const List<Widget> _pages = <Widget>[
    DeckListScreen(),
    HomeScreen(),
    ProfileScreen(),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
