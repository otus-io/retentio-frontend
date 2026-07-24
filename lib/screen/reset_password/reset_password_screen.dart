import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/routers/routers.dart';
import 'package:retentio/services/apis/auth_service.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/utils/util.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';

const _kContentPadding = AppThemeTokens.spaceLg;
const _kCardMaxWidth = 460.0;
const _kCardPadding = AppThemeTokens.spaceXl;
const _kFieldSpacing = AppThemeTokens.spaceMd;
const _kSubtitleSpacing = AppThemeTokens.spaceXs;
const _kIntroSpacing = 14.0;

class ResetPasswordScreen extends HookWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  Widget build(BuildContext context) {
    final passwordController = useTextEditingController();
    final confirmController = useTextEditingController();
    final isLoading = useState(false);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final resetToken = token?.trim() ?? '';

    Future<void> submit() async {
      final password = passwordController.text;
      final confirm = confirmController.text;
      if (resetToken.isEmpty) {
        showSnack(context, loc.resetPasswordMissingToken);
        return;
      }
      if (password.isEmpty || confirm.isEmpty) {
        showSnack(context, loc.pleaseFillAllFields);
        return;
      }
      if (password != confirm) {
        showSnack(context, loc.passwordNotMatch);
        return;
      }

      isLoading.value = true;
      try {
        final result = await AuthService.resetPassword(
          token: resetToken,
          newPassword: password,
        );
        if (!context.mounted) return;
        if (result?.isSuccess == true) {
          showSnack(context, loc.resetPasswordSuccess);
          context.go(AppRoutes.login.path);
        } else {
          showSnack(context, ApiErrorMessages.resolve(result?.msg, loc));
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

    return Scaffold(
      appBar: AppBar(title: Text(loc.resetPasswordTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_kContentPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: AppThemeTokens.borderRadiusXxl,
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.8),
                    width: AppThemeTokens.borderWidthHairline,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_kCardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.resetPasswordTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: _kSubtitleSpacing),
                      Text(
                        loc.resetPasswordHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.64),
                        ),
                      ),
                      const SizedBox(height: _kIntroSpacing),
                      if (resetToken.isEmpty) ...[
                        Text(
                          loc.resetPasswordMissingToken,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                        const SizedBox(height: _kFieldSpacing),
                        AppButton(
                          label: loc.backToLogin,
                          variant: AppButtonVariant.secondary,
                          fullWidth: true,
                          onPressed: () => context.go(AppRoutes.login.path),
                        ),
                      ] else ...[
                        AppInput(
                          controller: passwordController,
                          label: loc.newPassword,
                          obscureText: true,
                        ),
                        const SizedBox(height: _kFieldSpacing),
                        AppInput(
                          controller: confirmController,
                          label: loc.confirmPassword,
                          obscureText: true,
                        ),
                        const SizedBox(height: AppThemeTokens.spaceLg),
                        AppButton(
                          label: loc.resetPassword,
                          variant: AppButtonVariant.primary,
                          isLoading: isLoading.value,
                          fullWidth: true,
                          size: AppButtonSize.lg,
                          onPressed: isLoading.value ? null : submit,
                        ),
                        const SizedBox(height: AppThemeTokens.spaceSm),
                        Align(
                          alignment: Alignment.center,
                          child: AppButton(
                            label: loc.backToLogin,
                            variant: AppButtonVariant.ghost,
                            onPressed: () => context.go(AppRoutes.login.path),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
