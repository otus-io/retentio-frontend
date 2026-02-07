import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordupx/constants.dart';
import 'package:wordupx/l10n/app_localizations.dart';
import 'package:wordupx/providers/theme_provider.dart';

import 'package:wordupx/providers/locale_provider.dart';
import 'package:wordupx/screen/register/register_screen.dart';
import 'package:wordupx/utils/util.dart';
import 'package:wordupx/widgets/bottom_popup.dart';
import 'package:wordupx/screen/login/widgets/forgot_password.dart';

import '../../providers/auth_provider.dart';
import '../../services/apis/auth_service.dart';

part 'login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);

    // 判断当前是否深色模式
    final isDark =
        themeMode == .dark ||
        (themeMode == .system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    // 渐变色
    final List<Color> gradientColors = isDark
        ? [
            const Color(0xFF070A14),
            const Color(0xFF101522),
            const Color(0xFF1A1F2B),
            const Color(0xFF23283A),
          ]
        : [
            const Color(0xFFFFF1EB),
            const Color(0xFFFFD6E0),
            const Color(0xFFFFB4A2),
            const Color(0xFFFFCDB2),
          ];

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 100),
                Text(
                  kAppName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: loc.username,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: loc.password,
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  LoginController.handleLogin(
                                    context: context,
                                    username: _usernameController.text,
                                    password: _passwordController.text,
                                    setLoading: (loading) {
                                      setState(() => _isLoading = loading);
                                    },
                                  );
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(loc.login),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },
                            child: Text(loc.register),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    BottomPopup.show(
                                      context,
                                      child: const ForgotPassword(),
                                      height: 320,
                                    );
                                  },
                            child: Text(loc.forgotPassword),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 右上角语言切换下拉框
          Positioned(
            top: MediaQuery.of(context).padding.top,
            right: 24,
            child: Center(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Locale>(
                  value: const Locale('en'),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  items: const [
                    DropdownMenuItem(
                      value: Locale('en'),
                      child: Text(
                        'ENGLISH',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    DropdownMenuItem(
                      value: Locale('zh'),
                      child: Text(
                        '简体中文',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ],
                  // 语言切换
                  onChanged: _isLoading
                      ? null
                      : (Locale? newLocale) {
                          if (newLocale != null) {
                            ref
                                .read(localeProvider.notifier)
                                .setLocale(newLocale);
                          }
                        },
                ),
              ),
            ),
          ),
          // 左上角深浅色切换按钮
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 24,
            child: IconButton(
              icon: Icon(
                isDark ? CupertinoIcons.moon : CupertinoIcons.sun_max,
                color: Colors.grey,
                size: 22,
              ),
              tooltip: isDark ? '切换到浅色' : '切换到深色',
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(isDark ? .light : .dark);
              },
            ),
          ),
        ],
      ),
    );
  }
}
