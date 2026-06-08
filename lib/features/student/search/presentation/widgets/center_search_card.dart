/// Coaching-center search-result card bound to the backend [CenterSearchResult].
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../data/models/search_result_model.dart';
import 'result_avatar_widget.dart';
import 'result_card_parts.dart';

/// A single coaching center in the search results: a logo tile, name + rating
/// badge, a location subtitle, subject tags, and a fees footer. Tapping is
/// forwarded via [onTap] (a no-op placeholder until a center-detail screen
/// lands).
class CenterSearchCard extends StatelessWidget {
  /// Creates a center result card for [center].
  const CenterSearchCard({
    super.key,
    required this.center,
    this.onTap,
    this.headerAction,
  });

  /// The center to render.
  final CenterSearchResult center;

  /// Tap handler (forwarded from the results grid).
  final VoidCallback? onTap;

  /// Optional trailing action in the header row (e.g. a bookmark toggle).
  final Widget? headerAction;

  /// "Area, City" location line (drops empty parts).
  String _location() =>
      <String>[center.area, center.city].where((s) => s.isNotEmpty).join(', ');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final String location = _location();
    final String? fees = feesLabel(center.fees);
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
                      imageUrl: center.profileImage,
                      fallbackLabel: center.name,
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
                                  center.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              if (center.averageRating > 0) ...<Widget>[
                                const SizedBox(width: AppSpacing.sp8),
                                RatingBadge(rating: center.averageRating),
                              ],
                              if (headerAction != null) ...<Widget>[
                                const SizedBox(width: AppSpacing.sp8),
                                headerAction!,
                              ],
                            ],
                          ),
                          if (location.isNotEmpty) ...<Widget>[
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
                                    location,
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
                if (center.subjectsOffered.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sp12),
                  Wrap(
                    spacing: AppSpacing.sp8,
                    runSpacing: AppSpacing.sp8,
                    children: <Widget>[
                      for (final subject in center.subjectsOffered.take(3))
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
