/// Center edit form - fields + the four selector widgets, with a Save button.
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
import '../../data/controllers/manage_center_provider.dart';
import '../../data/mock_center_data.dart';
import '../widgets/board_selector_widget.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/subject_selector_widget.dart';
import '../widgets/timing_editor_widget.dart';

/// Owner center edit form.
///
/// Seeds local draft state from [manageCenterProvider] (read once so the form
/// doesn't reset on unrelated rebuilds), edits it via text fields and the
/// subject / board / timing / photo widgets, then commits the whole profile on
/// Save and pops back to the read view. Adding a photo is a "coming soon" stub
/// (no image picker in the stack).
class EditCenterScreen extends HookConsumerWidget {
  const EditCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CenterProfile current = ref.read(manageCenterProvider);
    final ManageCenterNotifier notifier =
        ref.read(manageCenterProvider.notifier);
    final palette = context.palette;

    final TextEditingController nameC =
        useTextEditingController(text: current.name);
    final TextEditingController taglineC =
        useTextEditingController(text: current.tagline);
    final TextEditingController locationC =
        useTextEditingController(text: current.location);
    final TextEditingController addressC =
        useTextEditingController(text: current.address);
    final TextEditingController aboutC =
        useTextEditingController(text: current.about);
    final TextEditingController phoneC =
        useTextEditingController(text: current.phone);
    final TextEditingController emailC =
        useTextEditingController(text: current.email);

    final ValueNotifier<List<String>> subjects =
        useState<List<String>>(List<String>.of(current.subjects));
    final ValueNotifier<List<String>> boards =
        useState<List<String>>(List<String>.of(current.boards));
    final ValueNotifier<List<DayTiming>> timings =
        useState<List<DayTiming>>(List<DayTiming>.of(current.timings));
    final ValueNotifier<List<CenterPhoto>> photos =
        useState<List<CenterPhoto>>(List<CenterPhoto>.of(current.photos));
    final ValueNotifier<List<CourseFee>> fees =
        useState<List<CourseFee>>(List<CourseFee>.of(current.fees));

    void toggle(ValueNotifier<List<String>> notifier, String value) {
      notifier.value = notifier.value.contains(value)
          ? notifier.value.where((String v) => v != value).toList()
          : <String>[...notifier.value, value];
    }

    void toggleDay(int i) {
      timings.value = <DayTiming>[
        for (int j = 0; j < timings.value.length; j++)
          if (j == i)
            timings.value[j].copyWith(isOpen: !timings.value[j].isOpen)
          else
            timings.value[j],
      ];
    }

    Future<void> pickTime(int i, bool openField) async {
      final DayTiming day = timings.value[i];
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: openField ? day.openAt : day.closeAt,
      );
      if (picked == null) return;
      timings.value = <DayTiming>[
        for (int j = 0; j < timings.value.length; j++)
          if (j == i)
            openField
                ? timings.value[j].copyWith(openAt: picked)
                : timings.value[j].copyWith(closeAt: picked)
          else
            timings.value[j],
      ];
    }

    void stub() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.stubComingSoon)),
        );
    }

    void removePhoto(String id) {
      photos.value = photos.value.where((CenterPhoto p) => p.id != id).toList();
    }

    void updateFee(String id, {String? course, String? fee}) {
      fees.value = <CourseFee>[
        for (final CourseFee f in fees.value)
          if (f.id == id) f.copyWith(course: course, fee: fee) else f,
      ];
    }

    void removeFee(String id) {
      fees.value = fees.value.where((CourseFee f) => f.id != id).toList();
    }

    void addFee() {
      fees.value = <CourseFee>[
        ...fees.value,
        CourseFee(
          id: 'fee-${DateTime.now().microsecondsSinceEpoch}',
          course: '',
          fee: '',
        ),
      ];
    }

    void save() {
      notifier.save(
        current.copyWith(
          name: nameC.text.trim(),
          tagline: taglineC.text.trim(),
          location: locationC.text.trim(),
          address: addressC.text.trim(),
          about: aboutC.text.trim(),
          phone: phoneC.text.trim(),
          email: emailC.text.trim(),
          subjects: subjects.value,
          boards: boards.value,
          timings: timings.value,
          photos: photos.value,
          fees: fees.value,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.centerSavedSnack)),
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
          AppStrings.centerEditTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
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
                _Field(
                  label: AppStrings.centerFieldName,
                  controller: nameC,
                ),
                _Field(
                  label: AppStrings.centerFieldTagline,
                  controller: taglineC,
                ),
                _Field(
                  label: AppStrings.centerFieldLocation,
                  controller: locationC,
                ),
                _Field(
                  label: AppStrings.centerFieldAddress,
                  controller: addressC,
                  maxLines: 2,
                ),
                _Field(
                  label: AppStrings.centerFieldAbout,
                  controller: aboutC,
                  maxLines: 4,
                ),
                const _EditSectionTitle(
                  title: AppStrings.centerSectionSubjects,
                ),
                SubjectSelectorWidget(
                  options: allSubjects,
                  selected: subjects.value,
                  onToggle: (String s) => toggle(subjects, s),
                ),
                const _EditSectionTitle(
                  title: AppStrings.centerSectionBoards,
                ),
                BoardSelectorWidget(
                  options: allBoards,
                  selected: boards.value,
                  onToggle: (String b) => toggle(boards, b),
                ),
                const _EditSectionTitle(
                  title: AppStrings.centerSectionTimings,
                ),
                TimingEditorWidget(
                  timings: timings.value,
                  onToggleDay: toggleDay,
                  onPickTime: pickTime,
                ),
                const _EditSectionTitle(
                  title: AppStrings.centerSectionPhotos,
                ),
                ImageUploadWidget(
                  photos: photos.value,
                  onAdd: stub,
                  onRemove: removePhoto,
                ),
                const _EditSectionTitle(
                  title: AppStrings.centerSectionContact,
                ),
                _Field(
                  label: AppStrings.centerFieldPhone,
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                ),
                _Field(
                  label: AppStrings.centerFieldEmail,
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                ),
                const _EditSectionTitle(title: AppStrings.centerSectionFees),
                for (final CourseFee fee in fees.value)
                  Padding(
                    key: ValueKey<String>(fee.id),
                    padding: const EdgeInsets.only(bottom: AppSpacing.sp12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            initialValue: fee.course,
                            onChanged: (String v) =>
                                updateFee(fee.id, course: v),
                            style: TextStyle(color: palette.textPrimary),
                            decoration: _feeDecoration(
                              context,
                              AppStrings.centerFieldCourseName,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sp8),
                        SizedBox(
                          width: 110,
                          child: TextFormField(
                            initialValue: fee.fee,
                            onChanged: (String v) => updateFee(fee.id, fee: v),
                            style: TextStyle(color: palette.textPrimary),
                            decoration: _feeDecoration(
                              context,
                              AppStrings.centerFieldFee,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => removeFee(fee.id),
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: addFee,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.centerAddCourse),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ownerAccent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sp24),
                FilledButton(
                  onPressed: save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ownerAccent,
                    foregroundColor: AppColors.neutralWhite,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sp12),
                    ),
                  ),
                  child: const Text(
                    AppStrings.centerSave,
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

  InputDecoration _feeDecoration(BuildContext context, String hint) {
    final palette = context.palette;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: palette.textMuted),
      filled: true,
      fillColor: palette.inputFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp12,
        vertical: AppSpacing.sp12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
        borderSide: BorderSide.none,
      ),
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

/// Bold section title with top spacing, used between form blocks.
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
