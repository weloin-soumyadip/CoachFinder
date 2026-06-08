/// Owner dashboard - greeting, headline stats, a 7-day views chart, quick
/// actions, and a recent-enquiries preview.
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
import '../../../../auth/data/providers/auth_providers.dart';
import '../../../manage_center/data/controllers/my_center_provider.dart';
import '../../../profile/data/mock_owner_profile_data.dart';
import '../../data/controllers/dashboard_provider.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/mock_dashboard_data.dart';
import '../widgets/quick_action_widget.dart';
import '../widgets/stat_card_widget.dart';
import '../widgets/views_chart_widget.dart';

/// Owner dashboard screen.
///
/// The headline stats, 7-day views chart, and recent-enquiries preview are
/// wired to `GET /api/owners/dashboard` via [ownerDashboardControllerProvider]
/// (spinner while loading, inline retry on error). The owner's identity in the
/// header and the static stat-delta captions / enquiry avatar colours are NOT
/// part of that endpoint, so they stay fixture-backed (see `_statsFrom` /
/// `_enquiriesFrom`). The Edit Center and View Enquiries quick actions navigate
/// within the owner shell; Manage Courses, Share Link, and the notifications
/// bell are placeholders ("Coming soon" snackbar). The recent-enquiries preview
/// links into the Enquiries tab.
class OwnerDashboardScreen extends HookConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final OwnerDashboardState state =
        ref.watch(ownerDashboardControllerProvider);
    // The greeting name comes from the authenticated owner (not a fixture).
    final String ownerFirstName =
        _firstNameOf(ref.watch(authControllerProvider).user?.name);
    // The centre name (header subtitle) comes from GET /api/centers/me; while
    // it loads (or on failure) we fall back to the fixture business name.
    final String? centerName = ref.watch(myCenterProvider).valueOrNull?.name;
    final String businessName = (centerName == null || centerName.isEmpty)
        ? mockOwnerBusinessName
        : centerName;

    void stub() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.stubComingSoon)),
        );
    }

    void openEnquiries() => context.goNamed(AppRoutes.ownerEnquiryInbox);
    void openEditCenter() => context.goNamed(AppRoutes.ownerManageCenter);

    // Push (not go) so the detail's back button returns here within the shell.
    void openEnquiry(String id) => context.pushNamed(
          AppRoutes.ownerEnquiryDetail,
          pathParameters: <String, String>{'id': id},
        );

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[AppColors.ownerAccent],
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
                        child: _Header(
                          firstName: ownerFirstName,
                          businessName: businessName,
                          onBell: stub,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      _DashboardBody(
                        state: state,
                        onRetry: () => ref
                            .read(ownerDashboardControllerProvider.notifier)
                            .load(),
                        onEditCenter: openEditCenter,
                        onManageCourses: stub,
                        onViewEnquiries: openEnquiries,
                        onShareLink: stub,
                        onEnquiry: openEnquiry,
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

/// The data-driven region below the header: a spinner while the first load is
/// in flight, an inline retry on failure, otherwise the stats / chart / quick
/// actions / recent-enquiries built from the live [OwnerDashboardData].
class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.onRetry,
    required this.onEditCenter,
    required this.onManageCourses,
    required this.onViewEnquiries,
    required this.onShareLink,
    required this.onEnquiry,
  });

  final OwnerDashboardState state;
  final VoidCallback onRetry;
  final VoidCallback onEditCenter;
  final VoidCallback onManageCourses;
  final VoidCallback onViewEnquiries;
  final VoidCallback onShareLink;
  final ValueChanged<String> onEnquiry;

  @override
  Widget build(BuildContext context) {
    final OwnerDashboardData? data = state.data;

    if (data == null && state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sp48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // A no-center owner is held on the setup gate (`OwnerSetupScreen`) and never
    // reaches the dashboard, so `noCenter` falls through to the error card here
    // as a defensive fallback only.
    if (data == null) {
      return _DashboardError(
        message: state.errorMessage ?? AppStrings.dashboardLoadError,
        onRetry: onRetry,
      );
    }

    final List<DashboardStat> stats = _statsFrom(data);
    final List<DailyViews> views = _viewsFrom(data.profileViewStats);
    final List<EnquiryPreview> enquiries = _enquiriesFrom(data.recentEnquiries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _StatGrid(stats: stats),
        const SizedBox(height: AppSpacing.sp24),
        ViewsChartWidget(data: views),
        const SizedBox(height: AppSpacing.sp24),
        const _SectionHeader(title: AppStrings.dashboardQuickActions),
        const SizedBox(height: AppSpacing.sp12),
        _QuickActions(
          onEditCenter: onEditCenter,
          onManageCourses: onManageCourses,
          onViewEnquiries: onViewEnquiries,
          onShareLink: onShareLink,
        ),
        const SizedBox(height: AppSpacing.sp24),
        _SectionHeader(
          title: AppStrings.dashboardRecentEnquiries,
          trailing: GestureDetector(
            onTap: onViewEnquiries,
            child: Text(
              AppStrings.dashboardViewAll,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.ownerAccent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sp12),
        if (enquiries.isEmpty)
          const _NoEnquiries()
        else
          _RecentEnquiries(items: enquiries, onTap: onEnquiry),
      ],
    );
  }
}

// ===== API → view-model mappers (static fields preserved) =====

/// Static avatar fills cycled per recent-enquiry, since the dashboard endpoint
/// carries no avatar colour (kept as fixture content colours, not removed).
const List<Color> _enquiryAvatarColors = <Color>[
  Color(0xFF5B7CA0),
  Color(0xFFC97373),
  Color(0xFF7C9F7C),
  Color(0xFFB08968),
  Color(0xFF8E7CC3),
];

/// Maps the live metrics into the four [DashboardStat] cards. The icons +
/// accents stay fixed; the delta captions/trends are intentionally left blank
/// for views/enquiries/students (the endpoint has no period-over-period figure,
/// so showing the old static "+12%" beside a real number would mislead). Only
/// the rating caption is real — the backend's `totalReviews`.
List<DashboardStat> _statsFrom(OwnerDashboardData d) {
  return <DashboardStat>[
    DashboardStat(
      label: AppStrings.dashboardStatProfileViews,
      value: _formatCount(d.weeklyProfileViews),
      icon: Icons.visibility_outlined,
      accent: AppColors.ownerAccent,
    ),
    DashboardStat(
      label: AppStrings.dashboardStatNewEnquiries,
      value: _formatCount(d.weeklyEnquiries),
      icon: Icons.mark_email_unread_outlined,
      accent: AppColors.info,
    ),
    DashboardStat(
      label: AppStrings.dashboardStatRating,
      value: d.averageRating.toStringAsFixed(1),
      icon: Icons.star_outline,
      accent: AppColors.ratingStar,
      caption: '${d.totalReviews}${AppStrings.dashboardReviewsSuffix}',
    ),
    DashboardStat(
      label: AppStrings.dashboardStatActiveStudents,
      value: _formatCount(d.activeStudents),
      icon: Icons.people_outline,
      accent: AppColors.success,
    ),
  ];
}

/// Maps the 7-day `profileViewStats` into [DailyViews], labelling each bar with
/// the weekday abbreviation derived from its date.
List<DailyViews> _viewsFrom(List<ProfileViewPoint> points) {
  return <DailyViews>[
    for (final ProfileViewPoint p in points)
      DailyViews(label: _weekdayShort(p.date), views: p.views),
  ];
}

/// Maps the live `recentEnquiries` into [EnquiryPreview]s. The avatar colour is
/// a static fixture colour (not in the payload); `isNew` defaults to false (the
/// endpoint carries no read/unread flag — field kept, not removed).
List<EnquiryPreview> _enquiriesFrom(List<RecentEnquiry> items) {
  final List<EnquiryPreview> result = <EnquiryPreview>[];
  for (int i = 0; i < items.length; i++) {
    final RecentEnquiry e = items[i];
    final String name = e.studentName.trim();
    result.add(
      EnquiryPreview(
        id: e.enquiryId,
        studentName: name.isEmpty ? '—' : name,
        message: e.message,
        timeAgo: _timeAgo(e.createdAt),
        initial: name.isEmpty ? '?' : name[0].toUpperCase(),
        avatarColor: _enquiryAvatarColors[i % _enquiryAvatarColors.length],
      ),
    );
  }
  return result;
}

/// Groups a non-negative integer with comma thousands separators (no `intl`
/// dependency), e.g. `1248` → `'1,248'`.
String _formatCount(int n) {
  final String digits = n.abs().toString();
  final StringBuffer out = StringBuffer(n < 0 ? '-' : '');
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

const List<String> _weekdayAbbr = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Short weekday label for a (possibly null) date; empty string when absent.
String _weekdayShort(DateTime? date) =>
    date == null ? '' : _weekdayAbbr[(date.weekday - 1) % 7];

/// A compact relative-time label derived from [createdAt].
String _timeAgo(DateTime? createdAt) {
  if (createdAt == null) return '';
  final Duration diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return AppStrings.timeJustNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inHours < 48) return AppStrings.timeYesterday;
  return '${diff.inDays}d ago';
}

/// The first whitespace-delimited token of [fullName], or an empty string when
/// [fullName] is null/blank. Used to greet the owner by first name.
String _firstNameOf(String? fullName) {
  final String name = fullName?.trim() ?? '';
  if (name.isEmpty) return '';
  return name.split(RegExp(r'\s+')).first;
}

/// Greeting block: owner name + business name on the left, a notifications
/// bell (with an unread dot) on the right.
class _Header extends StatelessWidget {
  const _Header({
    required this.firstName,
    required this.businessName,
    required this.onBell,
  });

  /// The authenticated owner's first name; empty when unavailable.
  final String firstName;

  /// The coaching centre name shown as the subtitle.
  final String businessName;

  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final String greeting = firstName.isEmpty
        ? AppStrings.dashboardGreetingNoName
        : '${AppStrings.dashboardGreetingPrefix}$firstName'
            '${AppStrings.dashboardGreetingSuffix}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.business_outlined,
                    size: 16,
                    color: AppColors.ownerAccent,
                  ),
                  const SizedBox(width: AppSpacing.sp4),
                  Flexible(
                    child: Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.ownerAccent,
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

/// Notification bell with a small unread dot, ringed by the surface so the dot
/// reads as a cutout in both themes.
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
            Icons.notifications_outlined,
            color: palette.textSecondary,
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.ownerAccent,
              shape: BoxShape.circle,
              border: Border.all(color: palette.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// 2x2 grid of [StatCardWidget]s. Paired rows are height-matched so cards in a
/// row stay flush regardless of caption length.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<DashboardStat> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < stats.length; i += 2) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sp12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: StatCardWidget(stat: stats[i])),
                const SizedBox(width: AppSpacing.sp12),
                if (i + 1 < stats.length)
                  Expanded(child: StatCardWidget(stat: stats[i + 1]))
                else
                  const Spacer(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 2x2 grid of the four quick actions.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onEditCenter,
    required this.onManageCourses,
    required this.onViewEnquiries,
    required this.onShareLink,
  });

  final VoidCallback onEditCenter;
  final VoidCallback onManageCourses;
  final VoidCallback onViewEnquiries;
  final VoidCallback onShareLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: QuickActionWidget(
                  label: AppStrings.dashboardActionEditCenter,
                  icon: Icons.edit_outlined,
                  onTap: onEditCenter,
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: QuickActionWidget(
                  label: AppStrings.dashboardActionManageCourses,
                  icon: Icons.menu_book_outlined,
                  onTap: onManageCourses,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sp12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: QuickActionWidget(
                  label: AppStrings.dashboardActionViewEnquiries,
                  icon: Icons.inbox_outlined,
                  onTap: onViewEnquiries,
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: QuickActionWidget(
                  label: AppStrings.dashboardActionShareLink,
                  icon: Icons.ios_share_outlined,
                  onTap: onShareLink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vertical list of recent-enquiry preview cards.
class _RecentEnquiries extends StatelessWidget {
  const _RecentEnquiries({required this.items, required this.onTap});

  final List<EnquiryPreview> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sp12),
          _EnquiryCard(enquiry: items[i], onTap: () => onTap(items[i].id)),
        ],
      ],
    );
  }
}

/// A single recent-enquiry row: avatar, name + time, snippet, and a NEW badge
/// when unread.
class _EnquiryCard extends StatelessWidget {
  const _EnquiryCard({required this.enquiry, required this.onTap});

  final EnquiryPreview enquiry;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
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
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
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
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              enquiry.message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                          if (enquiry.isNew) ...<Widget>[
                            const SizedBox(width: AppSpacing.sp8),
                            const _NewBadge(),
                          ],
                        ],
                      ),
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

/// Small "NEW" pill marking an unread enquiry.
class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sp8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ownerAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Text(
        AppStrings.dashboardEnquiryNew,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.ownerAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

/// Inline load-failure state with a retry button, shown in place of the data
/// sections when the dashboard fetch fails before any data is cached.
class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp48),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_off, size: 48, color: palette.iconFaint),
          const SizedBox(height: AppSpacing.sp12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpacing.sp16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ownerAccent,
              foregroundColor: AppColors.neutralWhite,
            ),
            child: const Text(AppStrings.dashboardRetry),
          ),
        ],
      ),
    );
  }
}

/// Empty state for the recent-enquiries preview when the owner has none yet.
class _NoEnquiries extends StatelessWidget {
  const _NoEnquiries();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return NeoSurface(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      child: Row(
        children: <Widget>[
          Icon(Icons.inbox_outlined, size: 20, color: palette.iconFaint),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Text(
              AppStrings.dashboardNoEnquiries,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: palette.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bold section title with an optional trailing action (e.g. "View all").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.palette.textPrimary,
              ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}
