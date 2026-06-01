/// Upcoming-webinar card for the student home "Upcoming Webinars" list.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/neo_button.dart';
import '../../data/models/upcoming_webinar_model.dart';
import 'avatar_image_widget.dart';

/// A single upcoming webinar: thumbnail, title, hosting teacher, the scheduled
/// time, and a Join action. Flat shell-surface card.
class WebinarCardWidget extends StatelessWidget {
  const WebinarCardWidget({super.key, required this.webinar, this.onJoin});

  /// The webinar to render.
  final UpcomingWebinar webinar;

  /// Join handler. Stubbed by the caller (no url_launcher in the stack yet).
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.sp12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AvatarImageWidget(
            imageUrl: webinar.thumbnail,
            fallbackLabel: webinar.title,
            size: 56,
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
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  webinar.teacher.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp4),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: palette.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatSchedule(webinar.scheduledAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp8),
          NeoButton(
            onPressed: onJoin,
            filled: true,
            accent: AppColors.studentPrimary,
            height: 36,
            child: Text(
              AppStrings.homeWebinarJoin,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutralWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats [utc] in the device's local zone as e.g. `May 31, 4:05 PM`. Hand
/// rolled because `intl` is intentionally absent from the dependency set.
String _formatSchedule(DateTime utc) {
  final DateTime t = utc.toLocal();
  final String month = _months[t.month - 1];
  final int hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final String minute = t.minute.toString().padLeft(2, '0');
  final String meridiem = t.hour < 12 ? 'AM' : 'PM';
  return '$month ${t.day}, $hour12:$minute $meridiem';
}
