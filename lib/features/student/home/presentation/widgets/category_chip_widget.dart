/// Trending-topic chip - icon + label, coloured background.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_home_data.dart';

/// Single entry in the horizontally-scrolling "Trending Topics" rail.
class CategoryChipWidget extends StatelessWidget {
  const CategoryChipWidget({super.key, required this.topic, this.onTap});

  final TrendingTopic topic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    // Bluish chip via the brand tint (theme-aware: light blue / dark blue). The
    // icon keeps the topic's hue, lightened in dark mode for contrast.
    final Color background = palette.primaryTint;
    final Color iconColor = dark
        ? HSLColor.fromColor(topic.iconColor).withLightness(0.72).toColor()
        : topic.iconColor;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppSpacing.sp16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        child: Container(
          width: 130,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16,
            vertical: AppSpacing.sp16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(topic.icon, color: iconColor, size: 24),
              const SizedBox(height: AppSpacing.sp12),
              Text(
                topic.label,
                style: textTheme.labelLarge?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
