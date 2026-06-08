/// Student home screen — the student dashboard feed (top teachers, top centers,
/// upcoming webinars) backed by `GET /api/students/dashboard`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../features/auth/data/providers/auth_providers.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../../../shared/widgets/entrance_fade_slide.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../../../shared/widgets/neo_button.dart';
import '../../data/controllers/home_provider.dart';
import '../../data/mock_home_data.dart';
import '../../data/models/student_dashboard_model.dart';
import '../widgets/category_chip_widget.dart';
import '../widgets/center_card_widget.dart';
import '../widgets/teacher_card_widget.dart';
import '../widgets/webinar_card_widget.dart';

/// Student home screen.
///
/// Content is served by [homeControllerProvider] (`GET /api/students/dashboard`)
/// as a loading → data / error [HomeState]; pull-to-refresh and the error-retry
/// button both call `refresh()`. The top bar and greeting fade + slide in on
/// first build; the greeting name comes from the signed-in [authControllerProvider]
/// user. Content is capped + centered for wide windows.
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entrance = useAnimationController(
      duration: const Duration(milliseconds: 900),
    );
    useEffect(() {
      entrance.forward();
      return null;
    }, const <Object?>[]);

    final palette = context.palette;
    final state = ref.watch(homeControllerProvider);
    final String? fullName = ref.watch(
      authControllerProvider.select((s) => s.user?.name),
    );

    return Scaffold(
      body: DecoratedBox(
        // Subtle vertical brand-tint wash that fades into the flat background
        // within the first ~40% of the viewport. Fixed backdrop behind the feed.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[palette.primaryTint, palette.background],
            stops: const <double>[0.0, 0.4],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: RefreshIndicator(
                    onRefresh: () =>
                        ref.read(homeControllerProvider.notifier).refresh(),
                    color: AppColors.studentPrimary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: floatingNavClearance(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          EntranceFadeSlide(
                            animation: entrance,
                            start: 0.0,
                            end: 0.5,
                            child: const _TopBar(),
                          ),
                          const SizedBox(height: AppSpacing.sp16),
                          EntranceFadeSlide(
                            animation: entrance,
                            start: 0.06,
                            end: 0.56,
                            child: _Greeting(fullName: fullName),
                          ),
                          const SizedBox(height: AppSpacing.sp16),
                          // Mock: featured Next Session CTA card (static fixture).
                          EntranceFadeSlide(
                            animation: entrance,
                            start: 0.14,
                            end: 0.64,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sp16,
                              ),
                              child: _NextSessionCard(session: mockNextSession),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sp24),
                          // Mock: Trending Topics browse rail (static fixture).
                          EntranceFadeSlide(
                            animation: entrance,
                            start: 0.24,
                            end: 0.74,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const _SectionHeader(
                                  title: AppStrings.homeTrendingTopics,
                                  trailing: _SeeAll(),
                                ),
                                const SizedBox(height: AppSpacing.sp12),
                                _TopicsRail(topics: mockTopics),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sp24),
                          // Real: dashboard sections (Recommended For You, Top
                          // Centers, Upcoming Webinars) or loading / error.
                          _DashboardBody(state: state),
                          const SizedBox(height: AppSpacing.sp24),
                          // Mock: Personalized Path card + action tiles.
                          EntranceFadeSlide(
                            animation: entrance,
                            start: 0.44,
                            end: 0.94,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const <Widget>[
                                _SectionHeader(
                                  title: AppStrings.homePersonalizedPath,
                                ),
                                SizedBox(height: AppSpacing.sp12),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sp16,
                                  ),
                                  child: _PersonalizedPathCard(path: mockPath),
                                ),
                                SizedBox(height: AppSpacing.sp12),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sp16,
                                  ),
                                  child: _ActionTilesRow(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.sp16,
                bottom: floatingNavClearance(context),
                child: EntranceFadeSlide(
                  animation: entrance,
                  start: 0.6,
                  end: 1.0,
                  child: const _ChatFab(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Switches the feed area between loading, error, empty, and data states.
class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A failed first load (no prior data) gets the full error+retry view.
    // Refreshes keep the prior dashboard on screen (the RefreshIndicator shows
    // its own spinner), so a refresh error doesn't replace the feed.
    if (state.status == HomeStatus.error && !state.hasData) {
      return _ErrorState(
        message: state.errorMessage ?? AppStrings.errorUnknown,
        onRetry: () => ref.read(homeControllerProvider.notifier).refresh(),
      );
    }
    final StudentDashboard? dashboard = state.dashboard;
    // No payload yet (initial / first load in flight) → big spinner.
    if (dashboard == null) {
      return const _CenteredState(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sp48),
          child: CircularProgressIndicator(
            color: AppColors.studentPrimary,
          ),
        ),
      );
    }
    // Once we have a payload, ALWAYS render all three sections; an empty
    // section shows its own "no data found" placeholder rather than vanishing.
    return _DashboardSections(dashboard: dashboard);
  }
}

/// The three populated dashboard sections, each rendered only when non-empty.
class _DashboardSections extends StatelessWidget {
  const _DashboardSections({required this.dashboard});

  final StudentDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    // Every section is always present; an empty list renders a "no data found"
    // placeholder inside the section instead of removing it. Recommended For
    // You sits in its original static slot (right after Trending Topics), then
    // the other two real sections follow.
    final List<Widget> sections = <Widget>[
      _Section(
        title: AppStrings.homeRecommendedForYou,
        children: <Widget>[
          for (final teacher in dashboard.topTeachers)
            TeacherCardWidget(
              teacher: teacher,
              onTap: () => context.pushNamed(
                AppRoutes.studentTeacherDetail,
                pathParameters: <String, String>{'id': teacher.id},
                extra: teacher.subjects,
              ),
            ),
        ],
      ),
      _Section(
        title: AppStrings.homeTopCenters,
        children: <Widget>[
          for (final center in dashboard.topCenters)
            CenterCardWidget(
              center: center,
              onTap: () => context.pushNamed(
                AppRoutes.studentCenterDetail,
                pathParameters: <String, String>{'id': center.id},
              ),
            ),
        ],
      ),
      _Section(
        title: AppStrings.homeUpcomingWebinars,
        children: <Widget>[
          for (final webinar in dashboard.upcomingWebinars)
            WebinarCardWidget(
              webinar: webinar,
              onJoin: () => _showComingSoon(context),
            ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < sections.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sp24),
          sections[i],
        ],
      ],
    );
  }
}

