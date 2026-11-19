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
        showSnack(context, _registerError(result?.msg, loc));
      }
    } catch (e) {
      if (!context.mounted) return;
      showSnack(context, _registerError(rawApiErrorMessage(e), loc));
    } finally {
      setLoading(false);
    }
  }

  /// A taken email is usually the user's own: point them at password reset.
  static String _registerError(String? msg, AppLocalizations loc) =>
      msg?.trim() == 'Email already in use'
      ? loc.registerEmailInUseHint
      : ApiErrorMessages.resolve(msg, loc);
}
