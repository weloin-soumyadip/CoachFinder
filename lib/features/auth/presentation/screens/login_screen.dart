/// Login screen consuming authProvider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
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

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    return Scaffold(
      backgroundColor: AppColors.neutralGrey50,
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
                  color: AppColors.studentPrimary,
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
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp4),
                    Text(
                      AppStrings.loginSubtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutralGrey500,
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
                            color: AppColors.studentPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          passwordVisible.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.neutralGrey500,
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
                      onPressed: () => stub(AppStrings.stubAuthNotImplemented),
                    ),
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
