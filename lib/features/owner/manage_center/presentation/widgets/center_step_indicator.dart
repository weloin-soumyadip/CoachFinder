/// Hand-built horizontal step indicator (the "Smart Stepper / Example" look):
/// numbered circles joined by connector lines, filling the role accent as the
/// owner progresses. No package — drawn with plain widgets per the fixed-stack
/// rule. Used by the create-center wizard.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';

/// A row of numbered step circles connected by lines. [currentStep] is the
/// 0-based index of the active step; earlier circles render as completed
/// (accent fill + check), the active one is accent-filled with its number, and
/// later ones are muted.
class CenterStepIndicator extends StatelessWidget {
  /// Creates the indicator for [stepCount] steps with [currentStep] active.
  const CenterStepIndicator({
    super.key,
    required this.currentStep,
    required this.stepCount,
    this.accent = AppColors.ownerAccent,
  });

  /// 0-based index of the active step.
  final int currentStep;

  /// Total number of steps.
  final int stepCount;

  /// Accent colour for completed / active circles and connectors.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final List<Widget> row = <Widget>[];
    for (int i = 0; i < stepCount; i++) {
      row.add(_StepCircle(index: i, currentStep: currentStep, accent: accent));
      if (i < stepCount - 1) {
        row.add(
          Expanded(
            child: _Connector(
              // The segment leaving step i is "done" once you've passed step i.
              done: i < currentStep,
              accent: accent,
              trackColor: palette.border,
            ),
          ),
        );
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: row,
    );
  }
}

/// A single numbered circle. Completed → accent fill + check; active → accent
/// fill + number; upcoming → muted fill + number.
class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.currentStep,
    required this.accent,
  });

  final int index;
  final int currentStep;
  final Color accent;

  static const double _size = 30;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool done = index < currentStep;
    final bool active = index == currentStep;
    final bool filled = done || active;

    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? accent : palette.inputFill,
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: palette.border),
      ),
      child: done
          ? const Icon(
              Icons.check,
              size: 16,
              color: AppColors.neutralWhite,
            )
          : Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.neutralWhite : palette.textMuted,
              ),
            ),
    );
  }
}

/// The line between two circles. [done] paints it in the accent, otherwise the
/// muted track colour.
class _Connector extends StatelessWidget {
  const _Connector({
    required this.done,
    required this.accent,
    required this.trackColor,
  });

  final bool done;
  final Color accent;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sp8),
      decoration: BoxDecoration(
        color: done ? accent : trackColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
