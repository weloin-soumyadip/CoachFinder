/// Owner profile screen - identity header, appearance (theme) toggle,
/// settings list, and sign out.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/providers/role_provider.dart';
import '../../../../../core/providers/theme_mode_provider.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../../auth/data/providers/auth_providers.dart';
import '../../data/mock_owner_profile_data.dart';

/// Owner Profile screen.
///
/// Phase 1: the identity block is rendered from fixtures
/// (`mock_owner_profile_data.dart`). The Appearance control is fully wired - it
/// drives the app-wide `themeModeProvider` and persists the choice to Hive,
/// exactly as the student profile does. Settings rows are placeholders (a
/// "Coming soon" snackbar). Sign Out clears the session and role behind a
/// confirmation dialog and returns to onboarding.
///
/// The accent throughout is the owner orange (`AppColors.ownerAccent`) rather
/// than the student blue, so the screen stays on-brand for the owner shell.
class OwnerProfileScreen extends HookConsumerWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    void setThemeMode(ThemeMode mode) {
      ref.read(themeModeProvider.notifier).state = mode;
      LocalStorage.set(StorageKeys.themeMode, mode.name);
    }

    void stub() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.stubComingSoon)),
        );
    }

    Future<void> handleSignOut() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text(AppStrings.profileSignOutConfirmTitle),
          content: const Text(AppStrings.profileSignOutConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.profileSignOutCancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.profileSignOut),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      await ref.read(authControllerProvider.notifier).logout();
      await LocalStorage.remove(StorageKeys.userRole);
      ref.read(roleProvider.notifier).state = null;
      if (!context.mounted) return;
      context.goNamed(AppRoutes.onboarding);
    }

    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: floatingNavClearance(context)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.sp8),
                    Text(
                      AppStrings.profileTitle,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.sp16),
                    _ProfileHeader(onEdit: stub),
                    const SizedBox(height: AppSpacing.sp24),
                    const _SectionHeader(title: AppStrings.profileAppearance),
                    const SizedBox(height: AppSpacing.sp12),
                    _AppearanceSelector(
                      selected: themeMode,
                      onChanged: setThemeMode,
                    ),
                    const SizedBox(height: AppSpacing.sp24),
                    const _SectionHeader(title: AppStrings.profileSettings),
                    const SizedBox(height: AppSpacing.sp12),
                    _SettingsCard(onTap: stub),
                    const SizedBox(height: AppSpacing.sp24),
                    OutlinedButton.icon(
                      onPressed: handleSignOut,
                      icon: const Icon(Icons.logout),
                      label: const Text(AppStrings.profileSignOut),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sp16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sp12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Identity block: avatar (owner initial), owner name, business name, email,
/// and an Edit Profile button.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.ownerAccent,
            child: Text(
              mockOwnerInitial,
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.neutralWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp12),
          Text(
            mockOwnerName,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.business_outlined,
                size: 16,
                color: AppColors.ownerAccent,
              ),
              const SizedBox(width: AppSpacing.sp4),
              Flexible(
                child: Text(
                  mockOwnerBusinessName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ownerAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            mockOwnerEmail,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sp16),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ownerAccent,
              side: const BorderSide(color: AppColors.ownerAccent),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp24,
                vertical: AppSpacing.sp12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sp12),
              ),
            ),
            child: const Text(AppStrings.profileEditButton),
          ),
        ],
      ),
    );
  }
}

/// System / Light / Dark theme selector (three equal-width pills).
class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector({required this.selected, required this.onChanged});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _AppearancePill(
            label: AppStrings.profileThemeSystem,
            icon: Icons.brightness_auto_outlined,
            selected: selected == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
        ),
        const SizedBox(width: AppSpacing.sp8),
        Expanded(
          child: _AppearancePill(
            label: AppStrings.profileThemeLight,
            icon: Icons.light_mode_outlined,
            selected: selected == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
        ),
        const SizedBox(width: AppSpacing.sp8),
        Expanded(
          child: _AppearancePill(
            label: AppStrings.profileThemeDark,
            icon: Icons.dark_mode_outlined,
            selected: selected == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ),
      ],
    );
  }
}

/// One pill in [_AppearanceSelector]: stacked icon + label, owner-orange when
/// selected.
class _AppearancePill extends StatelessWidget {
  const _AppearancePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Color foreground =
        selected ? AppColors.neutralWhite : palette.textSecondary;
    return Material(
      color: selected ? AppColors.ownerAccent : palette.surface,
      borderRadius: BorderRadius.circular(AppSpacing.sp12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.sp12),
            border: Border.all(
              color: selected ? AppColors.ownerAccent : palette.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 20, color: foreground),
              const SizedBox(height: AppSpacing.sp4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card holding the (placeholder) settings rows, divided by hairlines.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        children: <Widget>[
          _SettingsRow(
            icon: Icons.notifications_outlined,
            label: AppStrings.profileNotifications,
            onTap: onTap,
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.receipt_long_outlined,
            label: AppStrings.ownerProfileBilling,
            onTap: onTap,
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.help_outline,
            label: AppStrings.profileHelpSupport,
            onTap: onTap,
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.info_outline,
            label: AppStrings.profileAbout,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// A single tappable settings row: leading icon, label, trailing chevron.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16,
          vertical: AppSpacing.sp16,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: palette.textSecondary),
            const SizedBox(width: AppSpacing.sp16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 22,
              color: palette.iconFaint,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hairline divider between settings rows, indented to align under the labels.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.palette.borderSubtle,
      indent: AppSpacing.sp16,
      endIndent: AppSpacing.sp16,
    );
  }
}

/// Bold section title used above the appearance and settings blocks.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.palette.textPrimary,
          ),
    );
  }
}