/// A titled section: bold header + vertically stacked cards.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeader(title: title),
        const SizedBox(height: AppSpacing.sp12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
          child: children.isEmpty
              ? const _NoData()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = 0; i < children.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: AppSpacing.sp12),
                      children[i],
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Per-section "no data found" placeholder: a flat surface tile with a muted
/// icon + label, so an empty section still occupies its slot in the feed.
class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.inbox_outlined, size: 28, color: palette.iconFaint),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            AppStrings.homeNoData,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Centered single-child layout used by the loading / empty states so they sit
/// mid-feed while remaining inside the scroll view (keeps pull-to-refresh live).
class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(child: child);
  }
}

/// Inline error with the backend's message and a Retry button.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp32,
        vertical: AppSpacing.sp48,
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_off_outlined, size: 40, color: palette.iconFaint),
          const SizedBox(height: AppSpacing.sp16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sp24),
          NeoButton(
            onPressed: onRetry,
            filled: true,
            accent: AppColors.studentPrimary,
            child: Text(
              AppStrings.homeRetry,
              style: textTheme.titleSmall?.copyWith(
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

/// Shows the standard "coming soon" snackbar for not-yet-wired tap targets.
void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text(AppStrings.stubComingSoon)),
    );
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: AppSpacing.sp8,
      ),
      child: Row(
        children: <Widget>[
          Text(
            AppStrings.appName,
            style: textTheme.titleLarge?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.fullName});

  /// Signed-in user's full name; the greeting uses just the first token.
  final String? fullName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final String first = (fullName ?? '').trim().split(' ').first;
    final String greeting = first.isEmpty
        ? 'Hello${AppStrings.homeGreetingSuffix}'
        : '${AppStrings.homeGreetingPrefix}$first${AppStrings.homeGreetingSuffix}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            greeting,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.homeSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ChatFab extends StatelessWidget {
  const _ChatFab();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.studentPrimary,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _showComingSoon(context),
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            Icons.chat_bubble_outline,
            color: AppColors.neutralWhite,
          ),
        ),
      ),
    );
  }
}

