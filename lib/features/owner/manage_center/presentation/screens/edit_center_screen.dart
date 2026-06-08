/// Center edit form — wired to `PATCH /api/centers/:id` via
/// [manageCenterControllerProvider]. Seeds from the loaded [OwnerCenter], edits
/// the backend-supported fields (identity, address, contact, boards, subjects,
/// class range, fee range, timings), and commits a STRICT PARTIAL (only changed
/// fields) on Save. Photos/gallery are not editable (no uploader in the stack).
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
import '../../../../auth/presentation/auth_validators.dart';
import '../../data/controllers/manage_center_provider.dart';
import '../../data/controllers/subjects_provider.dart';
import '../../data/models/center_update.dart';
import '../../data/models/owner_center.dart';
import '../../data/models/subject_option.dart';
import '../widgets/board_selector_widget.dart';
import '../widgets/subject_selector_widget.dart';
import '../widgets/timing_editor_widget.dart';

/// Ordered weekday labels for the timings editor.
const List<String> _weekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Owner center edit screen — loads, then hands the centre to [_EditForm].
class EditCenterScreen extends HookConsumerWidget {
  /// Creates the edit screen.
  const EditCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ManageCenterState state = ref.watch(manageCenterControllerProvider);
    final palette = context.palette;
    final OwnerCenter? center = state.center;

    Widget body;
    if (center == null && state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (center == null) {
      body = Center(
        child: Text(
          state.errorMessage ?? AppStrings.centerLoadError,
          style: TextStyle(color: palette.textMuted),
        ),
      );
    } else {
      body = _EditForm(center: center);
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
      body: body,
    );
  }
}

/// The form, seeded once from [center].
class _EditForm extends HookConsumerWidget {
  const _EditForm({required this.center});

