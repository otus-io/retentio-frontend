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
      showSnack(context, loc.pleaseFillAllFields);
      return;
    }

    setLoading(true);

    try {
      final result = await AuthService.loginByAuthBloc(
        username: username.trim(),
        password: password,
      );

      if (!context.mounted) return;

      final isSuccess = result['token'] != null;

      if (!isSuccess) {
        final rawMsg = result['message'] as String?;
        showSnack(context, ApiErrorMessages.resolve(rawMsg, loc));
        return;
      }

      context.go(AppRoutes.main.path);
    } catch (e) {
      if (!context.mounted) return;
      showSnack(context, ApiErrorMessages.resolve(rawApiErrorMessage(e), loc));
    } finally {
      setLoading(false);
    }
  }
}
