import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/screen/profile/bloc/profile_cubit.dart';
import 'package:retentio/theme/theme_tokens.dart';

const _kHeaderHorizontalMargin = AppThemeTokens.spaceLg;
const _kHeaderTopMargin = 8.0;
const _kHeaderPadding = 18.0;
const _kAvatarSize = 60.0;
const _kAvatarBackgroundAlpha = 0.12;
const _kAvatarBorderAlpha = 0.25;
const _kAvatarToTextSpacing = 12.0;
const _kNameToEmailSpacing = 2.0;
const _kEmailAlpha = 0.76;

class ProfileUserHeader extends StatelessWidget {
  const ProfileUserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((ProfileCubit cubit) => cubit.state.user);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        _kHeaderHorizontalMargin,
        _kHeaderTopMargin,
        _kHeaderHorizontalMargin,
        0,
      ),
      padding: const EdgeInsets.all(_kHeaderPadding),
      decoration: BoxDecoration(
        borderRadius: AppThemeTokens.borderRadiusXl,
        color: scheme.surfaceContainerHighest,
        border: Border.all(
          color: scheme.outline,
          width: AppThemeTokens.borderWidthHairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: _kAvatarSize,
            height: _kAvatarSize,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: _kAvatarBackgroundAlpha),
              borderRadius: AppThemeTokens.borderRadiusXl,
              border: Border.all(
                color: scheme.primary.withValues(alpha: _kAvatarBorderAlpha),
                width: AppThemeTokens.borderWidthHairline,
              ),
            ),
            child: Center(
              child: Text(
                user.username.isEmpty ? '' : user.username[0].toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: _kAvatarToTextSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: _kNameToEmailSpacing),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: _kEmailAlpha),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
