/// Owner profile edit form — name + phone (email read-only), wired to
/// `PATCH /api/owners/me` via [ownerProfileControllerProvider]. Commits a STRICT
/// PARTIAL (only changed fields). Mirrors the student edit-profile screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../auth/presentation/auth_validators.dart';
import '../../data/controllers/owner_profile_provider.dart';
import '../../data/models/owner_profile_model.dart';
import '../../data/models/owner_profile_update.dart';

/// Owner profile edit screen.
class EditOwnerProfileScreen extends HookConsumerWidget {
  /// Creates the edit screen.
  const EditOwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OwnerProfileState state = ref.watch(ownerProfileControllerProvider);
    final palette = context.palette;
    final OwnerProfile? profile = state.profile;

    Widget body;
    if (profile == null && state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (profile == null) {
      body = _LoadError(
        message: state.errorMessage ?? AppStrings.profileLoadError,
        onRetry: () => ref.read(ownerProfileControllerProvider.notifier).load(),
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
          AppStrings.ownerEditTitle,
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

/// The form, seeded once from [profile].
class _EditForm extends HookConsumerWidget {
  const _EditForm({required this.profile});

  final OwnerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final TextEditingController nameC =
        useTextEditingController(text: profile.name);
    final TextEditingController emailC =
        useTextEditingController(text: profile.email);
    final TextEditingController phoneC =
        useTextEditingController(text: profile.phone ?? '');
    final ValueNotifier<bool> saving = useState<bool>(false);

    /// Builds an update holding ONLY changed fields (name required; an emptied
    /// phone is omitted — the form can't clear it).
    OwnerProfileUpdate buildUpdate() {
      final String name = nameC.text.trim();
      final String phone = phoneC.text.trim();
      return OwnerProfileUpdate(
        name: name != profile.name && name.isNotEmpty ? name : null,
        phone:
            phone.isNotEmpty && phone != (profile.phone ?? '') ? phone : null,
      );
    }

    Future<void> save() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      saving.value = true;
      final bool ok = await ref
          .read(ownerProfileControllerProvider.notifier)
          .save(buildUpdate());
      saving.value = false;
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.ownerProfileSavedSnack)),
          );
        context.pop();
      } else {
        final String message =
            ref.read(ownerProfileControllerProvider).errorMessage ??
                AppStrings.ownerProfileSaveError;
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
          padding: const EdgeInsets.all(AppSpacing.sp16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Field(
                  label: AppStrings.ownerFieldName,
                  controller: nameC,
                  validator: AuthValidators.notEmpty,
                ),
                _Field(
                  label: AppStrings.ownerFieldEmail,
                  controller: emailC,
                  enabled: false,
                  helperText: AppStrings.studentEmailReadonlyHint,
                ),
                _Field(
                  label: AppStrings.ownerFieldPhone,
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  validator: (String? v) => (v == null || v.trim().isEmpty)
                      ? null
                      : AuthValidators.phone(v),
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

/// A labelled text field; disabled (read-only) when [enabled] is false.
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

/// Inline load-failure state with a retry button.
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
