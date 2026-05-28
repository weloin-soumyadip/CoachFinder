/// Sign In screen — calls authController.signIn and reacts to AuthState.
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
import '../../data/providers/auth_providers.dart';
import '../auth_role_accents.dart';
import '../auth_validators.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Sign In screen.
///
/// The form validates on submit (email format + min 6-char password). On
/// valid submit, it calls
/// `ref.read(authControllerProvider.notifier).signIn(...)` and reacts to
/// [AuthState] transitions via `ref.listen`:
///
///  - `AuthStatus.authenticated` → route to the role's landing screen.
///  - `AuthStatus.error` → SnackBar with the failure message verbatim.
///
/// `AuthStatus.loading` greys out the Sign In button and swaps its label for
/// a spinner. The CTA, focused input ring, footer link, and "Forgot
/// password?" link all adopt the active role's accent.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final passwordVisible = useState(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final String? role = ref.watch(roleProvider) ?? initialRole;
    final Color accent = authAccent(role);
    final List<Color> orbs = authBackdropOrbs(role);
    final AuthState authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.isLoading;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!context.mounted) return;
      if (next.status == AuthStatus.authenticated && next.role != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.goNamed(landingRouteForRole(next.role!));
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    Future<void> handleSignIn() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final String resolvedRole =
          ref.read(roleProvider) ?? initialRole ?? roleStudent;
      await ref.read(authControllerProvider.notifier).signIn(
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
                        AppStrings.loginTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp4),
                      Text(
                        AppStrings.loginSubtitle,
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
                              textInputAction: TextInputAction.done,
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () =>
                                    context.pushNamed(AppRoutes.forgotPassword),
                                child: Text(
                                  AppStrings.forgotPassword,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthPrimaryButton(
                              label: AppStrings.signIn,
                              accent: accent,
                              isLoading: isLoading,
                              onPressed: handleSignIn,
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
                                icon: Icons.g_mobiledata_outlined,
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
                        prefix: AppStrings.dontHaveAccount,
                        actionLabel: AppStrings.signUp,
                        accent: accent,
                        onAction: () => context.goNamed(
                          AppRoutes.register,
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
