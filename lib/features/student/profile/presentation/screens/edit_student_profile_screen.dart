/// Student profile edit form - personal + academic fields, wired to
/// `PATCH /api/students/me` via [studentProfileControllerProvider].
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
import '../../data/controllers/student_profile_provider.dart';
import '../../data/models/student_profile_model.dart';
import '../../data/models/student_profile_update.dart';

/// Student profile edit form.
///
/// Watches [studentProfileControllerProvider]; while the profile is still
/// loading (or failed) it shows a spinner / retry, otherwise it hands the
/// loaded [StudentProfile] to [_EditForm], which seeds local draft state and
/// commits a STRICT PARTIAL update (only changed fields) on Save. On success it
/// snackbars + pops back to the read view; on failure it stays on the form and
/// surfaces the backend message.
class EditStudentProfileScreen extends HookConsumerWidget {
  /// Creates the student edit-profile screen.
  const EditStudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StudentProfileState state =
        ref.watch(studentProfileControllerProvider);
    final palette = context.palette;
    final StudentProfile? profile = state.profile;

    Widget body;
    if (profile == null && state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (profile == null) {
      body = _LoadError(
        message: state.errorMessage ?? AppStrings.profileLoadError,
        onRetry: () =>
            ref.read(studentProfileControllerProvider.notifier).load(),
      );
    } else {
      body = _EditForm(profile: profile);
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          AppStrings.studentEditTitle,
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

/// The actual form, given a loaded [profile]. Seeds local hook draft state from
/// the profile once, then builds a [StudentProfileUpdate] containing only the
/// fields the user changed and submits it.
class _EditForm extends HookConsumerWidget {
  const _EditForm({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);

    final TextEditingController nameC =
        useTextEditingController(text: profile.name);
    final TextEditingController emailC =
        useTextEditingController(text: profile.email);
    final TextEditingController phoneC =
        useTextEditingController(text: profile.phone ?? '');
    final TextEditingController cityC =
        useTextEditingController(text: profile.city ?? '');

    final ValueNotifier<DateTime?> dob =
        useState<DateTime?>(profile.dateOfBirth);
    final ValueNotifier<StudentGender?> gender =
        useState<StudentGender?>(profile.gender);
    final ValueNotifier<int?> currentClass =
        useState<int?>(profile.currentClass);
    final ValueNotifier<StudentBoard?> board =
        useState<StudentBoard?>(profile.board);
    final ValueNotifier<bool> saving = useState<bool>(false);

    Future<void> pickDate() async {
      final DateTime now = DateTime.now();
      final DateTime picked = dob.value ?? DateTime(now.year - 15);
      final DateTime? result = await showDatePicker(
        context: context,
        initialDate: picked,
        firstDate: DateTime(1950),
        lastDate: now,
      );
      if (result != null) dob.value = result;
    }

    /// Builds an update holding ONLY fields that differ from [profile]. Text
    /// fields are trimmed; an emptied phone/city is omitted (this form can't
    /// clear them — the backend validates non-empty), and name is required.
    StudentProfileUpdate buildUpdate() {
      final String name = nameC.text.trim();
      final String phone = phoneC.text.trim();
      final String city = cityC.text.trim();
      return StudentProfileUpdate(
        name: name != profile.name ? name : null,
        phone:
            phone.isNotEmpty && phone != (profile.phone ?? '') ? phone : null,
        city: city.isNotEmpty && city != (profile.city ?? '') ? city : null,
        dateOfBirth:
            _sameDate(dob.value, profile.dateOfBirth) ? null : dob.value,
        gender: gender.value != profile.gender ? gender.value : null,
        currentClass: currentClass.value != profile.currentClass
            ? currentClass.value
            : null,
        board: board.value != profile.board ? board.value : null,
      );
    }

    Future<void> save() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      saving.value = true;
      final bool ok = await ref
          .read(studentProfileControllerProvider.notifier)
          .save(buildUpdate());
      saving.value = false;
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.studentSavedSnack)),
          );
        context.pop();
      } else {
        final String message =
            ref.read(studentProfileControllerProvider).errorMessage ??
                AppStrings.studentSaveError;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }

