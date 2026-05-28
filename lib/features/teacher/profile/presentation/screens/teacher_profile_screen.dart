/// Teacher profile - public listing (read view) + account settings.
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
import '../../../../auth/data/providers/auth_providers.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../data/controllers/teacher_profile_provider.dart';
import '../../data/mock_teacher_profile_data.dart';

/// Teacher profile screen.
///
/// A read view of the tutor's public listing (identity, stats, about, subjects,
/// rate) plus the shared account controls (appearance, settings, sign out),
/// all from [teacherProfileProvider]. The Edit button pushes the edit form;
/// saving there updates this view live. Teal-branded ([AppColors.teacherAccent]),
/// palette-first.
class TeacherProfileScreen extends HookConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TeacherProfile profile = ref.watch(teacherProfileProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

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
      final bool? confirmed = await showDialog<bool>(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.sp8),
                    Row(
                      children: <Widget>[
                        Text(
                          AppStrings.teacherProfileTitle,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.pushNamed(AppRoutes.teacherEditProfile),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(AppStrings.teacherProfileEdit),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.teacherAccent,
                            side: const BorderSide(
                              color: AppColors.teacherAccent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.sp12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sp16),
                    _IdentityCard(profile: profile),
                    const SizedBox(height: AppSpacing.sp16),
                    _StatsStrip(profile: profile),
                    const SizedBox(height: AppSpacing.sp24),
                    const _SectionTitle(title: AppStrings.teacherSectionAbout),
                    const SizedBox(height: AppSpacing.sp12),
                    _Card(
                      child: Text(
                        profile.bio,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp24),
                    const _SectionTitle(
                      title: AppStrings.teacherSectionSubjects,
                    ),
                    const SizedBox(height: AppSpacing.sp12),
                    _ReadChips(labels: profile.subjects),
                    const SizedBox(height: AppSpacing.sp12),
                    Text(
                      profile.expertise,
                      style: textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp24),
                    const _SectionTitle(title: AppStrings.teacherSectionRate),
                    const SizedBox(height: AppSpacing.sp12),
                    _RateCard(profile: profile),
                    const SizedBox(height: AppSpacing.sp24),
                    const _SectionTitle(title: AppStrings.profileAppearance),
                    const SizedBox(height: AppSpacing.sp12),
                    _AppearanceSelector(
                      selected: themeMode,
                      onChanged: setThemeMode,
                    ),
                    const SizedBox(height: AppSpacing.sp24),
                    const _SectionTitle(title: AppStrings.profileSettings),
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

/// Avatar, name, headline, tutor-status badge, rating, and email.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return _Card(
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 36,
            backgroundColor: profile.avatarColor,
            child: Text(
              profile.initial,
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.neutralWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp12),
          Text(
            profile.name,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.headline,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpacing.sp8),
          _StatusBadge(profile: profile),
          const SizedBox(height: AppSpacing.sp12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.star, size: 16, color: AppColors.ratingStar),
              const SizedBox(width: AppSpacing.sp4),
              Text(
                '${profile.rating.toStringAsFixed(1)} '
                '(${profile.reviewCount})',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            profile.email,
            style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Teal-tinted pill: "Independent Tutor", or "At " + the affiliated center.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    final String label = profile.isIndependent
        ? AppStrings.teacherStatusIndependent
        : '${AppStrings.teacherStatusAffiliatedPrefix}${profile.affiliation}';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp12,
        vertical: AppSpacing.sp4,
      ),
      decoration: BoxDecoration(
        color: AppColors.teacherAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.sp24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.verified_outlined,
            size: 14,
            color: AppColors.teacherAccent,
          ),
          const SizedBox(width: AppSpacing.sp4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.teacherAccent,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Read-only views / students / rating / response strip.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: _Stat(
                value: profile.profileViews.toString(),
                label: AppStrings.teacherStatViews,
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _Stat(
                value: profile.studentsTaught.toString(),
                label: AppStrings.teacherStatStudents,
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _Stat(
                value: profile.rating.toStringAsFixed(1),
                label: AppStrings.teacherStatRating,
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _Stat(
                value: '${profile.responseRatePercent}%',
                label: AppStrings.teacherStatResponse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Column(
      children: <Widget>[
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: AppSpacing.sp8,
      endIndent: AppSpacing.sp8,
      color: context.palette.borderSubtle,
    );
  }
}

/// Hourly rate + years of experience.
class _RateCard extends StatelessWidget {
  const _RateCard({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: <Widget>[
          Expanded(
            child: _RateItem(
              icon: Icons.payments_outlined,
              value:
                  '₹${profile.hourlyRate}${AppStrings.teacherRatePerHourSuffix}',
            ),
          ),
          Expanded(
            child: _RateItem(
              icon: Icons.workspace_premium_outlined,
              value: '${profile.experienceYears} '
                  '${AppStrings.teacherExperienceSuffix}',
            ),
          ),
        ],
      ),
    );
  }
}

class _RateItem extends StatelessWidget {
  const _RateItem({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: AppColors.teacherAccent),
        const SizedBox(width: AppSpacing.sp8),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

/// Read-only teal-tinted subject chips.
class _ReadChips extends StatelessWidget {
  const _ReadChips({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sp8,
      runSpacing: AppSpacing.sp8,
      children: <Widget>[
        for (final String label in labels)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp12,
              vertical: AppSpacing.sp8,
            ),
            decoration: BoxDecoration(
              color: AppColors.teacherAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sp24),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.teacherAccent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}

/// System / Light / Dark selector (teal when selected).
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
      color: selected ? AppColors.teacherAccent : palette.surface,
      borderRadius: BorderRadius.circular(AppSpacing.sp12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.sp12),
            border: Border.all(
              color: selected ? AppColors.teacherAccent : palette.border,
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

/// Card of placeholder settings rows.
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
            icon: Icons.event_available_outlined,
            label: AppStrings.teacherSettingsAvailability,
            onTap: onTap,
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.account_balance_wallet_outlined,
            label: AppStrings.teacherSettingsPayouts,
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
            Icon(Icons.chevron_right, size: 22, color: palette.iconFaint),
          ],
        ),
      ),
    );
  }
}

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: child,
    );
  }
}
