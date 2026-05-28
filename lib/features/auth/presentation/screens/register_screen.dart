/// Sign Up screen consuming authProvider — sends the chosen role to the backend.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/hive_keys.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/hive_service_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_backdrop.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../auth_validators.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Sign Up screen.
///
/// The form validates on submit (required names, email format, 8-char password,
/// matching confirmation). Phase 1: on a valid submit a debug-only shortcut
/// writes a placeholder JWT and lands on the role-appropriate shell; release
/// builds show the not-implemented stub. The chosen [initialRole] will be
/// included in the register POST once the backend lands.
class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstNameCtrl = useTextEditingController();
    final lastNameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final passwordVisible = useState(false);
    final confirmVisible = useState(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> onCreateAccount() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (!kDebugMode) {
        stub(AppStrings.stubAuthNotImplemented);
        return;
      }
      final hive = ref.read(hiveServiceProvider);
      await hive.authBox.put(HiveKeys.keyJwtToken, 'phase1-dev-token');
      final role = ref.read(roleProvider) ?? initialRole ?? roleStudent;
      if (!context.mounted) return;
      context.goNamed(landingRouteForRole(role));
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[
          AppColors.studentPrimary,
          AppColors.studentPrimaryDark,
        ],
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp24,
                  AppSpacing.sp32,
                  AppSpacing.sp24,
                  AppSpacing.sp32,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        AppStrings.registerTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp8),
                      Text(
                        AppStrings.registerSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: AuthFieldWidget(
                                    label: AppStrings.fieldFirstName,
                                    hint: AppStrings.hintFirstName,
                                    icon: Icons.person_outline,
                                    controller: firstNameCtrl,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    validator: AuthValidators.notEmpty,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sp12),
                                Expanded(
                                  child: AuthFieldWidget(
                                    label: AppStrings.fieldLastName,
                                    hint: AppStrings.hintLastName,
                                    icon: Icons.person_outline,
                                    controller: lastNameCtrl,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    validator: AuthValidators.notEmpty,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthFieldWidget(
                              label: AppStrings.fieldEmail,
                              hint: AppStrings.hintEmail,
                              icon: Icons.mail_outline,
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.email,
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthFieldWidget(
                              label: AppStrings.fieldPassword,
                              icon: Icons.lock_outline,
                              controller: passwordCtrl,
                              obscureText: !passwordVisible.value,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.password,
                              trailing: IconButton(
                                icon: Icon(
                                  passwordVisible.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: palette.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => passwordVisible.value =
                                    !passwordVisible.value,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthFieldWidget(
                              label: AppStrings.fieldConfirmPassword,
                              icon: Icons.shield_outlined,
                              controller: confirmCtrl,
                              obscureText: !confirmVisible.value,
                              textInputAction: TextInputAction.done,
                              validator: (String? v) =>
                                  AuthValidators.confirmPassword(
                                v,
                                passwordCtrl.text,
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  confirmVisible.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: palette.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => confirmVisible.value =
                                    !confirmVisible.value,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp24),
                            AuthPrimaryButton(
                              label: AppStrings.signUp,
                              onPressed: onCreateAccount,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      const AuthOrDivider(text: AppStrings.authOr),
                      const SizedBox(height: AppSpacing.sp16),
                      GlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.sp16),
                        child: Column(
                          children: <Widget>[
                            AuthOAuthButton(
                              label: AppStrings.socialGoogle,
                              icon: Icons.g_mobiledata,
                              onPressed: () =>
                                  stub(AppStrings.stubGoogleSignIn),
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            AuthOAuthButton(
                              label: AppStrings.socialFacebook,
                              icon: Icons.facebook,
                              onPressed: () => stub(AppStrings.stubAppleSignIn),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      AuthBottomLink(
                        prefix: AppStrings.alreadyHaveAccount,
                        actionLabel: AppStrings.signIn,
                        onAction: () => context.goNamed(
                          AppRoutes.login,
                          extra: initialRole,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
