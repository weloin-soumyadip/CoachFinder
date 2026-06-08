/// Teacher search-result card bound to the backend [TeacherSearchResult].
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../data/models/search_result_model.dart';
import 'result_avatar_widget.dart';
import 'result_card_parts.dart';

/// A single teacher in the search results: a circular avatar, name + rating
/// badge, a location / experience subtitle, subject tags, and a fees footer.
/// Tapping is forwarded via [onTap] (a no-op placeholder until a teacher-detail
/// screen lands).
class TeacherSearchCard extends StatelessWidget {
  /// Creates a teacher result card for [teacher].
  const TeacherSearchCard({
    super.key,
    required this.teacher,
    this.onTap,
    this.headerAction,
  });

  /// The teacher to render.
  final TeacherSearchResult teacher;

  /// Tap handler (forwarded from the results grid).
  final VoidCallback? onTap;

  /// Optional trailing action in the header row (e.g. a bookmark toggle).
  final Widget? headerAction;

  /// Location line, or experience as a fallback when no place is set.
  String _subtitle() {
    final String place = <String>[teacher.city, teacher.state]
        .where((s) => s.isNotEmpty)
        .join(', ');
    if (place.isNotEmpty) return place;
    if (teacher.experienceYears > 0) {
      return '${teacher.experienceYears}${AppStrings.searchExperienceSuffix}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final String subtitle = _subtitle();
    final String? fees = feesLabel(teacher.feesRange);
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
                    ResultAvatarWidget(
                      imageUrl: teacher.profileImage,
                      fallbackLabel: teacher.name,
                      circle: true,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              if (teacher.averageRating > 0) ...<Widget>[
                                const SizedBox(width: AppSpacing.sp8),
                                RatingBadge(rating: teacher.averageRating),
                              ],
                              if (headerAction != null) ...<Widget>[
                                const SizedBox(width: AppSpacing.sp8),
                                headerAction!,
                              ],
                            ],
                          ),
                          if (subtitle.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 2),
                            Row(
                              children: <Widget>[
                                if (teacher.isVerified) ...<Widget>[
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: palette.primary,
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                Flexible(
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (teacher.subjects.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sp12),
                  Wrap(
                    spacing: AppSpacing.sp8,
                    runSpacing: AppSpacing.sp8,
                    children: <Widget>[
                      for (final subject in teacher.subjects.take(3))
                        SubjectTag(label: subject),
                    ],
                  ),
                ],
                if (fees != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sp12),
                  Divider(height: 1, color: palette.borderSubtle),
                  const SizedBox(height: AppSpacing.sp12),
                  Text(
                    fees,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
