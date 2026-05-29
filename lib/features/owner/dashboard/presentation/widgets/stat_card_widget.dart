/// Single dashboard stat tile: tinted icon, value, label, and a trend caption.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_dashboard_data.dart';

/// A bordered surface card showing one headline metric ([DashboardStat]): a
/// tinted accent icon, the big value, its label, and an optional caption whose
/// colour/arrow reflect the [StatTrend].
class StatCardWidget extends StatelessWidget {
  const StatCardWidget({super.key, required this.stat});

  final DashboardStat stat;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stat.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sp12),
            ),
            alignment: Alignment.center,
            child: Icon(stat.icon, size: 22, color: stat.accent),
          ),
          const SizedBox(height: AppSpacing.sp12),
          Text(
            stat.value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: textTheme.labelMedium?.copyWith(color: palette.textMuted),
          ),
          if (stat.caption != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sp8),
            _TrendCaption(caption: stat.caption!, trend: stat.trend),
          ],
        ],
      ),
    );
  }
}

/// Small trend line beneath the label: an up/down arrow (omitted when neutral)
/// plus the caption text, coloured green for up, red for down, muted otherwise.
class _TrendCaption extends StatelessWidget {
  const _TrendCaption({required this.caption, required this.trend});

  final String caption;
  final StatTrend trend;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (trend) {
      StatTrend.up => AppColors.success,
      StatTrend.down => AppColors.error,
      StatTrend.neutral => context.palette.textMuted,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (trend != StatTrend.neutral) ...<Widget>[
          Icon(
            trend == StatTrend.up
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
        ],
        Flexible(
          child: Text(
            caption,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
