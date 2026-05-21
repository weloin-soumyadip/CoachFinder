/// Trending-topic chip - icon + label, coloured background.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
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
    return Material(
      color: topic.background,
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
              Icon(topic.icon, color: topic.iconColor, size: 24),
              const SizedBox(height: AppSpacing.sp12),
              Text(
                topic.label,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.neutralBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
