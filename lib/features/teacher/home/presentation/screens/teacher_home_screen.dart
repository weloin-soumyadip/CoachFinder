/// Teacher home - overview of sessions and activity. Phase 1 placeholder.
library;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Teacher home screen.
///
/// Phase 1 placeholder. The real overview (upcoming sessions, quick stats) is
/// built later from a design.
class TeacherHomeScreen extends HookConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.home_outlined,
              color: AppColors.teacherAccent,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sp12),
            Text(
              AppStrings.navHome,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sp4),
            Text(
              AppStrings.teacherComingSoon,
              style: textTheme.bodyMedium?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
