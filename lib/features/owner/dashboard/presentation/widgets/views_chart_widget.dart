/// Hand-drawn 7-day profile-views mini bar chart (no charting package).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_dashboard_data.dart';

/// A surface card charting daily profile views for the week. The bars are
/// painted by [_BarsPainter] (a `CustomPainter`, so no chart dependency is
/// added); the tallest day is highlighted in the owner accent and annotated
/// with its value. Day labels sit in a matching column grid beneath the bars.
class ViewsChartWidget extends StatelessWidget {
  const ViewsChartWidget({super.key, required this.data});

  final List<DailyViews> data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    final List<int> values = <int>[for (final d in data) d.views];
    final int peakIndex = _peakIndex(values);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.dashboardViewsChartTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      AppStrings.dashboardViewsChartSubtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp16),
          SizedBox(
            height: 132,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarsPainter(
                values: values,
                peakIndex: peakIndex,
                barColor: AppColors.ownerAccent,
                fadedColor: AppColors.ownerAccent.withValues(alpha: 0.28),
                labelColor: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          Row(
            children: <Widget>[
              for (final d in data)
                Expanded(
                  child: Center(
                    child: Text(
                      d.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Index of the highest day; 0 when the list is empty.
  static int _peakIndex(List<int> values) {
    if (values.isEmpty) return 0;
    int peak = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[peak]) peak = i;
    }
    return peak;
  }
}

/// Paints evenly-spaced rounded bars scaled to the largest value, with the peak
/// bar drawn in [barColor] (others [fadedColor]) and its value labelled above.
class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.peakIndex,
    required this.barColor,
    required this.fadedColor,
    required this.labelColor,
  });

  final List<int> values;
  final int peakIndex;
  final Color barColor;
  final Color fadedColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final double maxValue =
        values.reduce(math.max).toDouble().clamp(1, double.infinity);
    final int n = values.length;
    final double slot = size.width / n;
    final double barWidth = slot * 0.46;
    // Reserve headroom above the tallest bar for its value label.
    const double topPadding = 22;
    final double usableHeight = size.height - topPadding;

    for (int i = 0; i < n; i++) {
      final double barHeight = (values[i] / maxValue) * usableHeight;
      final double centerX = slot * i + slot / 2;
      final Rect rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        size.height - barHeight,
        barWidth,
        barHeight,
      );
      final Paint paint = Paint()
        ..color = i == peakIndex ? barColor : fadedColor;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        paint,
      );
    }

    // Annotate the peak bar with its value.
    final double peakHeight = (values[peakIndex] / maxValue) * usableHeight;
    final double peakCenterX = slot * peakIndex + slot / 2;
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: values[peakIndex].toString(),
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        peakCenterX - tp.width / 2,
        size.height - peakHeight - tp.height - 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.values != values ||
      old.peakIndex != peakIndex ||
      old.barColor != barColor ||
      old.fadedColor != fadedColor ||
      old.labelColor != labelColor;
}
