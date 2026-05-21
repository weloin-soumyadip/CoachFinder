/// Role selector - writes the chosen role to Hive and routes to login.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/hive_keys.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/hive_service_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Onboarding screen.
///
/// User picks Student or Coaching Owner, then taps Continue. Selection state is
/// kept locally until Continue: that tap persists the role to Hive, updates
/// [roleProvider], and navigates to the login screen.
class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = useState<String?>(null);
    final textTheme = Theme.of(context).textTheme;

    Future<void> handleContinue() async {
      final role = selectedRole.value;
      if (role == null) return;
      final hive = ref.read(hiveServiceProvider);
      await hive.settingsBox.put(HiveKeys.keyUserRole, role);
      ref.read(roleProvider.notifier).state = role;
      if (!context.mounted) return;
      context.goNamed(AppRoutes.login, extra: role);
    }

    return Scaffold(
      backgroundColor: AppColors.neutralGrey50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.sp8),
              _TopBar(),
              const SizedBox(height: AppSpacing.sp24),
              Text(
                AppStrings.onboardingTitle,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutralBlack,
                ),
              ),
              const SizedBox(height: AppSpacing.sp12),
              Text(
                AppStrings.onboardingSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutralGrey500,
                ),
              ),
              const SizedBox(height: AppSpacing.sp24),
              _RoleCard(
                title: AppStrings.roleStudentTitle,
                blurb: AppStrings.roleStudentBlurb,
                icon: Icons.school,
                iconColor: AppColors.studentPrimary,
                iconBackground: AppColors.studentPrimaryTint,
                selected: selectedRole.value == roleStudent,
                onTap: () => selectedRole.value = roleStudent,
              ),
              const SizedBox(height: AppSpacing.sp16),
              _RoleCard(
                title: AppStrings.roleOwnerTitle,
                blurb: AppStrings.roleOwnerBlurb,
                icon: Icons.storefront,
                iconColor: AppColors.neutralGrey700,
                iconBackground: AppColors.neutralGrey200,
                selected: selectedRole.value == roleOwner,
                onTap: () => selectedRole.value = roleOwner,
              ),
              const Spacer(),
              _ContinueButton(
                enabled: selectedRole.value != null,
                onPressed: handleContinue,
              ),
              const SizedBox(height: AppSpacing.sp16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top bar with back arrow (no-op in Phase 1), CoachFinder wordmark, and a
/// placeholder profile icon.
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Text(
          AppStrings.appName,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.studentPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A selectable role card. Highlighted with a primary-coloured border when
/// [selected] is true.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.blurb,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String blurb;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor =
        selected ? AppColors.studentPrimary : AppColors.neutralGrey200;
    return Material(
      color: AppColors.neutralWhite,
      borderRadius: BorderRadius.circular(AppSpacing.sp16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.sp16),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.sp24),
          child: Column(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: AppSpacing.sp16),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutralBlack,
                ),
              ),
              const SizedBox(height: AppSpacing.sp8),
              Text(
                blurb,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.neutralGrey500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width Continue CTA. Disabled (low-emphasis grey) until a role is
/// picked; once enabled, becomes the filled primary-colour action.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: enabled
              ? AppColors.studentPrimary
              : AppColors.neutralGrey200,
          disabledBackgroundColor: AppColors.neutralGrey200,
          foregroundColor: AppColors.neutralWhite,
          disabledForegroundColor: AppColors.neutralGrey500,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sp16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(AppStrings.onboardingContinue),
            const SizedBox(width: AppSpacing.sp8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}
