/// Inbox list tile for a single enquiry: avatar, name + time, course tag, and
/// a one-line snippet, with an unread treatment for new enquiries.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_enquiry_data.dart';

/// A tappable enquiry row. New (unread) enquiries get a bolder name, an
/// accent-tinted border, and a "NEW" badge; tapping forwards via [onTap].
class EnquiryTileWidget extends StatelessWidget {
  const EnquiryTileWidget({
    super.key,
    required this.enquiry,
    required this.onTap,
  });

  final Enquiry enquiry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final bool isNew = enquiry.status == EnquiryStatus.newEnquiry;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(AppSpacing.sp16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sp12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.sp16),
            border: Border.all(
              color: isNew
                  ? AppColors.ownerAccent.withValues(alpha: 0.45)
                  : palette.borderSubtle,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: enquiry.avatarColor,
                child: Text(
                  enquiry.initial,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.neutralWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            enquiry.studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isNew ? FontWeight.w700 : FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        if (isNew) ...<Widget>[
                          const SizedBox(width: AppSpacing.sp8),
                          const _NewBadge(),
                        ],
                        const SizedBox(width: AppSpacing.sp8),
                        Text(
                          enquiry.timeAgo,
                          style: textTheme.labelSmall?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sp4),
                    _CourseTag(course: enquiry.course),
                    const SizedBox(height: AppSpacing.sp8),
                    Text(
                      enquiry.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
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

/// Small accent-tinted pill naming the course/subject the enquiry is about.
class _CourseTag extends StatelessWidget {
  const _CourseTag({required this.course});

  final String course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.ownerAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.menu_book_outlined,
            size: 12,
            color: AppColors.ownerAccent,
          ),
          const SizedBox(width: AppSpacing.sp4),
          Flexible(
            child: Text(
              course,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.ownerAccent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "NEW" pill marking an unread enquiry.
class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.ownerAccent,
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Text(
        AppStrings.enquiriesNewBadge,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.neutralWhite,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
      ),
    );
  }
}
