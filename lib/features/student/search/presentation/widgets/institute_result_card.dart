/// Coaching-institute search-result card.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/saved_bookmark_button.dart';
import '../../data/mock_search_data.dart';

/// A single coaching institute / center in the search results: a logo tile,
/// name and rating badge, location, subject tags, and a course count. Tapping
/// is forwarded via [onTap] (a no-op placeholder until the center-detail screen
/// is wired). When [onUnsave] is supplied (e.g. on the Saved screen) a filled
/// bookmark-remove button is shown in the footer; Search leaves it null.
class InstituteResultCard extends StatelessWidget {
  const InstituteResultCard({
    super.key,
    required this.institute,
    this.onTap,
    this.onUnsave,
  });

  final SearchInstitute institute;
  final VoidCallback? onTap;
  final VoidCallback? onUnsave;

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
          padding: const EdgeInsets.all(AppSpacing.sp16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppSpacing.sp16),
            border: Border.all(color: palette.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Logo(initial: institute.initial, color: institute.logoColor),
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
                                institute.name,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sp8),
                            _RatingBadge(rating: institute.rating),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                institute.location,
                                style: textTheme.bodySmall?.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ),
                          ],
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
                  for (final tag in institute.tags) _TagPill(label: tag),
                ],
              ),
              const SizedBox(height: AppSpacing.sp12),
              Divider(height: 1, color: palette.borderSubtle),
              const SizedBox(height: AppSpacing.sp12),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sp4),
                  Expanded(
                    child: Text(
                      '${institute.courseCount} ${AppStrings.searchCoursesSuffix}',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
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
    );
  }
}

/// Rounded-square logo tile with the institute's initial.
class _Logo extends StatelessWidget {
  const _Logo({required this.initial, required this.color});

  final String initial;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
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

/// Small tinted rating pill (star + value) shown beside the name.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

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

/// Neutral subject tag pill.
class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
