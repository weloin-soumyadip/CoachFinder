/// Register screen consuming authProvider - sends the chosen role to the backend.
library;

import 'package:flutter/gestures.dart';
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
import '../../../../core/theme/app_spacing.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Register screen.
///
/// Phase 1 placeholder. The form is interactive (typing, password visibility,
/// terms checkbox). The submit button surfaces a SnackBar stub until the
/// backend register contract lands; the role from [initialRole] will be
/// included in that POST when wired.
class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final passwordVisible = useState(false);
    final confirmVisible = useState(false);
    final termsAccepted = useState(false);
    final textTheme = Theme.of(context).textTheme;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    // TODO(real-auth): replace with the real register flow once the backend
    // contract lands. Phase 1 dev shortcut: write a placeholder JWT and
    // navigate into the role-appropriate shell.
    Future<void> onCreateAccount() async {
      if (!termsAccepted.value) {
        stub(AppStrings.stubTermsRequired);
        return;
      }
      final hive = ref.read(hiveServiceProvider);
      await hive.authBox.put(HiveKeys.keyJwtToken, 'phase1-dev-token');
      final role = ref.read(roleProvider) ?? initialRole ?? roleStudent;
      if (!context.mounted) return;
      context.goNamed(
        role == roleStudent
            ? AppRoutes.studentHome
            : AppRoutes.ownerDashboard,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutralGrey50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.sp8),
              _RegisterTopBar(
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.goNamed(
                        AppRoutes.login,
                        extra: initialRole,
                      ),
              ),
              const SizedBox(height: AppSpacing.sp16),
              AuthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Text(
                        AppStrings.registerTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp4),
                    Center(
                      child: Text(
                        AppStrings.registerSubtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.neutralGrey500,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp24),
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
                    const SizedBox(height: AppSpacing.sp16),
                    const AuthOrDivider(text: AppStrings.orEmail),
                    const SizedBox(height: AppSpacing.sp16),
                    AuthFieldWidget(
                      label: AppStrings.fieldFullName,
                      hint: AppStrings.hintFullName,
                      icon: Icons.person_outline,
                      controller: nameCtrl,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: AppSpacing.sp16),
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
                    const SizedBox(height: AppSpacing.sp16),
                    AuthFieldWidget(
                      label: AppStrings.fieldConfirmPassword,
                      icon: Icons.shield_outlined,
                      controller: confirmCtrl,
                      obscureText: !confirmVisible.value,
                      trailing: IconButton(
                        icon: Icon(
                          confirmVisible.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.neutralGrey500,
                          size: 20,
                        ),
                        onPressed: () =>
                            confirmVisible.value = !confirmVisible.value,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp16),
                    _TermsCheckbox(
                      accepted: termsAccepted.value,
                      onChanged: (v) => termsAccepted.value = v,
                      onTapTerms: () => stub(AppStrings.stubTermsTap),
                      onTapPrivacy: () => stub(AppStrings.stubTermsTap),
                    ),
                    const SizedBox(height: AppSpacing.sp16),
                    AuthPrimaryButton(
                      label: AppStrings.createAccountButton,
                      onPressed: onCreateAccount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sp16),
              AuthBottomLink(
                prefix: AppStrings.alreadyHaveAccount,
                actionLabel: AppStrings.signIn,
                onAction: () =>
                    context.goNamed(AppRoutes.login, extra: initialRole),
              ),
              const SizedBox(height: AppSpacing.sp24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top bar for the register screen - back arrow + CoachFinder wordmark.
class _RegisterTopBar extends StatelessWidget {
  const _RegisterTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.studentPrimary,
          onPressed: onBack,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: AppSpacing.sp4),
        Text(
          AppStrings.appName,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.studentPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Terms-and-privacy checkbox row with inline links.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.accepted,
    required this.onChanged,
    required this.onTapTerms,
    required this.onTapPrivacy,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.neutralGrey700,
      height: 1.4,
    );
    final linkStyle = bodyStyle?.copyWith(
      color: AppColors.studentPrimary,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: accepted,
            onChanged: (v) => onChanged(v ?? false),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sp4),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppSpacing.sp12),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: bodyStyle,
              children: <InlineSpan>[
                const TextSpan(text: AppStrings.termsPrefix),
                TextSpan(
                  text: AppStrings.termsOfService,
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = onTapTerms,
                ),
                const TextSpan(text: AppStrings.termsAnd),
                TextSpan(
                  text: AppStrings.privacyPolicy,
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = onTapPrivacy,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

