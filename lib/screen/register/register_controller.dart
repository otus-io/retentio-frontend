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
        username.trim().isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showSnack(context, loc.pleaseFillAllFields);
      return;
    }
    if (password != confirmPassword) {
      showSnack(context, loc.passwordNotMatch);
      return;
    }
    final limitMessage = AccountLimits.limitMessage(
      loc,
      username: username,
      secret: password,
      rejectSpaces: true,
    );
    if (limitMessage != null) {
      showSnack(context, limitMessage);
      return;
    }

    setLoading(true);

    try {
      final result = await AuthService.register(
        email: email,
        username: username.trim(),
        password: password,
      );
      if (!context.mounted) return;

      if (result?.isSuccess == true) {
        showSnack(context, loc.registerSuccessCheckEmail);
        onSuccess();
      } else {
        showSnack(context, ApiErrorMessages.resolve(result?.msg, loc));
      }
    } catch (e) {
      if (!context.mounted) return;
      showSnack(context, ApiErrorMessages.resolve(rawApiErrorMessage(e), loc));
    } finally {
      setLoading(false);
    }
  }
}
