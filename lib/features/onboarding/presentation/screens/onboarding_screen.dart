/// Role selector — writes the chosen role to Hive and routes to login.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_backdrop.dart';
import '../../../../shared/widgets/entrance_fade_slide.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/neo_button.dart';
import '../../../../shared/widgets/neo_surface.dart';

/// A selectable onboarding role, with its own brand accent.
class _RoleOptionData {
  const _RoleOptionData({
    required this.role,
    required this.title,
    required this.blurb,
    required this.icon,
    required this.accent,
  });

  final String role;
  final String title;
  final String blurb;
  final IconData icon;
  final Color accent;
}

/// Onboarding screen — neoglass styling, three-orb brand backdrop, glass role
/// shelf, neo role tiles (the settled (selected) state IS the selection signal),
/// and a neo Continue CTA that re-tweens to the selected role's accent.
class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = useState<String?>(null);
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    final entrance = useAnimationController(
      duration: const Duration(milliseconds: 850),
    );
    useEffect(() {
      entrance.forward();
      return null;
    }, const <Object?>[]);

    final roles = <_RoleOptionData>[
      const _RoleOptionData(
        role: roleStudent,
        title: AppStrings.roleStudentTitle,
        blurb: AppStrings.roleStudentBlurb,
        icon: Icons.school_outlined,
        accent: AppColors.studentPrimary,
      ),
      const _RoleOptionData(
        role: roleOwner,
        title: AppStrings.roleOwnerTitle,
        blurb: AppStrings.roleOwnerBlurb,
        icon: Icons.storefront_outlined,
        accent: AppColors.ownerAccent,
      ),
      const _RoleOptionData(
        role: roleTeacher,
        title: AppStrings.roleTeacherTitle,
        blurb: AppStrings.roleTeacherBlurb,
        icon: Icons.cast_for_education_outlined,
        accent: AppColors.teacherAccent,
      ),
    ];

    Color ctaAccent = AppColors.studentPrimary;
    for (final _RoleOptionData r in roles) {
      if (r.role == selectedRole.value) ctaAccent = r.accent;
    }

    Future<void> handleContinue() async {
      final role = selectedRole.value;
      if (role == null) return;
      await LocalStorage.set(StorageKeys.userRole, role);
      ref.read(roleProvider.notifier).state = role;
      if (!context.mounted) return;
      context.goNamed(AppRoutes.login, extra: role);
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[
          AppColors.studentPrimary,
          AppColors.ownerAccent,
          AppColors.teacherAccent,
        ],
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.sp24,
                            AppSpacing.sp16,
                            AppSpacing.sp24,
                            AppSpacing.sp16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const SizedBox(height: AppSpacing.sp16),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.0,
                                end: 0.45,
                                child: const _Hero(),
                              ),
                              const SizedBox(height: AppSpacing.sp32),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.10,
                                end: 0.55,
                                child: Text(
                                  AppStrings.onboardingTitle,
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp12),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.18,
                                end: 0.63,
                                child: Text(
                                  AppStrings.onboardingSubtitle,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: palette.textMuted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp32),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.26,
                                end: 0.80,
                                child: GlassPanel(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.sp16),
                                  child: Column(
                                    children: <Widget>[
                                      for (int i = 0;
                                          i < roles.length;
                                          i++) ...<Widget>[
                                        if (i > 0)
                                          const SizedBox(
                                              height: AppSpacing.sp12),
                                        _RoleTile(
                                          data: roles[i],
                                          selected: selectedRole.value ==
                                              roles[i].role,
                                          onTap: () => selectedRole.value =
                                              roles[i].role,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: AppSpacing.sp24),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.55,
                                end: 1.0,
                                child: NeoButton(
                                  onPressed: selectedRole.value == null
                                      ? null
                                      : handleContinue,
                                  filled: true,
                                  accent: ctaAccent,
                                  height: 56,
                                  radius: AppSpacing.sp16,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        AppStrings.onboardingContinue,
                                        style: textTheme.titleMedium?.copyWith(
                                          color: AppColors.neutralWhite,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sp8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 18,
                                        color: AppColors.neutralWhite,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Brand lockup: an embossed neo logo badge above the CoachFinder wordmark.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        NeoSurface(
          fill: AppColors.studentPrimary,
          padding: const EdgeInsets.all(AppSpacing.sp16),
          radius: AppSpacing.sp16,
          child: const Icon(
            Icons.school_rounded,
            color: AppColors.neutralWhite,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.sp12),
        Text(
          AppStrings.appName,
          style: textTheme.titleLarge?.copyWith(
            color: context.palette.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A selectable role row — accent icon tile + title + blurb + radio indicator,
/// presented as a [NeoButton] whose settled (selected) state IS the signal.
class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _RoleOptionData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return NeoButton(
      onPressed: onTap,
      selected: selected,
      accent: data.accent,
      filled: false,
      height: null,
      radius: AppSpacing.sp16,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16,
        vertical: AppSpacing.sp16,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sp12),
            ),
            child: Icon(data.icon, color: data.accent, size: 24),
          ),
          const SizedBox(width: AppSpacing.sp16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  data.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp4),
                Text(
                  data.blurb,
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp12),
          _SelectIndicator(selected: selected, accent: data.accent),
        ],
      ),
    );
  }
}

/// Radio-style indicator: outlined circle that fills with [accent] when
/// [selected], with an animated checkmark.
class _SelectIndicator extends StatelessWidget {
  const _SelectIndicator({required this.selected, required this.accent});

  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accent : Colors.transparent,
        border: Border.all(
          color: selected ? accent : palette.border,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: const Icon(
          Icons.check,
          size: 16,
          color: AppColors.neutralWhite,
        ),
      ),
    );
  }
}
