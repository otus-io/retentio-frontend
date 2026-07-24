import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/routers/routers.dart';
import 'package:retentio/services/apis/auth_service.dart';
import 'package:retentio/utils/util.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';

const _kSheetPadding = 24.0;
const _kSubtitleSpacing = 6.0;
const _kSectionSpacing = 24.0;

class ForgotPassword extends HookWidget {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final isLoading = useState(false);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Future<void> submit() async {
      final email = emailController.text.trim();
      if (email.isEmpty) {
        showSnack(context, loc.pleaseFillAllFields);
        return;
      }

      isLoading.value = true;
      try {
        final result = await AuthService.forgotPassword(email: email);
        if (!context.mounted) return;

        if (result?.isSuccess != true) {
          showSnack(context, ApiErrorMessages.resolve(result?.msg, loc));
          return;
        }

        showSnack(context, loc.resetPasswordSent);

        String? resetToken;
        final data = result?.data;
        if (data is Map && data['reset_token'] is String) {
          final token = (data['reset_token'] as String).trim();
          if (token.isNotEmpty) resetToken = token;
        }

        Navigator.of(context).pop();
        if (resetToken != null && context.mounted) {
          // Dev without Resend returns the token so the in-app reset flow works.
          context.go(
            '${AppRoutes.resetPassword.path}?token=${Uri.encodeQueryComponent(resetToken)}',
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        showSnack(
          context,
          ApiErrorMessages.resolve(rawApiErrorMessage(e), loc),
        );
      } finally {
        isLoading.value = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(_kSheetPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.forgotPassword, style: theme.textTheme.titleLarge),
          const SizedBox(height: _kSubtitleSpacing),
          Text(
            loc.forgotPasswordHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: _kSectionSpacing),
          AppInput(
            controller: emailController,
            label: loc.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: _kSectionSpacing),
          AppButton(
            label: loc.resetPassword,
            variant: AppButtonVariant.primary,
            isLoading: isLoading.value,
            fullWidth: true,
            onPressed: isLoading.value ? null : submit,
          ),
        ],
      ),
    );
  }
}