  final OwnerCenter center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);

    final TextEditingController nameC =
        useTextEditingController(text: center.name);
    final TextEditingController descriptionC =
        useTextEditingController(text: center.description ?? '');
    final TextEditingController addressC =
        useTextEditingController(text: center.address);
    final TextEditingController areaC =
        useTextEditingController(text: center.area ?? '');
    final TextEditingController cityC =
        useTextEditingController(text: center.city);
    final TextEditingController stateC =
        useTextEditingController(text: center.state);
    final TextEditingController pincodeC =
        useTextEditingController(text: center.pincode);
    final TextEditingController phoneC =
        useTextEditingController(text: center.phone);
    final TextEditingController altPhoneC =
        useTextEditingController(text: center.alternatePhone ?? '');
    final TextEditingController emailC =
        useTextEditingController(text: center.email ?? '');
    final TextEditingController websiteC =
        useTextEditingController(text: center.website ?? '');
    final TextEditingController feeMinC = useTextEditingController(
      text:
          center.fees?.min == null ? '' : center.fees!.min!.round().toString(),
    );
    final TextEditingController feeMaxC = useTextEditingController(
      text:
          center.fees?.max == null ? '' : center.fees!.max!.round().toString(),
    );

    final ValueNotifier<List<String>> boards =
        useState<List<String>>(List<String>.of(center.boards));
    final ValueNotifier<Set<String>> subjectIds = useState<Set<String>>(
      center.subjects.map((SubjectOption s) => s.id).toSet(),
    );
    final ValueNotifier<int?> classFrom =
        useState<int?>(center.classRange?.from);
    final ValueNotifier<int?> classTo = useState<int?>(center.classRange?.to);
    final ValueNotifier<List<DayTiming>> timings =
        useState<List<DayTiming>>(_seedTimings(center.timings));
    final ValueNotifier<bool> timingsTouched = useState<bool>(false);
    final ValueNotifier<bool> saving = useState<bool>(false);

    void toggleBoard(String b) {
      boards.value = boards.value.contains(b)
          ? boards.value.where((String v) => v != b).toList()
          : <String>[...boards.value, b];
    }

    void toggleSubject(String id) {
      final Set<String> next = Set<String>.of(subjectIds.value);
      next.contains(id) ? next.remove(id) : next.add(id);
      subjectIds.value = next;
    }

    void toggleDay(int i) {
      timingsTouched.value = true;
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
      timingsTouched.value = true;
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

    /// Builds the strict-partial update — only the fields that changed.
    CenterUpdate buildUpdate() {
      String? changedText(String value, String original,
          {bool allowEmpty = false}) {
        final String v = value.trim();
        if (v == original.trim()) return null;
        if (v.isEmpty && !allowEmpty) return null;
        return v;
      }

      final CenterClassRange newRange =
          CenterClassRange(from: classFrom.value, to: classTo.value);
      final CenterClassRange oldRange =
          center.classRange ?? const CenterClassRange();

      final num? newMin = num.tryParse(feeMinC.text.trim());
      final num? newMax = num.tryParse(feeMaxC.text.trim());
      final String currency = center.fees?.currency ?? 'INR';
      final CenterFees newFees =
          CenterFees(min: newMin, max: newMax, currency: currency);
      final CenterFees oldFees = center.fees ?? CenterFees(currency: currency);

      final Set<String> oldSubjectIds =
          center.subjects.map((SubjectOption s) => s.id).toSet();

      return CenterUpdate(
        name: changedText(nameC.text, center.name),
        description: changedText(descriptionC.text, center.description ?? '',
            allowEmpty: true),
        address: changedText(addressC.text, center.address),
        area: changedText(areaC.text, center.area ?? ''),
        city: changedText(cityC.text, center.city),
        state: changedText(stateC.text, center.state),
        pincode: changedText(pincodeC.text, center.pincode),
        phone: changedText(phoneC.text, center.phone),
        alternatePhone:
            changedText(altPhoneC.text, center.alternatePhone ?? ''),
        email: changedText(emailC.text, center.email ?? ''),
        website: changedText(websiteC.text, center.website ?? ''),
        boards: _setEquals(boards.value.toSet(), center.boards.toSet())
            ? null
            : boards.value,
        subjectIds: _setEquals(subjectIds.value, oldSubjectIds)
            ? null
            : subjectIds.value.toList(),
        classRange: newRange == oldRange ? null : newRange,
        fees: newFees == oldFees ? null : newFees,
        timings: timingsTouched.value
            ? timings.value.map(_toCenterTiming).toList()
            : null,
      );
    }

    Future<void> save() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      saving.value = true;
      final bool ok = await ref
          .read(manageCenterControllerProvider.notifier)
          .save(buildUpdate());
      saving.value = false;
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.centerSavedSnack)),
          );
        context.pop();
      } else {
        final String message =
            ref.read(manageCenterControllerProvider).errorMessage ??
                AppStrings.centerSaveError;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }

    final AsyncValue<List<SubjectOption>> subjectsAsync =
        ref.watch(subjectsProvider);

    return Align(
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
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Field(
                  label: AppStrings.centerFieldName,
                  controller: nameC,
                  validator: AuthValidators.notEmpty,
                ),
                _Field(
                  label: AppStrings.centerFieldDescription,
                  controller: descriptionC,
                  maxLines: 4,
                ),
                const _EditSectionTitle(
                  title: AppStrings.centerSectionSubjects,
                ),
                subjectsAsync.when(
                  data: (List<SubjectOption> opts) => SubjectSelectorWidget(
                    options: opts,
                    selectedIds: subjectIds.value,
                    onToggle: toggleSubject,
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sp12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => SubjectSelectorWidget(
                    options: center.subjects,
                    selectedIds: subjectIds.value,
                    onToggle: toggleSubject,
                  ),
                ),
                const _EditSectionTitle(title: AppStrings.centerSectionBoards),
                BoardSelectorWidget(
                  options: OwnerCenter.boardOptions,
                  selected: boards.value,
                  onToggle: toggleBoard,
                ),
                const _EditSectionTitle(title: AppStrings.centerSectionClasses),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ClassDropdown(
                        label: AppStrings.centerFieldClassFrom,
                        value: classFrom.value,
                        onChanged: (int? v) => classFrom.value = v,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sp12),
                    Expanded(
                      child: _ClassDropdown(
                        label: AppStrings.centerFieldClassTo,
                        value: classTo.value,
                        onChanged: (int? v) => classTo.value = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp16),
                const _EditSectionTitle(title: AppStrings.centerSectionFees),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Field(
                        label: AppStrings.centerFeeMin,
                        controller: feeMinC,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sp12),
                    Expanded(
                      child: _Field(
                        label: AppStrings.centerFeeMax,
                        controller: feeMaxC,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const _EditSectionTitle(title: AppStrings.centerSectionTimings),
                TimingEditorWidget(
                  timings: timings.value,
                  onToggleDay: toggleDay,
                  onPickTime: pickTime,
                ),
                const SizedBox(height: AppSpacing.sp16),
                const _EditSectionTitle(title: AppStrings.centerSectionContact),
                _Field(
                  label: AppStrings.centerFieldPhone,
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  validator: AuthValidators.phone,
                ),
                _Field(
                  label: AppStrings.centerFieldAlternatePhone,
                  controller: altPhoneC,
                  keyboardType: TextInputType.phone,
                ),
                _Field(
                  label: AppStrings.centerFieldEmail,
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                ),
                _Field(
                  label: AppStrings.centerFieldWebsite,
                  controller: websiteC,
                  keyboardType: TextInputType.url,
                ),
                _Field(
                  label: AppStrings.centerFieldAddress,
                  controller: addressC,
                  maxLines: 2,
                  validator: AuthValidators.notEmpty,
                ),
                _Field(
                  label: AppStrings.centerFieldArea,
                  controller: areaC,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Field(
                        label: AppStrings.centerFieldCity,
                        controller: cityC,
                        validator: AuthValidators.notEmpty,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sp12),
                    Expanded(
                      child: _Field(
                        label: AppStrings.centerFieldState,
                        controller: stateC,
                        validator: AuthValidators.notEmpty,
                      ),
                    ),
                  ],
                ),
                _Field(
                  label: AppStrings.centerFieldPincode,
                  controller: pincodeC,
                  keyboardType: TextInputType.number,
                  validator: AuthValidators.notEmpty,
                ),
                const SizedBox(height: AppSpacing.sp24),
                FilledButton(
                  onPressed: saving.value ? null : save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ownerAccent,
                    foregroundColor: AppColors.neutralWhite,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sp12),
                    ),
                  ),
                  child: saving.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.neutralWhite,
                          ),
                        )
                      : const Text(
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
}

