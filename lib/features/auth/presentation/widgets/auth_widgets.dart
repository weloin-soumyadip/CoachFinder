/// Shared widgets used by the login, register, and forgot-password screens.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/neo_button.dart';

/// Full-width filled primary CTA with an optional trailing icon, styled as a
/// neo primary button on the brand fill.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return NeoButton(
      onPressed: onPressed,
      filled: true,
      accent: AppColors.studentPrimary,
      height: 52,
      radius: AppSpacing.sp12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.neutralWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailingIcon != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sp8),
            Icon(trailingIcon, size: 18, color: AppColors.neutralWhite),
          ],
        ],
      ),
    );
  }
}

/// Full-width social-auth button (Google / Facebook), styled as a neo
/// secondary button on the surface fill.
class AuthOAuthButton extends StatelessWidget {
  const AuthOAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return NeoButton(
      onPressed: onPressed,
      filled: false,
      accent: palette.textPrimary,
      height: 52,
      radius: AppSpacing.sp12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 20, color: palette.textPrimary),
          const SizedBox(width: AppSpacing.sp8),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal divider with centred text — "Or".
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: palette.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12),
          child: Text(
            text,
            style: textTheme.labelMedium?.copyWith(color: palette.textMuted),
          ),
        ),
        Expanded(child: Divider(color: palette.border)),
      ],
    );
  }
}

/// Footer link — `prefix` text followed by a blue tappable `actionLabel`.
class AuthBottomLink extends StatelessWidget {
  const AuthBottomLink({
    super.key,
    required this.prefix,
    required this.actionLabel,
    required this.onAction,
  });

  final String prefix;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          prefix,
          style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sp4),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
