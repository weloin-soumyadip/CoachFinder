/// Trending-topic chip - icon + label, coloured background.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_home_data.dart';

/// Single entry in the "Trending Topics" rail.
///
/// [width] is honoured when the rail scrolls (fixed-size chips); pass null to
/// let the chip fill its parent (e.g. when wrapped in an [Expanded] so the rail
/// spreads chips evenly across a wide row).
class CategoryChipWidget extends StatelessWidget {
  const CategoryChipWidget({
    super.key,
    required this.topic,
    this.onTap,
    this.width,
  });

  final TrendingTopic topic;
  final VoidCallback? onTap;

  /// Fixed chip width, or null to fill the available space.
  final double? width;

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
          width: width,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16,
            vertical: AppSpacing.sp12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(topic.icon, color: iconColor, size: 24),
              const SizedBox(height: AppSpacing.sp8),
              // Cap at two lines + ellipsis so a long label can never overflow
              // the chip's bounded height on a narrow chip.
              Text(
                topic.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
