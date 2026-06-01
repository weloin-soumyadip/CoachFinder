/// Top-teacher card for the student home "Recommended For You" list.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/models/top_teacher_model.dart';
import 'avatar_image_widget.dart';

/// A single recommended teacher: avatar, name, the subjects they teach, and a
/// rating badge with review count. Flat shell-surface card (no glass in lists).
class TeacherCardWidget extends StatelessWidget {
  const TeacherCardWidget({super.key, required this.teacher, this.onTap});

  /// The teacher to render.
  final TopTeacher teacher;

  /// Tap handler (stubbed by the caller until teacher detail lands).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(AppSpacing.sp16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.sp16),
            border: Border.all(color: palette.borderSubtle),
          ),
          padding: const EdgeInsets.all(AppSpacing.sp12),
          child: Row(
            children: <Widget>[
              AvatarImageWidget(
                imageUrl: teacher.profileImage,
                fallbackLabel: teacher.name,
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      teacher.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (teacher.subjects.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        teacher.subjects.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sp8),
                    _RatingRow(
                      rating: teacher.averageRating,
                      reviews: teacher.totalReviews,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Amber star + rating value, with a muted "(N)" review count beside it.
class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.reviews});

  final double rating;
  final int reviews;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.star, color: AppColors.ratingStar, size: 14),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.sp4),
        Text(
          '($reviews)',
          style: textTheme.labelSmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}
