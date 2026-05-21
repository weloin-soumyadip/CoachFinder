/// Shared layout widgets used by the login and register screens.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Branding badge - blue rounded square with the school icon. Sits at the top
/// of the login screen above the "CoachFinder" wordmark.
class AuthBrandingBadge extends StatelessWidget {
  const AuthBrandingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.studentPrimary,
          borderRadius: BorderRadius.circular(AppSpacing.sp16),
        ),
        child: const Icon(
          Icons.school,
          color: AppColors.neutralWhite,
          size: 36,
        ),
      ),
    );
  }
}

/// White rounded card wrapper used by both auth screens.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp24),
      decoration: BoxDecoration(
        color: AppColors.neutralWhite,
        borderRadius: BorderRadius.circular(AppSpacing.sp24),
      ),
      child: child,
    );
  }
}

/// Full-width filled primary CTA with an optional trailing icon.
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
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.studentPrimary,
          foregroundColor: AppColors.neutralWhite,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sp12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.neutralWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailingIcon != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sp8),
              Icon(trailingIcon, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Outlined social-auth button (Google / Apple).
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
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neutralGrey900,
        side: const BorderSide(color: AppColors.neutralGrey200),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sp12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.neutralGrey900),
          const SizedBox(width: AppSpacing.sp8),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.neutralGrey900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal divider with centred text - "or continue with" / "OR EMAIL".
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: AppColors.neutralGrey200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12),
          child: Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.neutralGrey500,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.neutralGrey200)),
      ],
    );
  }
}

/// Footer link - `prefix` text followed by a blue tappable `actionLabel`.
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          prefix,
          style: textTheme.bodyMedium
              ?.copyWith(color: AppColors.neutralGrey700),
        ),
        const SizedBox(width: AppSpacing.sp4),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.studentPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
