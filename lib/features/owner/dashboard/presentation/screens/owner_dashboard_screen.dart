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
import '../../../profile/data/mock_owner_profile_data.dart';
import '../../data/mock_dashboard_data.dart';
import '../widgets/quick_action_widget.dart';
import '../widgets/stat_card_widget.dart';
import '../widgets/views_chart_widget.dart';

/// Owner dashboard screen.
///
/// Phase 1: every figure is rendered from `mock_dashboard_data.dart` (with the
/// owner's identity reused from `mock_owner_profile_data.dart`). When the
/// backend lands the fixture imports are swapped for a controller-backed
/// `AsyncValue<DashboardData>` and the layout stays unchanged. The Edit Center
/// and View Enquiries quick actions navigate within the owner shell; Manage
/// Courses, Share Link, and the notifications bell are placeholders ("Coming
/// soon" snackbar). The recent-enquiries preview links into the Enquiries tab.
class OwnerDashboardScreen extends HookConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;

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
                        child: _Header(onBell: stub),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      const _StatGrid(stats: mockDashboardStats),
                      const SizedBox(height: AppSpacing.sp24),
                      const ViewsChartWidget(data: mockWeeklyViews),
                      const SizedBox(height: AppSpacing.sp24),
                      const _SectionHeader(
                        title: AppStrings.dashboardQuickActions,
                      ),
                      const SizedBox(height: AppSpacing.sp12),
                      _QuickActions(
                        onEditCenter: openEditCenter,
                        onManageCourses: stub,
                        onViewEnquiries: openEnquiries,
                        onShareLink: stub,
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      _SectionHeader(
                        title: AppStrings.dashboardRecentEnquiries,
                        trailing: GestureDetector(
                          onTap: openEnquiries,
                          child: Text(
                            AppStrings.dashboardViewAll,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.ownerAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp12),
                      _RecentEnquiries(
                        items: mockRecentEnquiries,
                        onTap: openEnquiry,
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

/// Greeting block: owner name + business name on the left, a notifications
/// bell (with an unread dot) on the right.
class _Header extends StatelessWidget {
  const _Header({required this.onBell});

  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${AppStrings.dashboardGreetingPrefix}$mockOwnerFirstName'
                '${AppStrings.dashboardGreetingSuffix}',
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
                      mockOwnerBusinessName,
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
