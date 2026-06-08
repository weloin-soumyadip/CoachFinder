/// Webinar search-result card bound to the backend [WebinarSearchResult].
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../../../shared/widgets/neo_button.dart';
import '../../data/models/search_result_model.dart';
import 'result_avatar_widget.dart';

/// Abbreviated month names for the schedule label (no `intl` in the stack).
const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a UTC [scheduledAt] into a local "Jun 5, 3:30 PM" label.
String formatWebinarSchedule(DateTime scheduledAt) {
  final DateTime local = scheduledAt.toLocal();
  final String month = _months[local.month - 1];
  final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final String minute = local.minute.toString().padLeft(2, '0');
  final String meridiem = local.hour < 12 ? 'AM' : 'PM';
  return '$month ${local.day}, $hour12:$minute $meridiem';
}

/// A single webinar in the search results: thumbnail, title, hosting teacher,
/// scheduled time + duration, a status pill, and a Join button. [onJoin] is
/// invoked by the Join button (a "coming soon" stub until launching is wired).
class WebinarSearchCard extends StatelessWidget {
  /// Creates a webinar result card for [webinar].
  const WebinarSearchCard({
    super.key,
    required this.webinar,
    this.onJoin,
    this.headerAction,
  });

  /// The webinar to render.
  final WebinarSearchResult webinar;

  /// Join handler (forwarded from the results grid).
  final VoidCallback? onJoin;

  /// Optional trailing action in the header row (e.g. a bookmark toggle).
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final String when = formatWebinarSchedule(webinar.scheduledAt);
    final String duration = webinar.durationMinutes > 0
        ? ' · ${webinar.durationMinutes}${AppStrings.searchWebinarMinutesSuffix}'
        : '';
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: AppSpacing.sp16,
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
                  imageUrl: webinar.thumbnail,
                  fallbackLabel: webinar.title,
                ),
                const SizedBox(width: AppSpacing.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        webinar.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (webinar.teacherName.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          webinar.teacherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (webinar.status.isNotEmpty) ...<Widget>[
                  const SizedBox(width: AppSpacing.sp8),
                  _StatusPill(status: webinar.status),
                ],
                if (headerAction != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sp8),
                  headerAction!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sp12),
            Row(
              children: <Widget>[
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sp4),
                Expanded(
                  child: Text(
                    '$when$duration',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sp8),
                NeoButton(
                  onPressed: onJoin,
                  filled: true,
                  accent: palette.primary,
                  height: 40,
                  child: const Text(AppStrings.searchWebinarJoin),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tinted status pill ("Scheduled", "Live", …) coloured by webinar state.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final String label =
        status.isEmpty ? status : status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: palette.primaryTint,
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.primary,
            ),
      ),
    );
  }
}
