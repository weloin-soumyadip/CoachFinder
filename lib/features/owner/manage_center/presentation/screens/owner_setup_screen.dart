/// Owner setup gate — the first screen a freshly-authenticated owner lands on
/// (top-level route, NO bottom tabs). It checks `GET /api/centers/me`: if the
/// owner already has a center it forwards to the dashboard; if not (`404`) it
/// hosts the create-center wizard. On create it forwards to the dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/controllers/create_center_provider.dart';
import '../../data/repository/manage_center_repository.dart';
import '../widgets/center_create_wizard.dart';

/// The phases the gate moves through.
enum _SetupPhase { checking, noCenter, error }

/// Owner setup gate screen.
class OwnerSetupScreen extends HookConsumerWidget {
  /// Creates the gate screen.
  const OwnerSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final ValueNotifier<_SetupPhase> phase =
        useState<_SetupPhase>(_SetupPhase.checking);
    final ValueNotifier<String?> errorMessage = useState<String?>(null);

    Future<void> runCheck() async {
      phase.value = _SetupPhase.checking;
      errorMessage.value = null;
      try {
        final bool has =
            await ref.read(manageCenterRepositoryProvider).hasCenter();
        if (!context.mounted) return;
        if (has) {
          context.goNamed(AppRoutes.ownerDashboard);
        } else {
          phase.value = _SetupPhase.noCenter;
        }
      } on ManageCenterException catch (e) {
        if (!context.mounted) return;
        errorMessage.value = e.message;
        phase.value = _SetupPhase.error;
      }
    }

    useEffect(() {
      // Run the existence check once, after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => runCheck());
      return null;
    }, const <Object?>[]);

    Widget body;
    switch (phase.value) {
      case _SetupPhase.checking:
        body = const Center(child: CircularProgressIndicator());
      case _SetupPhase.error:
        body = _CheckError(
          message: errorMessage.value ?? AppStrings.centerSetupError,
          onRetry: runCheck,
        );
      case _SetupPhase.noCenter:
        body = CenterCreateWizard(
          onCreated: () {
            if (context.mounted) context.goNamed(AppRoutes.ownerDashboard);
          },
        );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(child: body),
    );
  }
}

/// Inline failure state for the existence check, with a retry button.
class _CheckError extends StatelessWidget {
  const _CheckError({required this.message, required this.onRetry});

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
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ownerAccent,
                foregroundColor: AppColors.neutralWhite,
              ),
              child: const Text(AppStrings.dashboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
