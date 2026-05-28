/// Sign Up screen — calls authProvider.register and reacts to AuthState.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_backdrop.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../data/controllers/auth_provider.dart';
import '../../data/models/auth_state.dart';
import '../auth_role_accents.dart';
import '../auth_validators.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Sign Up screen.
///
/// The form validates on submit (required names, email format, 8-char password,
/// matching confirmation). On valid submit, it calls
/// `ref.read(authProvider.notifier).register(...)` and reacts to [AuthState]
/// transitions via `ref.listen`:
///
///  - `AuthAuthenticated` → route to the role's landing screen.
///  - `AuthError` → SnackBar with the failure message verbatim.
///
/// `AuthLoading` greys out the Sign Up button and swaps its label for a
/// spinner. The CTA, focused input ring, and footer link all adopt the
/// active role's accent.
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

    final String? role = ref.watch(roleProvider) ?? initialRole;
    final Color accent = authAccent(role);
    final List<Color> orbs = authBackdropOrbs(role);
    final AuthState authState = ref.watch(authProvider);
    final bool isLoading = authState is AuthLoading;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    // React to state transitions for navigation + error UX.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!context.mounted) return;
      if (next is AuthAuthenticated) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.goNamed(landingRouteForRole(next.role));
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    Future<void> onCreateAccount() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final String resolvedRole =
          ref.read(roleProvider) ?? initialRole ?? roleStudent;
      await ref.read(authProvider.notifier).register(
            firstName: firstNameCtrl.text,
            lastName: lastNameCtrl.text,
            email: emailCtrl.text,
            password: passwordCtrl.text,
            role: resolvedRole,
          );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: orbs,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp16,
                  AppSpacing.sp24,
                  AppSpacing.sp16,
                  AppSpacing.sp24,
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
                      const SizedBox(height: AppSpacing.sp4),
                      Text(
                        AppStrings.registerSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      GlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.sp16),
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
                                    accent: accent,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sp8),
                                Expanded(
                                  child: AuthFieldWidget(
                                    label: AppStrings.fieldLastName,
                                    hint: AppStrings.hintLastName,
                                    icon: Icons.person_outline,
                                    controller: lastNameCtrl,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    validator: AuthValidators.notEmpty,
                                    accent: accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            AuthFieldWidget(
                              label: AppStrings.fieldEmail,
                              hint: AppStrings.hintEmail,
                              icon: Icons.mail_outline,
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.email,
                              accent: accent,
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            AuthFieldWidget(
                              label: AppStrings.fieldPassword,
                              icon: Icons.lock_outline,
                              controller: passwordCtrl,
                              obscureText: !passwordVisible.value,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.password,
                              accent: accent,
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
                            const SizedBox(height: AppSpacing.sp12),
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
                              accent: accent,
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
                            const SizedBox(height: AppSpacing.sp16),
                            AuthPrimaryButton(
                              label: AppStrings.signUp,
                              accent: accent,
                              isLoading: isLoading,
                              onPressed: onCreateAccount,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      const AuthOrDivider(text: AppStrings.authOr),
                      const SizedBox(height: AppSpacing.sp12),
                      GlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.sp12),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: AuthOAuthButton(
                                label: AppStrings.socialGoogle,
                                icon: Icons.g_mobiledata,
                                onPressed: () =>
                                    stub(AppStrings.stubGoogleSignIn),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sp8),
                            Expanded(
                              child: AuthOAuthButton(
                                label: AppStrings.socialFacebook,
                                icon: Icons.facebook,
                                onPressed: () =>
                                    stub(AppStrings.stubAppleSignIn),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      AuthBottomLink(
                        prefix: AppStrings.alreadyHaveAccount,
                        actionLabel: AppStrings.signIn,
                        accent: accent,
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