/// Seeds a full Mon–Sun [DayTiming] list from the centre's (possibly partial)
/// backend timings, defaulting missing days to closed.
List<DayTiming> _seedTimings(List<CenterTiming> backend) {
  const TimeOfDay defaultOpen = TimeOfDay(hour: 9, minute: 0);
  const TimeOfDay defaultClose = TimeOfDay(hour: 17, minute: 0);
  final Map<String, CenterTiming> byDay = <String, CenterTiming>{
    for (final CenterTiming t in backend) t.day: t,
  };
  return <DayTiming>[
    for (final String day in _weekdays)
      if (byDay[day] case final CenterTiming t)
        DayTiming(
          day: day,
          isOpen: !t.closed,
          openAt: timeOfDayFromHhmm(t.openTime, defaultOpen),
          closeAt: timeOfDayFromHhmm(t.closeTime, defaultClose),
        )
      else
        DayTiming(
          day: day,
          isOpen: false,
          openAt: defaultOpen,
          closeAt: defaultClose,
        ),
  ];
}

/// Converts a UI [DayTiming] to a backend [CenterTiming].
CenterTiming _toCenterTiming(DayTiming d) {
  return CenterTiming(
    day: d.day,
    closed: !d.isOpen,
    openTime: d.isOpen ? hhmmFromTimeOfDay(d.openAt) : null,
    closeTime: d.isOpen ? hhmmFromTimeOfDay(d.closeAt) : null,
  );
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

/// A 1–12 (or "Any") class dropdown.
class _ClassDropdown extends StatelessWidget {
  const _ClassDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
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
        DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: palette.surface,
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
          items: <DropdownMenuItem<int>>[
            DropdownMenuItem<int>(
              child: Text(AppStrings.centerClassAny),
            ),
            for (int i = 1; i <= 12; i++)
              DropdownMenuItem<int>(
                value: i,
                child: Text('${AppStrings.centerClassPrefix}$i'),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A labelled text form field used across the form.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

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
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
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

/// Bold section title with spacing, used between form blocks.
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
