/// Student change-password screen, wired to `POST /api/students/me/password`
/// via [studentProfileControllerProvider]. The data layer persists the
/// re-issued tokens so the session survives the server-side revocation.
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

/// Student change-password form: current + new + confirm, validated client-side
/// (min length, match, must differ) and submitted to the backend. On success it
/// snackbars + pops; on failure it surfaces the backend's verbatim message
/// (e.g. `Invalid current password`).
class ChangePasswordScreen extends HookConsumerWidget {
  /// Creates the change-password screen.
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final TextEditingController currentC = useTextEditingController();
    final TextEditingController newC = useTextEditingController();
    final TextEditingController confirmC = useTextEditingController();
    final ValueNotifier<bool> saving = useState<bool>(false);

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      saving.value = true;
      final bool ok = await ref
          .read(studentProfileControllerProvider.notifier)
          .changePassword(
            currentPassword: currentC.text,
            newPassword: newC.text,
          );
      saving.value = false;
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(AppStrings.changePasswordSuccessSnack),
            ),
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

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          AppStrings.profileChangePassword,
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
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    AppStrings.changePasswordSubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: palette.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.sp24),
                  _PasswordField(
                    label: AppStrings.changePasswordCurrent,
                    controller: currentC,
                    validator: AuthValidators.notEmpty,
                  ),
                  _PasswordField(
                    label: AppStrings.changePasswordNew,
                    controller: newC,
                    validator: (String? v) {
                      final String? base = AuthValidators.password(v);
                      if (base != null) return base;
                      if (v == currentC.text) {
                        return AppStrings.changePasswordSameAsOld;
                      }
                      return null;
                    },
                  ),
                  _PasswordField(
                    label: AppStrings.changePasswordConfirm,
                    controller: confirmC,
                    validator: (String? v) =>
                        AuthValidators.confirmPassword(v, newC.text),
                  ),
                  const SizedBox(height: AppSpacing.sp24),
                  FilledButton(
                    onPressed: saving.value ? null : submit,
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
                            AppStrings.changePasswordSubmit,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled obscured password field used across the change-password form.
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.validator,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

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
            obscureText: true,
            validator: validator,
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
