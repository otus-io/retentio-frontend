import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/constants.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/providers/theme_provider.dart';
import 'package:retentio/routers/routers.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          LoginGradientBackground(isDark: isDark),
          _LoginScrollBody(
            appearController: appearController,
            panel: _LoginPanel(
              isDark: isDark,
              isLoading: isLoading.value,
              loc: loc,
              theme: theme,
              scheme: scheme,
              usernameController: usernameController,
              passwordController: passwordController,
              onLoadingChanged: (loading) => isLoading.value = loading,
            ),
          ),
          LoginToolbarControls(isLoading: isLoading.value, isDark: isDark),
        ],
      ),
    );
  }
}

class _LoginScrollBody extends StatelessWidget {
  const _LoginScrollBody({required this.appearController, required this.panel});

  final AnimationController appearController;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              child: panel,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.isDark,
    required this.isLoading,
    required this.loc,
    required this.theme,
    required this.scheme,
    required this.usernameController,
    required this.passwordController,
    required this.onLoadingChanged,
  });

  final bool isDark;
  final bool isLoading;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme scheme;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onLoadingChanged;

  BoxDecoration get _decoration => BoxDecoration(
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
        color: scheme.shadow.withValues(alpha: isDark ? 0.26 : 0.12),
        blurRadius: isDark ? 30 : 24,
        offset: const Offset(0, 14),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _decoration,
      child: Padding(
        padding: const EdgeInsets.all(LoginTokens.spaceXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LoginBrandHeader(theme: theme, scheme: scheme),
            const SizedBox(height: LoginTokens.spaceXl),
            _LoginForm(
              isDark: isDark,
              loc: loc,
              theme: theme,
              scheme: scheme,
              usernameController: usernameController,
              passwordController: passwordController,
            ),
            const SizedBox(height: LoginTokens.spaceXl),
            _LoginActions(
              isLoading: isLoading,
              loc: loc,
              scheme: scheme,
              usernameController: usernameController,
              passwordController: passwordController,
              onLoadingChanged: onLoadingChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader({required this.theme, required this.scheme});

  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/rete_app_icon_mark.png',
          width: LoginTokens.brandBadgeSize,
          height: LoginTokens.brandBadgeSize,
          filterQuality: FilterQuality.high,
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
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.isDark,
    required this.loc,
    required this.theme,
    required this.scheme,
    required this.usernameController,
    required this.passwordController,
  });

  final bool isDark;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme scheme;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  OutlineInputBorder get _inputBorder => OutlineInputBorder(
    borderRadius: LoginTokens.fieldRadius,
    borderSide: BorderSide(
      color: scheme.outline.withValues(alpha: isDark ? 0.52 : 0.46),
      width: LoginTokens.hairlineBorderWidth,
    ),
  );

  InputDecoration _decorate(InputDecoration decoration) {
    final border = _inputBorder;
    return decoration.copyWith(
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: scheme.primary.withValues(alpha: 0.62),
          width: LoginTokens.hairlineBorderWidth,
        ),
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fill = scheme.surface.withValues(alpha: isDark ? 0.46 : 0.92);
    return AutofillGroup(
      child: Column(
        children: [
          AppInput(
            controller: usernameController,
            label: loc.username,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            filled: true,
            fillColor: fill,
            border: _inputBorder,
            decorationBuilder: _decorate,
          ),
          const SizedBox(height: LoginTokens.spaceMd),
          AppInput(
            controller: passwordController,
            label: loc.password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            filled: true,
            fillColor: fill,
            border: _inputBorder,
            decorationBuilder: _decorate,
          ),
        ],
      ),
    );
  }
}

class _LoginActions extends StatelessWidget {
  const _LoginActions({
    required this.isLoading,
    required this.loc,
    required this.scheme,
    required this.usernameController,
    required this.passwordController,
    required this.onLoadingChanged,
  });

  final bool isLoading;
  final AppLocalizations loc;
  final ColorScheme scheme;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onLoadingChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: loc.login,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.lg,
          isLoading: isLoading,
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
          onPressed: isLoading
              ? null
              : () {
                  LoginController.handleLogin(
                    context: context,
                    username: usernameController.text,
                    password: passwordController.text,
                    setLoading: onLoadingChanged,
                  );
                },
        ),
        const SizedBox(height: LoginTokens.spaceSm),
        _LoginSecondaryActions(isLoading: isLoading, loc: loc, scheme: scheme),
      ],
    );
  }
}

class _LoginSecondaryActions extends StatelessWidget {
  const _LoginSecondaryActions({
    required this.isLoading,
    required this.loc,
    required this.scheme,
  });

  final bool isLoading;
  final AppLocalizations loc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final ghostStyle = TextButton.styleFrom(
      foregroundColor: scheme.onSurface.withValues(alpha: 0.74),
    );
    return Row(
      children: [
        AppButton(
          label: loc.register,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          style: ghostStyle,
          onPressed: isLoading
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
        ),
        const Spacer(),
        AppButton(
          label: loc.forgotPassword,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          style: ghostStyle,
          onPressed: isLoading
              ? null
              : () {
                  BottomPopup.show(
                    context,
                    child: const ForgotPassword(),
                    height: LoginTokens.forgotPasswordPopupHeight,
                  );
                },
        ),
      ],
    );
  }
}
