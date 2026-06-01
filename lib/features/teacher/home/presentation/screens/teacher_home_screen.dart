/// Teacher home - an activity control center: greeting, headline stats, the
/// day's sessions, a recent-enquiries preview, and profile quick actions.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../../../shared/widgets/brand_backdrop.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../../../shared/widgets/neo_surface.dart';
import '../../../../../shared/widgets/neo_button.dart';
import '../../../enquiries/data/mock_teacher_enquiry_data.dart';
import '../../../profile/data/controllers/teacher_profile_provider.dart';
import '../../../profile/data/mock_teacher_profile_data.dart';
import '../../data/mock_teacher_home_data.dart';

/// Teacher home screen.
///
/// Phase 1: the headline stats are read live from [teacherProfileProvider]; the
/// day's sessions and recent enquiries come from `mock_teacher_home_data.dart`.
/// When the backend lands the fixtures are swapped for a controller-backed
/// `AsyncValue` and the layout stays unchanged. Edit Profile pushes the real
/// edit route; Share Profile, the bell, and enquiry taps are placeholders
/// ("Coming soon" snackbar). Teal-branded ([AppColors.teacherAccent]).
class TeacherHomeScreen extends HookConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final TeacherProfile profile = ref.watch(teacherProfileProvider);

    void stub() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.stubComingSoon)),
        );
    }

    void openEditProfile() => context.pushNamed(AppRoutes.teacherEditProfile);

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[AppColors.teacherAccent],
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: floatingNavClearance(context)),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: AppSpacing.sp8),
                      GlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.sp16),
                        child: _Header(profile: profile, onBell: stub),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      _StatGrid(profile: profile),
                      const SizedBox(height: AppSpacing.sp24),
                      const _SectionHeader(
                        title: AppStrings.teacherHomeTodaySessions,
                      ),
                      const SizedBox(height: AppSpacing.sp12),
                      const _SessionsList(sessions: mockTeacherSessions),
                      const SizedBox(height: AppSpacing.sp24),
                      _SectionHeader(
                        title: AppStrings.teacherHomeRecentEnquiries,
                        trailing: GestureDetector(
                          onTap: stub,
                          child: Text(
                            AppStrings.teacherHomeViewAll,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.teacherAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp12),
                      _EnquiriesList(
                        enquiries: mockTeacherEnquiries.take(3).toList(),
                        onTap: stub,
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      _QuickActions(
                        onEditProfile: openEditProfile,
                        onShareProfile: stub,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A bold section title with an optional trailing action (e.g. "View all").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Greeting block: teacher first name + an independent/affiliation status line
/// on the left, a notifications bell (stub) on the right.
class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.onBell});

  final TeacherProfile profile;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final String firstName =
        profile.name.isEmpty ? '' : profile.name.split(' ').first;
    final String status = profile.isIndependent
        ? AppStrings.teacherStatusIndependent
        : '${AppStrings.teacherStatusAffiliatedPrefix}${profile.affiliation}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${AppStrings.teacherHomeGreetingPrefix}$firstName'
                '${AppStrings.teacherHomeGreetingSuffix}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.school_outlined,
                    size: 16,
                    color: AppColors.teacherAccent,
                  ),
                  const SizedBox(width: AppSpacing.sp4),
                  Flexible(
                    child: Text(
                      status,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.teacherAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sp8),
        _BellButton(onTap: onBell),
      ],
    );
  }
}

/// Notification bell with a small unread dot.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        IconButton(
          onPressed: onTap,
          icon: Icon(
            Icons.notifications_none_rounded,
            color: palette.textSecondary,
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              border: Border.all(color: palette.surface, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// The four headline metrics in a 2x2 grid of embossed neo tiles, read live
/// from the teacher profile.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    final List<_StatTile> tiles = <_StatTile>[
      _StatTile(
        icon: Icons.visibility_outlined,
        accent: AppColors.teacherAccent,
        value: '${profile.profileViews}',
        label: AppStrings.teacherStatViews,
      ),
      _StatTile(
        icon: Icons.people_alt_outlined,
        accent: AppColors.teacherAccent,
        value: '${profile.studentsTaught}',
        label: AppStrings.teacherStatStudents,
      ),
      _StatTile(
        icon: Icons.star_rounded,
        accent: AppColors.ratingStar,
        value: profile.rating.toStringAsFixed(1),
        label: AppStrings.teacherStatRating,
      ),
      _StatTile(
        icon: Icons.bolt_outlined,
        accent: AppColors.teacherAccent,
        value: '${profile.responseRatePercent}%',
        label: AppStrings.teacherStatResponse,
      ),
    ];
    return Column(
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: tiles[0]),
              const SizedBox(width: AppSpacing.sp16),
              Expanded(child: tiles[1]),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sp16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: tiles[2]),
              const SizedBox(width: AppSpacing.sp16),
              Expanded(child: tiles[3]),
            ],
          ),
        ),
      ],
    );
  }
}

