/// Top coaching-center card for the student home "Top Centers" list.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/models/top_center_model.dart';
import 'avatar_image_widget.dart';

/// A single coaching center: thumbnail, name, location (city · area), and a
/// rating badge with review count. Flat shell-surface card.
class CenterCardWidget extends StatelessWidget {
  const CenterCardWidget({super.key, required this.center, this.onTap});

  /// The center to render.
  final TopCenter center;

  /// Tap handler (stubbed by the caller until center detail is wired here).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final String location = <String>[center.area, center.city]
        .where((String s) => s.trim().isNotEmpty)
        .join(', ');
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
                imageUrl: center.image,
                fallbackLabel: center.name,
                size: 56,
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      center.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (location.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: palette.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sp8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.star,
                            color: AppColors.ratingStar, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          center.averageRating.toStringAsFixed(1),
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sp4),
                        Text(
                          '(${center.totalReviews})',
                          style: textTheme.labelSmall
                              ?.copyWith(color: palette.textMuted),
                        ),
                      ],
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
