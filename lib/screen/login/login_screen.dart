import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/constants.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/screen/login/login_tokens.dart';
import 'package:retentio/screen/login/widgets/forgot_password.dart';
import 'package:retentio/screen/login/widgets/login_gradient_background.dart';
import 'package:retentio/screen/login/widgets/login_toolbar_controls.dart';
import 'package:retentio/screen/register/register_screen.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/utils/util.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';
import 'package:retentio/widgets/bottom_popup.dart';

import '../../services/apis/auth_service.dart';

part 'login_controller.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final appearController = useAnimationController(
      duration: const Duration(milliseconds: LoginTokens.appearDurationMs),
    );
    useEffect(() {
      appearController.forward();
      return null;
    }, [appearController]);

    final loc = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final inputBorder = OutlineInputBorder(
      borderRadius: LoginTokens.fieldRadius,
      borderSide: BorderSide(
        color: scheme.outline.withValues(alpha: isDark ? 0.52 : 0.46),
        width: LoginTokens.hairlineBorderWidth,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          LoginGradientBackground(isDark: isDark),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: LoginTokens.scrollPadding,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: appearController,
                    curve: Curves.easeOut,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: LoginTokens.panelMaxWidth,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: isDark ? 0.92 : 0.98,
                        ),
                        borderRadius: AppThemeTokens.borderRadiusXl,
                        border: Border.all(
                          color: scheme.outlineVariant,
                          width: LoginTokens.hairlineBorderWidth,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(
                              alpha: isDark ? 0.26 : 0.12,
                            ),
                            blurRadius: isDark ? 30 : 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(LoginTokens.spaceXl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    scheme.primary.withValues(alpha: 0.24),
                                    scheme.secondary.withValues(alpha: 0.18),
                                  ],
                                ),
                                borderRadius: AppThemeTokens.borderRadiusMd,
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                  width: LoginTokens.hairlineBorderWidth,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.graduationCap,
                                color: scheme.primary,
                                size: LoginTokens.brandIconSize,
                              ),
                            ),
                            const SizedBox(height: LoginTokens.spaceMd),
                            Text(
                              kAppName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: LoginTokens.spaceXs),
                            Text(
                              'Short daily sessions, lasting memory.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: LoginTokens.spaceXl),
                            AppInput(
                              controller: usernameController,
                              label: loc.username,
                              hint: 'your_username',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              filled: true,
                              fillColor: scheme.surface.withValues(
                                alpha: isDark ? 0.46 : 0.92,
                              ),
                              border: inputBorder,
                              decorationBuilder: (decoration) =>
                                  decoration.copyWith(
                                    enabledBorder: inputBorder,
                                    focusedBorder: inputBorder.copyWith(
                                      borderSide: BorderSide(
                                        color: scheme.primary.withValues(
                                          alpha: 0.62,
                                        ),
                                        width: LoginTokens.hairlineBorderWidth,
                                      ),
                                    ),
                                    labelStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                  ),
                            ),
                            const SizedBox(height: LoginTokens.spaceMd),
                            AppInput(
                              controller: passwordController,
                              label: loc.password,
                              obscureText: true,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              filled: true,
                              fillColor: scheme.surface.withValues(
                                alpha: isDark ? 0.46 : 0.92,
                              ),
                              border: inputBorder,
                              decorationBuilder: (decoration) =>
                                  decoration.copyWith(
                                    enabledBorder: inputBorder,
                                    focusedBorder: inputBorder.copyWith(
                                      borderSide: BorderSide(
                                        color: scheme.primary.withValues(
                                          alpha: 0.62,
                                        ),
                                        width: LoginTokens.hairlineBorderWidth,
                                      ),
                                    ),
                                    labelStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                  ),
                            ),
                            const SizedBox(height: LoginTokens.spaceXl),
                            AppButton(
                              label: loc.login,
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.lg,
                              isLoading: isLoading.value,
                              fullWidth: true,
                              trailing: Icon(
                                LucideIcons.moveRight,
                                size: LoginTokens.arrowIconSize,
                              ),
                              style: FilledButton.styleFrom(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: LoginTokens.fieldRadius,
                                ),
                              ),
                              onPressed: isLoading.value
                                  ? null
                                  : () {
                                      LoginController.handleLogin(
                                        context: context,
                                        username: usernameController.text,
                                        password: passwordController.text,
                                        setLoading: (loading) {
                                          isLoading.value = loading;
                                        },
                                      );
                                    },
                            ),
                            const SizedBox(height: LoginTokens.spaceSm),
                            Row(
                              children: [
                                AppButton(
                                  label: loc.register,
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  style: TextButton.styleFrom(
                                    foregroundColor: scheme.onSurface
                                        .withValues(alpha: 0.74),
                                  ),
                                  onPressed: isLoading.value
                                      ? null
                                      : () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const RegisterScreen(),
                                            ),
                                          );
                                        },
                                ),
                                const Spacer(),
                                AppButton(
                                  label: loc.forgotPassword,
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  style: TextButton.styleFrom(
                                    foregroundColor: scheme.onSurface
                                        .withValues(alpha: 0.74),
                                  ),
                                  onPressed: isLoading.value
                                      ? null
                                      : () {
                                          BottomPopup.show(
                                            context,
                                            child: const ForgotPassword(),
                                            height: LoginTokens
                                                .forgotPasswordPopupHeight,
                                          );
                                        },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          LoginToolbarControls(isLoading: isLoading.value, isDark: isDark),
        ],
      ),
    );
  }
}
