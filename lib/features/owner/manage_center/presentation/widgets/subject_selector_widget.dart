/// Multi-select subject picker used in the center edit form.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/models/subject_option.dart';

/// A wrap of toggleable subject chips. Selected subjects (by id) fill with the
/// owner accent; tapping a chip toggles it via [onToggle] (the subject id).
class SubjectSelectorWidget extends StatelessWidget {
  const SubjectSelectorWidget({
    super.key,
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  /// All selectable subjects.
  final List<SubjectOption> options;

  /// The ids currently selected.
  final Set<String> selectedIds;

  /// Fired with a subject id when its chip is tapped.
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sp8,
      runSpacing: AppSpacing.sp8,
      children: <Widget>[
        for (final SubjectOption option in options)
          _SelectableChip(
            label: option.name,
            selected: selectedIds.contains(option.id),
            onTap: () => onToggle(option.id),
          ),
      ],
    );
  }
}

/// A pill toggle: owner-accent fill with white label when selected, bordered
/// surface otherwise.
class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? AppColors.ownerAccent : palette.surface,
      borderRadius: BorderRadius.circular(AppSpacing.sp24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp24),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16,
            vertical: AppSpacing.sp8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.sp24),
            border: Border.all(
              color: selected ? AppColors.ownerAccent : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                selected ? Icons.check : Icons.add,
                size: 16,
                color: selected ? AppColors.neutralWhite : palette.textMuted,
              ),
              const SizedBox(width: AppSpacing.sp4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? AppColors.neutralWhite
                          : palette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
