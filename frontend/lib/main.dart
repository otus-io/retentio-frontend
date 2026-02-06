import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wordupx/l10n/app_localizations.dart';
import 'package:wordupx/pre_config.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'screen/login/login_screen.dart';
import 'screen/home/home_screen.dart';
import 'screen/learn/learn_screen.dart';
import 'screen/profile/profile_screen.dart';
import 'services/apis/api_service.dart';

// 全局导航键
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 全局 ProviderContainer
final providerContainer = ProviderContainer();

void main() async {

  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

// 初始化预配置
  PreConfig.init();
  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: ProviderScope(child: const MyApp()),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 等待登录状态加载完成
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final isLogin = ref.watch(isLoginProvider);

    ThemeMode flutterThemeMode;
    switch (themeMode) {
      case ThemeMode.light:
        flutterThemeMode = ThemeMode.light;
        break;
      case ThemeMode.dark:
        flutterThemeMode = ThemeMode.dark;
        break;
      case ThemeMode.system:
        flutterThemeMode = ThemeMode.system;
        break;
    }

    // 显示加载界面直到初始化完成
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '',
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
      themeMode: flutterThemeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainTabScreen(),
      },
      home: isLogin ? const MainTabScreen() : const LoginScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const LearnScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: loc.home),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: loc.learn),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: loc.profile),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
