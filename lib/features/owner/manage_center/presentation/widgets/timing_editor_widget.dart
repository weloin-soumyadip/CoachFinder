/// Weekly class-timing editor: per-day open/closed toggle + open/close times.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_center_data.dart';

/// One row per day inside a surface card. Each row has a day label, the open
/// and close time chips (tappable, firing [onPickTime] so the host can show a
/// time picker), and a switch that toggles the day open/closed via
/// [onToggleDay]. Closed days hide the time chips.
class TimingEditorWidget extends StatelessWidget {
  const TimingEditorWidget({
    super.key,
    required this.timings,
    required this.onToggleDay,
    required this.onPickTime,
  });

  final List<DayTiming> timings;

  /// Fired with the day index when its open/closed switch is toggled.
  final ValueChanged<int> onToggleDay;

  /// Fired with the day index and whether the opening time (true) or closing
  /// time (false) was tapped.
  final void Function(int index, bool openField) onPickTime;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < timings.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: palette.borderSubtle),
            _DayRow(
              timing: timings[i],
              onToggle: () => onToggleDay(i),
              onPickOpen: () => onPickTime(i, true),
              onPickClose: () => onPickTime(i, false),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.timing,
    required this.onToggle,
    required this.onPickOpen,
    required this.onPickClose,
  });

  final DayTiming timing;
  final VoidCallback onToggle;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16,
        vertical: AppSpacing.sp8,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: Text(
              timing.day,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sp8),
          Expanded(
            child: timing.isOpen
                ? Row(
                    children: <Widget>[
                      _TimeChip(
                        time: formatTimeOfDay(timing.openAt),
                        onTap: onPickOpen,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp8,
                        ),
                        child: Text(
                          AppStrings.centerTimingTo,
                          style: textTheme.bodySmall
                              ?.copyWith(color: palette.textMuted),
                        ),
                      ),
                      _TimeChip(
                        time: formatTimeOfDay(timing.closeAt),
                        onTap: onPickClose,
                      ),
                    ],
                  )
                : Text(
                    AppStrings.centerTimingClosed,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: palette.textMuted),
                  ),
          ),
          Switch(
            value: timing.isOpen,
            activeThumbColor: AppColors.ownerAccent,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}

/// A tappable time pill that opens a time picker in the host.
class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, required this.onTap});

  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.inputFill,
      borderRadius: BorderRadius.circular(AppSpacing.sp8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp12,
            vertical: AppSpacing.sp4,
          ),
          child: Text(
            time,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
