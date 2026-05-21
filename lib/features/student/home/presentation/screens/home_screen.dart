/// Student home screen - categories and featured centers feed.
library;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_home_data.dart';
import '../widgets/category_chip_widget.dart';
import '../widgets/featured_card_widget.dart';

/// Student home screen.
///
/// Phase 1: all content is rendered from `mock_home_data.dart`. When the
/// backend lands the fixture imports are swapped for a controller-backed
/// `AsyncValue<HomeFeed>` and the layout stays unchanged.
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.neutralGrey50,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.sp32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _TopBar(),
                  const SizedBox(height: AppSpacing.sp16),
                  const _Greeting(),
                  const SizedBox(height: AppSpacing.sp16),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp16,
                    ),
                    child: _NextSessionCard(session: mockNextSession),
                  ),
                  const SizedBox(height: AppSpacing.sp24),
                  _SectionHeader(
                    title: AppStrings.homeTrendingTopics,
                    trailing: GestureDetector(
                      onTap: () {},
                      child: Text(
                        AppStrings.homeSeeAll,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.studentPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp12),
                  _TopicsRail(topics: mockTopics),
                  const SizedBox(height: AppSpacing.sp24),
                  _SectionHeader(
                    title: AppStrings.homeRecommendedForYou,
                    trailing: const Icon(
                      Icons.tune,
                      color: AppColors.neutralGrey700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp12),
                  _RecommendedList(coaches: mockCoaches),
                  const SizedBox(height: AppSpacing.sp24),
                  _SectionHeader(
                    title: AppStrings.homePersonalizedPath,
                  ),
                  const SizedBox(height: AppSpacing.sp12),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp16,
                    ),
                    child: _PersonalizedPathCard(path: mockPath),
                  ),
                  const SizedBox(height: AppSpacing.sp12),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp16,
                    ),
                    child: _ActionTilesRow(),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: AppSpacing.sp16,
              bottom: AppSpacing.sp16,
              child: _ChatFab(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: AppSpacing.sp8,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.studentPrimary),
            onPressed: () {},
          ),
          Text(
            AppStrings.appName,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.studentPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sp8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.studentPrimaryTint,
              child: Text(
                mockUser.firstName[0],
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.studentPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${AppStrings.homeGreetingPrefix}${mockUser.firstName}${AppStrings.homeGreetingSuffix}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.neutralBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.homeSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.neutralGrey500,
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
        color: AppColors.studentPrimary,
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
              fontWeight: FontWeight.w700,
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
                  color: AppColors.neutralBlack,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: AppColors.neutralWhite,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: AppColors.neutralGrey100),
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
                    color: AppColors.neutralGrey500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  path.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutralBlack,
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

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: 5,
            backgroundColor: AppColors.neutralGrey100,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.priceGreen),
          ),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutralBlack,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionTilesRow extends StatelessWidget {
  const _ActionTilesRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Expanded(
          child: _ActionTile(
            label: AppStrings.homeTrackProgress,
            icon: Icons.bar_chart_rounded,
            background: AppColors.neutralGrey100,
            iconColor: AppColors.neutralGrey700,
          ),
        ),
        SizedBox(width: AppSpacing.sp12),
        Expanded(
          child: _ActionTile(
            label: AppStrings.homeViewInsights,
            icon: Icons.auto_awesome,
            background: AppColors.studentPrimaryTint,
            iconColor: AppColors.studentPrimary,
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
                  color: AppColors.neutralBlack,
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
