/// Teacher search - find organizations / centers to associate with. Phase 1 placeholder.
library;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Teacher search screen.
///
/// Phase 1 placeholder. Real org/center discovery is built later from a design.
class TeacherSearchScreen extends HookConsumerWidget {
  const TeacherSearchScreen({super.key});

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
              Icons.search,
              color: AppColors.teacherAccent,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sp12),
            Text(
              AppStrings.navSearch,
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
