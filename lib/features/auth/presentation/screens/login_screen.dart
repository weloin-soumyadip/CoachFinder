/// Sign In screen consuming authProvider.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/dev_credentials.dart';
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

/// Sign In screen.
///
/// The form validates on submit (email format + 8-char password). Phase 1: a
/// `kDebugMode` test credential ([DevCredentials]) signs in and lands on the
/// role-appropriate shell; any other input shows an error, and release builds
/// disable the bypass. [initialRole] arrives from onboarding via GoRouter
/// `extra`. The "Remember for 30 days" toggle and social buttons are local /
/// stubbed until the backend auth contract lands.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final passwordVisible = useState(false);
    final rememberMe = useState(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> handleSignIn() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final email = emailCtrl.text.trim().toLowerCase();
      final password = passwordCtrl.text;
      final isTestUser = kDebugMode &&
          email == DevCredentials.testEmail &&
          password == DevCredentials.testPassword;
      if (!isTestUser) {
        stub(kDebugMode
            ? AppStrings.loginInvalidCredentials
            : AppStrings.stubAuthNotImplemented);
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
                        AppStrings.loginTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp8),
                      Text(
                        AppStrings.loginSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      GlassPanel(
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
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthFieldWidget(
                              label: AppStrings.fieldPassword,
                              icon: Icons.lock_outline,
                              controller: passwordCtrl,
                              obscureText: !passwordVisible.value,
                              textInputAction: TextInputAction.done,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                _RememberToggle(
                                  value: rememberMe.value,
                                  onChanged: (bool v) => rememberMe.value = v,
                                ),
                                GestureDetector(
                                  onTap: () => context
                                      .pushNamed(AppRoutes.forgotPassword),
                                  child: Text(
                                    AppStrings.forgotPassword,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: palette.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sp24),
                            AuthPrimaryButton(
                              label: AppStrings.signIn,
                              onPressed: handleSignIn,
                            ),
                            if (kDebugMode) ...<Widget>[
                              const SizedBox(height: AppSpacing.sp12),
                              const _DebugCredentialHint(),
                            ],
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
                        prefix: AppStrings.dontHaveAccount,
                        actionLabel: AppStrings.signUp,
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

/// "Remember for 30 days" checkbox + label.
class _RememberToggle extends StatelessWidget {
  const _RememberToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (bool? v) => onChanged(v ?? false),
            activeColor: palette.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sp4),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppSpacing.sp8),
        Text(
          AppStrings.authRememberMe,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

/// Debug-only hint showing the test-account credentials beneath the Sign In
/// button. Only rendered when `kDebugMode` is true, so it never ships.
class _DebugCredentialHint extends StatelessWidget {
  const _DebugCredentialHint();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp12,
          vertical: AppSpacing.sp8,
        ),
        decoration: BoxDecoration(
          color: palette.borderSubtle,
          borderRadius: BorderRadius.circular(AppSpacing.sp8),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.info_outline, size: 16, color: palette.textMuted),
            const SizedBox(width: AppSpacing.sp8),
            Flexible(
              child: Text(
                '${AppStrings.loginTestAccountLabel}: '
                '${DevCredentials.testEmail} / ${DevCredentials.testPassword}',
                style: textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