/// One headline metric: a tinted icon, the big value, and its label.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color accent;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return NeoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sp12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(height: AppSpacing.sp12),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

/// The day's sessions as embossed neo rows, or an empty-state row.
class _SessionsList extends StatelessWidget {
  const _SessionsList({required this.sessions});

  final List<TeacherSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _EmptyRow(
        icon: Icons.event_available_outlined,
        message: AppStrings.teacherHomeNoSessions,
      );
    }
    return Column(
      children: <Widget>[
        for (int i = 0; i < sessions.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sp12),
          _SessionRow(session: sessions[i]),
        ],
      ],
    );
  }
}

/// One session row: a mode icon, subject + group, and the start time.
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final TeacherSession session;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final IconData modeIcon = session.mode == SessionMode.online
        ? Icons.videocam_outlined
        : Icons.place_outlined;
    return NeoSurface(
      padding: const EdgeInsets.all(AppSpacing.sp12),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.teacherAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sp12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_outlined,
              size: 20,
              color: AppColors.teacherAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  session.subject,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Icon(modeIcon, size: 14, color: palette.textMuted),
                    const SizedBox(width: AppSpacing.sp4),
                    Flexible(
                      child: Text(
                        session.group,
                        overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: AppSpacing.sp8),
          Text(
            session.time,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.teacherAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// The recent-enquiries preview as embossed neo rows, or an empty-state row.
class _EnquiriesList extends StatelessWidget {
  const _EnquiriesList({required this.enquiries, required this.onTap});

  final List<TeacherEnquiry> enquiries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (enquiries.isEmpty) {
      return const _EmptyRow(
        icon: Icons.mark_email_unread_outlined,
        message: AppStrings.teacherHomeNoEnquiries,
      );
    }
    return Column(
      children: <Widget>[
        for (int i = 0; i < enquiries.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sp12),
          _EnquiryRow(enquiry: enquiries[i], onTap: onTap),
        ],
      ],
    );
  }
}

/// One enquiry row: student avatar, name + wanted subject, and how long ago.
class _EnquiryRow extends StatelessWidget {
  const _EnquiryRow({required this.enquiry, required this.onTap});

  final TeacherEnquiry enquiry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return NeoSurface(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.sp16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sp12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: enquiry.avatarColor,
                    borderRadius: BorderRadius.circular(AppSpacing.sp12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    enquiry.initial,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.neutralWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        enquiry.studentName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppStrings.teacherHomeEnquiryWantsPrefix}'
                        '${enquiry.subject}',
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sp8),
                Text(
                  enquiry.timeAgo,
                  style: textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
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

/// Compact empty-state row used by the sessions / enquiries lists.
class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return NeoSurface(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: palette.iconFaint),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The two profile quick actions: a filled Edit Profile CTA and an outlined
/// Share Profile button.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onEditProfile,
    required this.onShareProfile,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: <Widget>[
        Expanded(
          child: NeoButton(
            onPressed: onEditProfile,
            filled: true,
            accent: AppColors.teacherAccent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.neutralWhite,
                ),
                SizedBox(width: AppSpacing.sp8),
                Text(AppStrings.teacherHomeEditProfile),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sp16),
        Expanded(
          child: NeoButton(
            onPressed: onShareProfile,
            filled: false,
            accent: palette.textPrimary,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                Icon(Icons.ios_share_outlined, size: 18),
                SizedBox(width: AppSpacing.sp8),
                Text(AppStrings.teacherHomeShareProfile),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