/// Bold section title with an optional trailing widget (e.g. a "See all"
/// affordance). Shared by both the real dashboard sections and the mock ones.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.palette.textPrimary,
                ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// "See all" trailing action (stubbed until a topics index screen exists).
class _SeeAll extends StatelessWidget {
  const _SeeAll();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showComingSoon(context),
      child: Text(
        AppStrings.homeSeeAll,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.palette.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Mock featured "Next Session" CTA card (static fixture; no backend yet).
class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({required this.session});

  final NextSession session;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: AppSpacing.sp16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.studentPrimary.withValues(alpha: 0.10),
              AppColors.studentPrimaryDark.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sp16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    AppStrings.homeNextSessionLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: palette.primary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.studentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.sp8),
                    ),
                    child: Text(
                      session.displayTime,
                      style: textTheme.labelSmall?.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp12),
              Text(
                session.title,
                style: textTheme.headlineSmall?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sp8),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.calendar_today_outlined,
                    color: palette.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sp8),
                  Text(
                    'With ${session.coachName} · ${session.durationMinutes} mins',
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp16),
              NeoButton(
                onPressed: () => _showComingSoon(context),
                filled: true,
                accent: AppColors.studentPrimary,
                height: 44,
                child: Text(
                  AppStrings.homeJoinSessionRoom,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutralWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive Trending Topics rail (static fixtures).
///
/// When the chips fit the available width they expand to fill the row evenly
/// (no scroll); on narrower screens the rail falls back to a horizontally
/// scrolling list of fixed-width chips.
class _TopicsRail extends StatelessWidget {
  const _TopicsRail({required this.topics});

  final List<TrendingTopic> topics;

  /// Minimum chip width below which the rail switches to horizontal scrolling.
  static const double _minChipWidth = 120;
  static const double _gap = AppSpacing.sp12;
  // Tall enough for icon + two-line label + padding so chips never overflow.
  static const double _railHeight = 108;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int n = topics.length;
        // Width left for chips after the rail's side padding.
        final double available = constraints.maxWidth - AppSpacing.sp16 * 2;
        final double needed = n * _minChipWidth + (n - 1) * _gap;
        final bool fits = n > 0 && needed <= available;

        if (fits) {
          // Wide enough: spread the chips evenly across the full row.
          return SizedBox(
            height: _railHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < n; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: CategoryChipWidget(
                        topic: topics[i],
                        onTap: () => _showComingSoon(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Narrow: horizontally-scrolling rail of fixed-width chips.
        return SizedBox(
          height: _railHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
            itemCount: n,
            separatorBuilder: (_, __) => const SizedBox(width: _gap),
            itemBuilder: (BuildContext context, int i) => CategoryChipWidget(
              topic: topics[i],
              width: _minChipWidth,
              onTap: () => _showComingSoon(context),
            ),
          ),
        );
      },
    );
  }
}

/// Mock "Personalized Path" progress card (static fixture).
class _PersonalizedPathCard extends StatelessWidget {
  const _PersonalizedPathCard({required this.path});

  final PersonalizedPath path;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      radius: AppSpacing.sp16,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.homeCurrentFocus,
                  style: textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  path.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _ProgressRing(percent: path.progressPercent),
        ],
      ),
    );
  }
}

/// Circular progress ring that animates its arc + percentage up from 0.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 56,
      height: 56,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: percent / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, _) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor: palette.borderSubtle,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.priceGreen),
              ),
              Text(
                '${(value * 100).round()}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: palette.textPrimary,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Mock pair of action tiles under the Personalized Path card.
class _ActionTilesRow extends StatelessWidget {
  const _ActionTilesRow();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: <Widget>[
        Expanded(
          child: _ActionTile(
            label: AppStrings.homeTrackProgress,
            icon: Icons.bar_chart_rounded,
            background: palette.borderSubtle,
            iconColor: palette.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sp12),
        Expanded(
          child: _ActionTile(
            label: AppStrings.homeViewInsights,
            icon: Icons.auto_awesome,
            background: palette.primaryTint,
            iconColor: palette.primary,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(icon, color: iconColor, size: 22),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.palette.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
