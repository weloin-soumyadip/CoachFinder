/// Coach card used in the Home "Recommended For You" list.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_home_data.dart';

/// A single coach in the recommended list. Renders an avatar (initial on a
/// coloured circle), name and role, tag chips, and a rating + hourly rate.
class FeaturedCardWidget extends StatelessWidget {
  const FeaturedCardWidget({super.key, required this.coach, this.onTap});

  final Coach coach;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    // Subtle bluish surface: brand blue blended into the surface (theme-aware).
    final Color cardColor = Color.alphaBlend(
      AppColors.studentPrimary.withValues(alpha: 0.06),
      palette.surface,
    );
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(AppSpacing.sp16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sp12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.sp16),
            border: Border.all(
              color: AppColors.studentPrimary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _Avatar(initial: coach.initial, color: coach.avatarColor),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      coach.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coach.role,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp8),
                    Wrap(
                      spacing: AppSpacing.sp4,
                      runSpacing: AppSpacing.sp4,
                      children: <Widget>[
                        for (final tag in coach.tags) _TagPill(tag: tag),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.star,
                          color: AppColors.ratingStar, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        coach.rating.toStringAsFixed(1),
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sp8),
                  Text(
                    '\$${coach.hourlyRate}${AppStrings.homePerHourSuffix}',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.priceGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.color});

  final String initial;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.neutralWhite,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag});

  final CoachTag tag;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    // Tint the fixed pastel in dark mode so the pill darkens with the theme;
    // light mode keeps the solid pastel.
    final Color background =
        dark ? tag.background.withValues(alpha: 0.24) : tag.background;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.sp4),
      ),
      child: Text(
        tag.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.palette.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
