part of 'register_screen.dart';

class RegisterController {
  static Future<void> handleRegister({
    required BuildContext context,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    required Function(bool) setLoading,
    required VoidCallback onSuccess,
  }) async {
    final loc = AppLocalizations.of(context)!;

    if (email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showSnack(context, loc.pleaseFillAllFields);
      return;
    }
    if (password != confirmPassword) {
      showSnack(context, loc.passwordNotMatch);
      return;
    }

    setLoading(true);

    try {
      final result = await AuthService.register(
        email: email,
        username: username,
        password: password,
      );
      if (!context.mounted) return;

      if (result?.isSuccess==true) {
        showSnack(context, '${loc.registerSuccess}: $username');
        onSuccess(); // 通过回调通知 UI 层
      } else {
        showSnack(context, result?.msg ?? '注册失败');
      }
    } catch (e) {
      showSnack(context, '注册失败: $e');
    } finally {
      setLoading(false);
    }
  }
}
