/// Inbox list tile for a single enquiry: avatar, name + time, optional subject
/// tag, and the message snippet, with an unread treatment for new enquiries.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/models/enquiry_model.dart';

/// Deterministic avatar colours, picked by a stable seed (the enquiry id).
const List<Color> _avatarColors = <Color>[
  Color(0xFF5B7CA0),
  Color(0xFFC97373),
  Color(0xFF7C9F7C),
  Color(0xFF8E7CC3),
  Color(0xFFB07D62),
  Color(0xFF5FA8A0),
];

/// A stable avatar colour for [seed] (the enquiry id).
Color enquiryAvatarColor(String seed) =>
    _avatarColors[seed.hashCode.abs() % _avatarColors.length];

/// A short relative-time label for [dt] (e.g. "20m ago", "Yesterday").
String enquiryTimeAgo(DateTime? dt) {
  if (dt == null) return '';
  final Duration diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return AppStrings.timeJustNow;
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}${AppStrings.timeMinutesAgoSuffix}';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}${AppStrings.timeHoursAgoSuffix}';
  }
  if (diff.inDays == 1) return AppStrings.timeYesterday;
  return '${diff.inDays}${AppStrings.timeDaysAgoSuffix}';
}

/// A tappable enquiry row. New (unread) enquiries get a bolder name, an
/// accent-tinted border, and a "NEW" badge; tapping forwards via [onTap].
class EnquiryTileWidget extends StatelessWidget {
  /// Creates the tile.
  const EnquiryTileWidget({
    super.key,
    required this.enquiry,
    required this.onTap,
  });

  /// The enquiry to render.
  final Enquiry enquiry;

  /// Tap handler.
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
                backgroundColor: enquiryAvatarColor(enquiry.id),
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
                          enquiryTimeAgo(enquiry.createdAt),
                          style: textTheme.labelSmall?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if ((enquiry.subjectName ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sp4),
                      _SubjectTag(subject: enquiry.subjectName!),
                    ],
                    const SizedBox(height: AppSpacing.sp8),
                    Text(
                      enquiry.message,
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

/// Small accent-tinted pill naming the subject the enquiry is about.
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
        color: AppColors.ownerAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.menu_book_outlined,
              size: 12, color: AppColors.ownerAccent),
          const SizedBox(width: AppSpacing.sp4),
          Flexible(
            child: Text(
              subject,
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
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sp8, vertical: 2),
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
