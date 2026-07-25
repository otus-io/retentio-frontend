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

const _kContentPadding = AppThemeTokens.spaceLg;
const _kCardMaxWidth = 460.0;
const _kCardPadding = AppThemeTokens.spaceXl;

enum _VerifyStatus { idle, loading, success, error }

class VerifyEmailScreen extends HookWidget {
  const VerifyEmailScreen({super.key, this.token});

  final String? token;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final verifyToken = token?.trim() ?? '';
    final status = useState(
      verifyToken.isEmpty ? _VerifyStatus.error : _VerifyStatus.idle,
    );
    final errorMessage = useState(
      verifyToken.isEmpty ? loc.verifyEmailMissingToken : '',
    );

    Future<void> verify() async {
      if (verifyToken.isEmpty) {
        status.value = _VerifyStatus.error;
        errorMessage.value = loc.verifyEmailMissingToken;
        return;
      }
      status.value = _VerifyStatus.loading;
      try {
        final result = await AuthService.verifyEmail(token: verifyToken);
        if (!context.mounted) return;
        if (result?.isSuccess == true) {
          status.value = _VerifyStatus.success;
          showSnack(context, loc.verifyEmailSuccess);
        } else {
          status.value = _VerifyStatus.error;
          errorMessage.value = ApiErrorMessages.resolve(result?.msg, loc);
        }
      } catch (e) {
        if (!context.mounted) return;
        status.value = _VerifyStatus.error;
        errorMessage.value = ApiErrorMessages.resolve(
          rawApiErrorMessage(e),
          loc,
        );
      }
    }

    useEffect(() {
      if (verifyToken.isEmpty) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) verify();
      });
      return null;
    }, const []);

    final bodyText = switch (status.value) {
      _VerifyStatus.loading || _VerifyStatus.idle => loc.verifyEmailInProgress,
      _VerifyStatus.success => loc.verifyEmailSuccess,
      _VerifyStatus.error => errorMessage.value,
    };

    return Scaffold(
      appBar: AppBar(title: Text(loc.verifyEmailTitle)),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        loc.verifyEmailTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppThemeTokens.spaceMd),
                      if (status.value == _VerifyStatus.loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppThemeTokens.spaceLg,
                          ),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Text(
                          bodyText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: status.value == _VerifyStatus.error
                                ? scheme.error
                                : scheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      const SizedBox(height: AppThemeTokens.spaceLg),
                      if (status.value == _VerifyStatus.error &&
                          verifyToken.isNotEmpty)
                        AppButton(
                          label: loc.retry,
                          variant: AppButtonVariant.secondary,
                          fullWidth: true,
                          onPressed: verify,
                        ),
                      if (status.value == _VerifyStatus.error &&
                          verifyToken.isNotEmpty)
                        const SizedBox(height: AppThemeTokens.spaceSm),
                      AppButton(
                        label: loc.backToLogin,
                        variant: status.value == _VerifyStatus.success
                            ? AppButtonVariant.primary
                            : AppButtonVariant.ghost,
                        fullWidth: true,
                        onPressed: () => context.go(AppRoutes.login.path),
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
