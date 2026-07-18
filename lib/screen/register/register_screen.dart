import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/utils/util.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';

import '../../services/apis/auth_service.dart';

part 'register_controller.dart';

const _kContentPadding = AppThemeTokens.spaceLg;
const _kCardMaxWidth = 460.0;
const _kCardPadding = AppThemeTokens.spaceXl;
const _kCardShadowBlur = 18.0;
const _kCardShadowOffset = Offset(0, 10);
const _kSubtitleSpacing = AppThemeTokens.spaceXs;
const _kIntroSpacing = 14.0;
const _kFieldSpacing = AppThemeTokens.spaceMd;
const _kPrimaryButtonTopSpacing = AppThemeTokens.spaceLg;
const _kBottomActionSpacing = AppThemeTokens.spaceSm;

class RegisterScreen extends HookWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmController = useTextEditingController();
    final isLoading = useState(false);

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(loc.register)),
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
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.08),
                      blurRadius: _kCardShadowBlur,
                      offset: _kCardShadowOffset,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_kCardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create account', style: theme.textTheme.titleLarge),
                      const SizedBox(height: _kSubtitleSpacing),
                      Text(
                        'Start building your long-term memory decks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.64),
                        ),
                      ),
                      const SizedBox(height: _kIntroSpacing),
                      AppInput(
                        controller: emailController,
                        label: loc.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: _kFieldSpacing),
                      AppInput(
                        controller: usernameController,
                        label: loc.username,
                      ),
                      const SizedBox(height: _kFieldSpacing),
                      AppInput(
                        controller: passwordController,
                        label: loc.password,
                        obscureText: true,
                      ),
                      const SizedBox(height: _kFieldSpacing),
                      AppInput(
                        controller: confirmController,
                        label: loc.confirmPassword,
                        obscureText: true,
                      ),
                      const SizedBox(height: _kPrimaryButtonTopSpacing),
                      AppButton(
                        label: loc.register,
                        variant: AppButtonVariant.primary,
                        isLoading: isLoading.value,
                        fullWidth: true,
                        size: AppButtonSize.lg,
                        onPressed: isLoading.value
                            ? null
                            : () {
                                RegisterController.handleRegister(
                                  context: context,
                                  email: emailController.text,
                                  username: usernameController.text,
                                  password: passwordController.text,
                                  confirmPassword: confirmController.text,
                                  setLoading: (loading) {
                                    isLoading.value = loading;
                                  },
                                  onSuccess: () {
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                      ),
                      const SizedBox(height: _kBottomActionSpacing),
                      Align(
                        alignment: Alignment.center,
                        child: AppButton(
                          label: loc.backToLogin,
                          variant: AppButtonVariant.ghost,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
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
