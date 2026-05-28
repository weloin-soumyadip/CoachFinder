/// Forgot Password screen — request a recovery link by email.
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
import '../auth_role_accents.dart';
import '../auth_validators.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Forgot Password screen.
///
/// Collects the account email and validates it on submit. Phase 1 shows a
/// success SnackBar (no backend yet). The spec's stray "password" field is
/// intentionally omitted — you don't enter a password to recover one. The
/// CTA, focused input ring, and footer link adopt the active role's accent.
class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final String? role = ref.watch(roleProvider);
    final Color accent = authAccent(role);
    final List<Color> orbs = authBackdropOrbs(role);

    void onRecover() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.forgotSuccess)),
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
                        AppStrings.forgotTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp4),
                      Text(
                        AppStrings.forgotSubtitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp4),
                      Text(
                        AppStrings.forgotDescription,
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
                              textInputAction: TextInputAction.done,
                              validator: AuthValidators.email,
                              accent: accent,
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthPrimaryButton(
                              label: AppStrings.recoverPasswordButton,
                              accent: accent,
                              onPressed: onRecover,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      AuthBottomLink(
                        prefix: AppStrings.forgotRememberPrefix,
                        actionLabel: AppStrings.signIn,
                        accent: accent,
                        onAction: () => context.goNamed(AppRoutes.login),
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
