part of 'login_screen.dart';

class LoginController {
  static Future<void> handleLogin({
    required BuildContext context,
    required String username,
    required String password,
    required Function(bool) setLoading,
  }) async {
    final loc = AppLocalizations.of(context)!;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.pleaseFillAllFields)));
      return;
    }

    setLoading(true);

    try {
      final result = await AuthService.login(
        username: username,
        password: password,
      );

      if (!context.mounted) return;

      final isSuccess = result['token'] != null;

      if (isSuccess) {
        providerContainer.read(isLoginProvider.notifier).setLogin(true);
      } else {
        showSnack(context, result['message']);
      }
    } catch (e) {
      showSnack(context, '登录异常: $e');
    } finally {
      setLoading(false);
    }
  }
}
