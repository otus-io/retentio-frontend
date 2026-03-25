import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/constants.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/main.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/screen/login/widgets/login_gradient_background.dart';
import 'package:retentio/screen/login/widgets/login_toolbar_controls.dart';
import 'package:retentio/screen/register/register_screen.dart';
import 'package:retentio/utils/util.dart';
import 'package:retentio/widgets/bottom_popup.dart';
import 'package:retentio/screen/login/widgets/forgot_password.dart';

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

    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      body: Stack(
        children: [
          LoginGradientBackground(isDark: isDark),
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
          LoginToolbarControls(isLoading: _isLoading, isDark: isDark),
        ],
      ),
    );
  }
}
