/// Student home screen - categories and featured centers feed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../../../shared/widgets/entrance_fade_slide.dart';
import '../../data/mock_home_data.dart';
import '../widgets/category_chip_widget.dart';
import '../widgets/featured_card_widget.dart';

/// Student home screen.
///
/// Phase 1: all content is rendered from `mock_home_data.dart`. When the
/// backend lands the fixture imports are swapped for a controller-backed
/// `AsyncValue<HomeFeed>` and the layout stays unchanged. Sections fade and
/// slide in with a staggered entrance on first build (one
/// `useAnimationController` + per-section [Interval]s via [EntranceFadeSlide]),
/// the Personalized-path ring animates from 0, and content is capped + centered
/// for wide windows.
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.only(bottom: floatingNavClearance(context)),
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
                        child: const _Greeting(),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
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
                      EntranceFadeSlide(
                        animation: entrance,
                        start: 0.24,
                        end: 0.74,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _SectionHeader(
                              title: AppStrings.homeTrendingTopics,
                              trailing: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  AppStrings.homeSeeAll,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: palette.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            _TopicsRail(topics: mockTopics),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      EntranceFadeSlide(
                        animation: entrance,
                        start: 0.34,
                        end: 0.84,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _SectionHeader(
                              title: AppStrings.homeRecommendedForYou,
                              trailing: Icon(
                                Icons.tune,
                                color: palette.textSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            _RecommendedList(coaches: mockCoaches),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      EntranceFadeSlide(
                        animation: entrance,
                        start: 0.44,
                        end: 0.94,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const <Widget>[
                            _SectionHeader(
                                title: AppStrings.homePersonalizedPath),
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
    );
  }
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
              fontWeight: FontWeight.w700,
            ),
          ),
          // const Spacer(),
          // Padding(
          //   padding: const EdgeInsets.only(right: AppSpacing.sp8),
          //   child: CircleAvatar(
          //     radius: 18,
          //     backgroundColor: palette.primaryTint,
          //     child: Text(
          //       mockUser.firstName[0],
          //       style: textTheme.labelLarge?.copyWith(
          //         color: palette.primary,
          //         fontWeight: FontWeight.w700,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${AppStrings.homeGreetingPrefix}${mockUser.firstName}${AppStrings.homeGreetingSuffix}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.homeSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({required this.session});

  final NextSession session;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.studentPrimary,
            AppColors.studentPrimaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                AppStrings.homeNextSessionLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.neutralWhite.withValues(alpha: 0.85),
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
                  color: AppColors.neutralWhite.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSpacing.sp8),
                ),
                child: Text(
                  session.displayTime,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.neutralWhite,
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
              color: AppColors.neutralWhite,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          Row(
            children: <Widget>[
              Icon(
                Icons.calendar_today_outlined,
                color: AppColors.neutralWhite.withValues(alpha: 0.85),
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sp8),
              Text(
                'With ${session.coachName} · ${session.durationMinutes} mins',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutralWhite.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.neutralWhite,
                foregroundColor: AppColors.studentPrimary,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sp12),
                ),
              ),
              child: Text(
                AppStrings.homeJoinSessionRoom,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.studentPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                  fontWeight: FontWeight.w700,
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

class _TopicsRail extends StatelessWidget {
  const _TopicsRail({required this.topics});

  final List<TrendingTopic> topics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sp12),
        itemBuilder: (context, i) =>
            CategoryChipWidget(topic: topics[i], onTap: () {}),
      ),
    );
  }
}

class _RecommendedList extends StatelessWidget {
  const _RecommendedList({required this.coaches});

  final List<Coach> coaches;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Column(
        children: <Widget>[
          for (final coach in coaches) ...<Widget>[
            FeaturedCardWidget(coach: coach, onTap: () {}),
            const SizedBox(height: AppSpacing.sp12),
          ],
        ],
      ),
    );
  }
}

class _PersonalizedPathCard extends StatelessWidget {
  const _PersonalizedPathCard({required this.path});

  final PersonalizedPath path;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
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
                    fontWeight: FontWeight.w700,
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

/// Circular progress ring that animates its arc + percentage up from 0 on first
/// build.
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
                      fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                ),
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
        onTap: () {},
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
