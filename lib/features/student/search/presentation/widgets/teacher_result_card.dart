/// Teacher search-result card.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../../../shared/widgets/saved_bookmark_button.dart';
import '../../data/mock_search_data.dart';

/// A single teacher in the search results: avatar (with an online dot), name
/// and rating badge, title, subject tags, and per-session price. Tapping is
/// forwarded via [onTap] (a no-op placeholder until a teacher-detail screen
/// lands). When [onUnsave] is supplied (e.g. on the Saved screen) a filled
/// bookmark-remove button is shown in the footer; Search leaves it null.
class TeacherResultCard extends StatelessWidget {
  const TeacherResultCard({
    super.key,
    required this.teacher,
    this.onTap,
    this.onUnsave,
  });

  final SearchTeacher teacher;
  final VoidCallback? onTap;
  final VoidCallback? onUnsave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    // Frosted-glass card: GlassPanel supplies the translucent fill + hairline;
    // a transparent Material/InkWell on top keeps the tap ripple.
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: AppSpacing.sp16,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.sp16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sp16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Avatar(
                      initial: teacher.initial,
                      color: teacher.avatarColor,
                      online: teacher.online,
                    ),
                    const SizedBox(width: AppSpacing.sp12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  teacher.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sp8),
                              _RatingBadge(rating: teacher.rating),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            teacher.title,
                            style: textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp12),
                Wrap(
                  spacing: AppSpacing.sp8,
                  runSpacing: AppSpacing.sp8,
                  children: <Widget>[
                    for (final tag in teacher.tags) _TagPill(label: tag),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp12),
                Divider(height: 1, color: palette.borderSubtle),
                const SizedBox(height: AppSpacing.sp12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(
                              text: '\$${teacher.sessionPrice}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: AppStrings.searchPerSessionSuffix,
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onUnsave != null) SavedBookmarkButton(onTap: onUnsave!),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular initial avatar with an optional green "available" dot.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initial,
    required this.color,
    required this.online,
  });

  final String initial;
  final Color color;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initial,
              // White initial on the (fixed) coloured avatar - stays white in
              // both themes.
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.neutralWhite,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  // Ring tracks the card surface so the dot reads as a cutout.
                  border: Border.all(color: context.palette.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small tinted rating pill (star + value) shown beside the name.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.palette.primaryTint,
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
                  color: context.palette.primary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Neutral subject tag pill.
class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp12,
        vertical: AppSpacing.sp4,
      ),
      decoration: BoxDecoration(
        color: context.palette.borderSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
