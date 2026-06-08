/// Small shared pieces (rating badge, subject tag, fees label) used by the
/// teacher / center / webinar search result cards.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/models/search_result_model.dart';

/// Tinted "★ 4.8" pill shown beside a result's name.
class RatingBadge extends StatelessWidget {
  /// Creates a rating badge for [rating].
  const RatingBadge({super.key, required this.rating});

  /// The average rating value (0..5).
  final double rating;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: palette.primaryTint,
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.star, size: 13, color: AppColors.ratingStar),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Neutral subject / tag pill.
class SubjectTag extends StatelessWidget {
  /// Creates a tag pill rendering [label].
  const SubjectTag({super.key, required this.label});

  /// The tag text.
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp12,
        vertical: AppSpacing.sp4,
      ),
      decoration: BoxDecoration(
        color: palette.borderSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Formats a [FeesRange] as "₹min – ₹max", or returns null when both bounds
/// are zero (the backend omitted fees) so the caller can fall back.
String? feesLabel(FeesRange fees) {
  if (fees.min <= 0 && fees.max <= 0) return null;
  const String c = AppStrings.searchCurrencyPrefix;
  if (fees.min > 0 && fees.max > 0 && fees.max != fees.min) {
    return '$c${fees.min} ${AppStrings.searchFeesRangeSeparator} $c${fees.max}';
  }
  final int value = fees.max > 0 ? fees.max : fees.min;
  return '$c$value';
}
