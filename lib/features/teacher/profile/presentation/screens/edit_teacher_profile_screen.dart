/// Teacher profile edit form - listing fields + tutor status, with Save.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../data/controllers/teacher_profile_provider.dart';
import '../../data/mock_teacher_profile_data.dart';

/// Teacher profile edit form.
///
/// Seeds local draft state from [teacherProfileProvider] (read once so the form
/// doesn't reset on unrelated rebuilds), edits the listing fields, subjects, and
/// tutor status, then commits the whole profile on Save and pops back to the
/// read view. Read-only metrics (rating, views, students, response) are not
/// edited here.
class EditTeacherProfileScreen extends HookConsumerWidget {
  const EditTeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TeacherProfile current = ref.read(teacherProfileProvider);
    final TeacherProfileNotifier notifier =
        ref.read(teacherProfileProvider.notifier);
    final palette = context.palette;

    final TextEditingController nameC =
        useTextEditingController(text: current.name);
    final TextEditingController headlineC =
        useTextEditingController(text: current.headline);
    final TextEditingController emailC =
        useTextEditingController(text: current.email);
    final TextEditingController bioC =
        useTextEditingController(text: current.bio);
    final TextEditingController expertiseC =
        useTextEditingController(text: current.expertise);
    final TextEditingController rateC =
        useTextEditingController(text: current.hourlyRate.toString());
    final TextEditingController experienceC =
        useTextEditingController(text: current.experienceYears.toString());
    final TextEditingController affiliationC =
        useTextEditingController(text: current.affiliation);

    final ValueNotifier<List<String>> subjects =
        useState<List<String>>(List<String>.of(current.subjects));
    final ValueNotifier<bool> isIndependent =
        useState<bool>(current.isIndependent);

    void toggleSubject(String value) {
      subjects.value = subjects.value.contains(value)
          ? subjects.value.where((String v) => v != value).toList()
          : <String>[...subjects.value, value];
    }

    void save() {
      notifier.save(
        current.copyWith(
          name: nameC.text.trim(),
          headline: headlineC.text.trim(),
          email: emailC.text.trim(),
          bio: bioC.text.trim(),
          expertise: expertiseC.text.trim(),
          hourlyRate: int.tryParse(rateC.text.trim()) ?? current.hourlyRate,
          experienceYears:
              int.tryParse(experienceC.text.trim()) ?? current.experienceYears,
          subjects: subjects.value,
          isIndependent: isIndependent.value,
          affiliation: isIndependent.value ? '' : affiliationC.text.trim(),
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.teacherSavedSnack)),
        );
      context.pop();
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          AppStrings.teacherEditTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sp16,
              AppSpacing.sp16,
              AppSpacing.sp16,
              floatingNavClearance(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Field(label: AppStrings.teacherFieldName, controller: nameC),
                _Field(
                  label: AppStrings.teacherFieldHeadline,
                  controller: headlineC,
                ),
                _Field(
                  label: AppStrings.teacherFieldEmail,
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                ),
                _Field(
                  label: AppStrings.teacherFieldBio,
                  controller: bioC,
                  maxLines: 4,
                ),
                _Field(
                  label: AppStrings.teacherFieldExpertise,
                  controller: expertiseC,
                  maxLines: 2,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Field(
                        label: AppStrings.teacherFieldRate,
                        controller: rateC,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sp12),
                    Expanded(
                      child: _Field(
                        label: AppStrings.teacherFieldExperience,
                        controller: experienceC,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const _EditSectionTitle(
                  title: AppStrings.teacherSectionSubjects,
                ),
                _SubjectChips(
                  options: teacherSubjectOptions,
                  selected: subjects.value,
                  onToggle: toggleSubject,
                ),
                const SizedBox(height: AppSpacing.sp24),
                _IndependentToggle(
                  value: isIndependent.value,
                  onChanged: (bool v) => isIndependent.value = v,
                ),
                if (!isIndependent.value) ...<Widget>[
                  const SizedBox(height: AppSpacing.sp16),
                  _Field(
                    label: AppStrings.teacherFieldAffiliation,
                    controller: affiliationC,
                  ),
                ],
                const SizedBox(height: AppSpacing.sp24),
                FilledButton(
                  onPressed: save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teacherAccent,
                    foregroundColor: AppColors.neutralWhite,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sp12),
                    ),
                  ),
                  child: const Text(
                    AppStrings.teacherSave,
                    style: TextStyle(fontWeight: FontWeight.w700),
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

/// Independent-tutor switch in a bordered surface row.
class _IndependentToggle extends StatelessWidget {
  const _IndependentToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sp16,
        AppSpacing.sp4,
        AppSpacing.sp8,
        AppSpacing.sp4,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              AppStrings.teacherFieldIndependent,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: palette.textPrimary,
                  ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.teacherAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Teal multi-select subject chips for the edit form.
class _SubjectChips extends StatelessWidget {
  const _SubjectChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      spacing: AppSpacing.sp8,
      runSpacing: AppSpacing.sp8,
      children: <Widget>[
        for (final String option in options)
          Builder(
            builder: (BuildContext context) {
              final bool isSelected = selected.contains(option);
              return Material(
                color: isSelected ? AppColors.teacherAccent : palette.surface,
                borderRadius: BorderRadius.circular(AppSpacing.sp24),
                child: InkWell(
                  onTap: () => onToggle(option),
                  borderRadius: BorderRadius.circular(AppSpacing.sp24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp16,
                      vertical: AppSpacing.sp8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.sp24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.teacherAccent
                            : palette.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          isSelected ? Icons.check : Icons.add,
                          size: 16,
                          color: isSelected
                              ? AppColors.neutralWhite
                              : palette.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sp4),
                        Text(
                          option,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: isSelected
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
            },
          ),
      ],
    );
  }
}

/// A labelled text field used across the form.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: palette.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp16,
                vertical: AppSpacing.sp12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sp12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bold section title with top spacing.
class _EditSectionTitle extends StatelessWidget {
  const _EditSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
      ),
    );
  }
}
