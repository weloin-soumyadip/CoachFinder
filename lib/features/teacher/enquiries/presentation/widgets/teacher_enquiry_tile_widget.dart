/// Inbox list tile for a single teacher enquiry: avatar, name + time, subject
/// tag, and a one-line snippet, with an unread treatment for new enquiries.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_teacher_enquiry_data.dart';

/// A tappable enquiry row. New (unread) enquiries get a bolder name, a
/// teal-tinted border, and a "NEW" badge; tapping forwards via [onTap].
class TeacherEnquiryTileWidget extends StatelessWidget {
  const TeacherEnquiryTileWidget({
    super.key,
    required this.enquiry,
    required this.onTap,
  });

  final TeacherEnquiry enquiry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final bool isNew = enquiry.status == TeacherEnquiryStatus.newEnquiry;
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
                  ? AppColors.teacherAccent.withValues(alpha: 0.45)
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
                    _SubjectTag(subject: enquiry.subject),
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

/// Small teal-tinted pill naming the subject the enquiry is about.
class _SubjectTag extends StatelessWidget {
  const _SubjectTag({required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.teacherAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.menu_book_outlined,
            size: 12,
            color: AppColors.teacherAccent,
          ),
          const SizedBox(width: AppSpacing.sp4),
          Flexible(
            child: Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.teacherAccent,
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
        color: AppColors.teacherAccent,
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
