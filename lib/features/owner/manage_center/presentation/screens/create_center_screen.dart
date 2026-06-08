/// Standalone create-center screen — a thin chrome wrapper (AppBar + SafeArea)
/// around the shared [CenterCreateWizard]. The primary first-run path is the
/// owner setup gate (`OwnerSetupScreen`), which hosts the same wizard; this
/// route remains for direct navigation. On success it pops back.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_palette.dart';
import '../widgets/center_create_wizard.dart';

/// Create-center screen.
class CreateCenterScreen extends StatelessWidget {
  /// Creates the create-center screen.
  const CreateCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          AppStrings.centerCreateTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
        ),
      ),
      // AppBar already titles the screen, so don't repeat the heading.
      body: SafeArea(
        child: CenterCreateWizard(
          showTitle: false,
          onCreated: () => context.pop(),
        ),
      ),
    );
  }
}
