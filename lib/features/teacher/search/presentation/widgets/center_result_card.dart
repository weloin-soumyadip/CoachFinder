/// Affiliation-center search-result card for the teacher search.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../../../shared/widgets/neo_button.dart';
import '../../data/mock_teacher_search_data.dart';

/// A single coaching center in the teacher search results: a logo tile, name +
/// rating, location, a "Hiring" badge when the center is open to tutors, the
/// subjects it teaches, and a teal "Request to affiliate" action. [onTap]
/// forwards a card tap (placeholder until the center-detail screen exists);
/// [onRequest] fires the affiliate request (a "Coming soon" stub for now).
class CenterResultCard extends StatelessWidget {
  const CenterResultCard({
    super.key,
    required this.center,
    this.onTap,
    this.onRequest,
  });

  final AffiliationCenter center;
  final VoidCallback? onTap;
  final VoidCallback? onRequest;

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
                    _Logo(initial: center.initial, color: center.logoColor),
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
                                  center.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sp8),
                              _RatingBadge(rating: center.rating),
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
                                  center.location,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                              if (center.isHiring) ...<Widget>[
                                const SizedBox(width: AppSpacing.sp8),
                                const _HiringBadge(),
                              ],
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
                    for (final String subject in center.subjects)
                      _TagPill(label: subject),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp16),
                NeoButton(
                  onPressed: onRequest,
                  filled: true,
                  accent: AppColors.teacherAccent,
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      Icon(
                        Icons.handshake_outlined,
                        size: 18,
                        color: AppColors.neutralWhite,
                      ),
                      SizedBox(width: AppSpacing.sp8),
                      Text(AppStrings.teacherSearchRequestAffiliate),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded-square logo tile with the center's initial.
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
        color: AppColors.ratingStar.withValues(alpha: 0.14),
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
                  color: palette.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Small teal "Hiring" badge marking a center open to tutors.
class _HiringBadge extends StatelessWidget {
  const _HiringBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.teacherAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.teacherAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sp4),
          Text(
            AppStrings.teacherSearchHiringBadge,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.teacherAccent,
                  fontWeight: FontWeight.w700,
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
