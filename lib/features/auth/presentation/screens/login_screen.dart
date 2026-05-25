/// Login screen consuming authProvider.
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
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Login screen.
///
/// Phase 1 placeholder: the form is interactive (input typing, password
/// visibility toggle, focus styles) but the submit / forgot-password / social
/// buttons surface SnackBar stubs until the backend auth contract lands.
/// [initialRole] is received from onboarding via GoRouter `extra` and will be
/// used to choose the post-login landing route once auth is real.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final passwordVisible = useState(false);
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    // TODO(real-auth): replace with the real login flow once the backend
    // contract lands. Until then a debug-only test credential signs in: typing
    // the [DevCredentials] account writes a placeholder JWT and lands on the
    // role-appropriate shell. Any other input is rejected, and in release
    // builds the bypass is disabled entirely so it can't ship.
    Future<void> handleLogIn() async {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.sp32),
              const AuthBrandingBadge(),
              const SizedBox(height: AppSpacing.sp12),
              Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sp24),
              AuthCard(
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
                    const SizedBox(height: AppSpacing.sp24),
                    AuthFieldWidget(
                      label: AppStrings.fieldEmail,
                      hint: AppStrings.hintEmail,
                      icon: Icons.mail_outline,
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.sp16),
                    AuthFieldWidget(
                      label: AppStrings.fieldPassword,
                      icon: Icons.lock_outline,
                      controller: passwordCtrl,
                      obscureText: !passwordVisible.value,
                      labelTrailing: GestureDetector(
                        onTap: () => stub(AppStrings.stubForgotPassword),
                        child: Text(
                          AppStrings.forgotPassword,
                          style: textTheme.labelLarge?.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          passwordVisible.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: palette.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            passwordVisible.value = !passwordVisible.value,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp24),
                    AuthPrimaryButton(
                      label: AppStrings.logInButton,
                      trailingIcon: Icons.login,
                      onPressed: handleLogIn,
                    ),
                    if (kDebugMode) ...<Widget>[
                      const SizedBox(height: AppSpacing.sp12),
                      const _DebugCredentialHint(),
                    ],
                    const SizedBox(height: AppSpacing.sp16),
                    const AuthOrDivider(text: AppStrings.orContinueWith),
                    const SizedBox(height: AppSpacing.sp16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AuthOAuthButton(
                            label: AppStrings.google,
                            icon: Icons.g_mobiledata,
                            onPressed: () => stub(AppStrings.stubGoogleSignIn),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sp12),
                        Expanded(
                          child: AuthOAuthButton(
                            label: AppStrings.apple,
                            icon: Icons.apple,
                            onPressed: () => stub(AppStrings.stubAppleSignIn),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sp16),
              AuthBottomLink(
                prefix: AppStrings.dontHaveAccount,
                actionLabel: AppStrings.signUp,
                onAction: () =>
                    context.goNamed(AppRoutes.register, extra: initialRole),
              ),
              const SizedBox(height: AppSpacing.sp24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug-only hint showing the test-account credentials beneath the Log In
/// button so they don't have to be memorised while testing. The call site only
/// renders this when `kDebugMode` is true, so it never appears in release.
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
            Icon(
              Icons.info_outline,
              size: 16,
              color: palette.textMuted,
            ),
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