    return Align(
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
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _SectionTitle(title: AppStrings.studentSectionPersonal),
                _Field(
                  label: AppStrings.studentFieldName,
                  controller: nameC,
                  validator: AuthValidators.notEmpty,
                ),
                _Field(
                  label: AppStrings.studentFieldEmail,
                  controller: emailC,
                  enabled: false,
                  helperText: AppStrings.studentEmailReadonlyHint,
                ),
                _Field(
                  label: AppStrings.studentFieldPhone,
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  // Optional: only validate format when something was typed.
                  validator: (String? v) => (v == null || v.trim().isEmpty)
                      ? null
                      : AuthValidators.phone(v),
                ),
                _Field(
                  label: AppStrings.studentFieldCity,
                  controller: cityC,
                ),
                const SizedBox(height: AppSpacing.sp8),
                const _SectionTitle(title: AppStrings.studentSectionAcademic),
                _DateField(
                  label: AppStrings.studentFieldDob,
                  value: dob.value,
                  onTap: pickDate,
                ),
                _DropdownField<int>(
                  label: AppStrings.studentFieldClass,
                  value: currentClass.value,
                  items: <int>[for (int i = 1; i <= 12; i++) i],
                  labelFor: (int v) => '${AppStrings.studentClassPrefix}$v',
                  onChanged: (int? v) => currentClass.value = v,
                ),
                _DropdownField<StudentBoard>(
                  label: AppStrings.studentFieldBoard,
                  value: board.value,
                  items: StudentBoard.values,
                  labelFor: (StudentBoard v) => v.label,
                  onChanged: (StudentBoard? v) => board.value = v,
                ),
                _DropdownField<StudentGender>(
                  label: AppStrings.studentFieldGender,
                  value: gender.value,
                  items: StudentGender.values,
                  labelFor: (StudentGender v) => v.label,
                  onChanged: (StudentGender? v) => gender.value = v,
                ),
                const SizedBox(height: AppSpacing.sp24),
                FilledButton(
                  onPressed: saving.value ? null : save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.studentPrimary,
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
                          AppStrings.studentSave,
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

/// Whether [a] and [b] denote the same calendar day (date-only comparison),
/// treating two nulls as equal. Avoids re-sending an unchanged DOB just because
/// the seeded value carries a UTC time and a fresh pick carries local-midnight.
bool _sameDate(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == b;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// A labelled text field used across the form. Disabled when [enabled] is false
/// (e.g. the read-only email).
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.enabled = true,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final String? helperText;

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
            enabled: enabled,
            keyboardType: keyboardType,
            validator: validator,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              color: enabled ? palette.textPrimary : palette.textMuted,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.inputFill,
              helperText: helperText,
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

/// A labelled, tappable field that opens a date picker and shows the chosen
/// date (or a placeholder).
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool isSet = value != null;
    final String text = isSet
        ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
        : AppStrings.studentDobSelect;
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
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.sp12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp16,
                  vertical: AppSpacing.sp16,
                ),
                decoration: BoxDecoration(
                  color: palette.inputFill,
                  borderRadius: BorderRadius.circular(AppSpacing.sp12),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isSet
                                  ? palette.textPrimary
                                  : palette.textMuted,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: palette.iconFaint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled dropdown for an optional enum / int choice, with a "Select"
/// placeholder when nothing is chosen.
class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelFor;
  final ValueChanged<T?> onChanged;

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
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            hint: Text(
              AppStrings.studentSelectHint,
              style: TextStyle(color: palette.textMuted),
            ),
            style: TextStyle(color: palette.textPrimary),
            dropdownColor: palette.surface,
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
            items: <DropdownMenuItem<T>>[
              for (final T item in items)
                DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelFor(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Bold section title with top spacing.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

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

/// Inline load-failure state with a retry button (shown when the profile
/// couldn't be fetched before the form could be seeded).
class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off, size: 48, color: palette.iconFaint),
            const SizedBox(height: AppSpacing.sp12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: AppSpacing.sp16),
            TextButton(
              onPressed: onRetry,
              child: const Text(AppStrings.profileRetry),
            ),
          ],
        ),
      ),
    );
  }
}
