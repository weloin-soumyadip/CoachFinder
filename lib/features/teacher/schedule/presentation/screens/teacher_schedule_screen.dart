/// Teacher schedule - a week day-strip and the selected day's teaching
/// sessions, in the teacher neoglass style.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../../../shared/widgets/brand_backdrop.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../../../shared/widgets/neo_surface.dart';
import '../../data/mock_teacher_schedule_data.dart';

/// Teacher schedule screen.
///
/// Phase 1: the week is rendered from `mock_teacher_schedule_data.dart`. A
/// horizontal day-strip selects a day (defaulting to today); the chosen day's
/// sessions are listed below under a frosted summary header. Session taps are
/// placeholders ("Coming soon"). Teal-branded ([AppColors.teacherAccent]); when
/// the backend lands the fixture swaps for a controller-backed `AsyncValue` and
/// the layout stays unchanged.
class TeacherScheduleScreen extends HookConsumerWidget {
  const TeacherScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final int todayIndex = mockScheduleWeek.indexWhere((d) => d.isToday);
    final ValueNotifier<int> selected =
        useState<int>(todayIndex < 0 ? 0 : todayIndex);
    final ScheduleDay day = mockScheduleWeek[selected.value];

    void stub() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.stubComingSoon)),
        );
    }

    final int count = day.sessions.length;
    final String word = count == 1
        ? AppStrings.teacherScheduleSession
        : AppStrings.teacherScheduleSessions;

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
                      Text(
                        AppStrings.teacherScheduleTitle,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      _WeekStrip(
                        days: mockScheduleWeek,
                        selectedIndex: selected.value,
                        onSelected: (int i) => selected.value = i,
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      GlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.sp16),
                        child: _SummaryHeader(
                          label: day.fullLabel,
                          subtitle: '$count $word',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      if (day.sessions.isEmpty)
                        const _EmptyDay()
                      else
                        for (int i = 0;
                            i < day.sessions.length;
                            i++) ...<Widget>[
                          if (i > 0) const SizedBox(height: AppSpacing.sp12),
                          _SessionRow(session: day.sessions[i], onTap: stub),
                        ],
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

/// Horizontally-scrollable week selector of day pills.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ScheduleDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < days.length; i++)
            Padding(
              padding: EdgeInsets.only(
                right: i == days.length - 1 ? 0 : AppSpacing.sp8,
              ),
              child: _DayPill(
                day: days[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single day in the strip: weekday + date number. Filled teal when selected;
/// frosted glass otherwise, with the date tinted teal for today.
class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final ScheduleDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final Color weekdayColor =
        selected ? AppColors.neutralWhite : palette.textMuted;
    final Color dayColor = selected
        ? AppColors.neutralWhite
        : (day.isToday ? AppColors.teacherAccent : palette.textPrimary);

    final Widget inner = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        child: SizedBox(
          width: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  day.weekday,
                  style: textTheme.labelSmall?.copyWith(
                    color: weekdayColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp4),
                Text(
                  day.dayNum,
                  style: textTheme.titleMedium?.copyWith(
                    color: dayColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: day.isToday
                        ? (selected
                            ? AppColors.neutralWhite
                            : AppColors.teacherAccent)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected) {
      return Material(
        color: AppColors.teacherAccent,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        child: inner,
      );
    }
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: AppSpacing.sp16,
      child: inner,
    );
  }
}

/// Frosted summary header: the selected day's full label + session count.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.label, required this.subtitle});

  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.teacherAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.sp12),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.calendar_month_outlined,
            size: 22,
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
                label,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One session as an embossed neo row: a start/end time column, the subject +
/// group, and a delivery-mode icon.
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final ScheduleSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final IconData modeIcon = session.mode == SessionMode.online
        ? Icons.videocam_outlined
        : Icons.place_outlined;
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
                SizedBox(
                  width: 64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        session.startTime,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.teacherAccent,
                        ),
                      ),
                      Text(
                        session.endTime,
                        style: textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: palette.borderSubtle,
                  margin: const EdgeInsets.only(right: AppSpacing.sp12),
                ),
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
                      Text(
                        session.group,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sp8),
                Icon(modeIcon, size: 18, color: AppColors.teacherAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty-state row shown when the selected day has no sessions.
class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return NeoSurface(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.event_available_outlined,
            size: 20,
            color: palette.iconFaint,
          ),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Text(
              AppStrings.teacherScheduleNoSessions,
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
