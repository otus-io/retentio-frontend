import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:retentio/l10n/app_localizations.dart';
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
      final email = emailController.text;
      if (email.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.pleaseFillAllFields)));
        return;
      }
      isLoading.value = true;
      // TODO: 调用忘记密码接口
      await Future.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.resetPasswordSent)));
      isLoading.value = false;
      Navigator.of(context).pop();
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
            'Enter your account email and we will send a reset link.',
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
