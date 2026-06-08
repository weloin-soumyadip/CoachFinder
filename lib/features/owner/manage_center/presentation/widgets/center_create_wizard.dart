/// Three-step create-coaching-center wizard, wired to `POST /api/centers` via
/// [createCenterControllerProvider]. A [CenterStepIndicator] sits at the top;
/// the steps are Basics → Location & contact → Review & create. Used by the
/// owner setup gate (first run) and the standalone [CreateCenterScreen].
///
/// Returns the full scrollable layout (capped + centered) so callers only need
/// to provide a Scaffold / SafeArea around it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../auth/presentation/auth_validators.dart';
import '../../data/controllers/create_center_provider.dart';
import '../../data/models/center_create_request.dart';
import 'center_step_indicator.dart';

/// The number of wizard steps.
const int _stepCount = 3;

/// The create-center wizard.
class CenterCreateWizard extends HookConsumerWidget {
  /// Creates the wizard. [onCreated] fires after a successful create (the gate
  /// forwards to the dashboard; the standalone screen pops). [showTitle] renders
  /// the heading above the stepper — omit it when an AppBar already titles the
  /// screen.
  const CenterCreateWizard({
    super.key,
    required this.onCreated,
    this.showTitle = true,
  });

  /// Called once the center is created successfully.
  final VoidCallback onCreated;

  /// Whether to show the title heading above the stepper.
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final ValueNotifier<int> step = useState<int>(0);

    final TextEditingController nameC = useTextEditingController();
    final TextEditingController descriptionC = useTextEditingController();
    final TextEditingController addressC = useTextEditingController();
    final TextEditingController cityC = useTextEditingController();
    final TextEditingController stateC = useTextEditingController();
    final TextEditingController pincodeC = useTextEditingController();
    final TextEditingController phoneC = useTextEditingController();

    final CreateCenterState createState =
        ref.watch(createCenterControllerProvider);
    final bool submitting = createState.isSubmitting;

    void goNext() {
      // Validate only the mounted (current) step's fields before advancing.
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (step.value < _stepCount - 1) step.value++;
    }

    void goBack() {
      if (step.value > 0) step.value--;
    }

    Future<void> create() async {
      final CenterCreateRequest request = CenterCreateRequest(
        name: nameC.text.trim(),
        phone: phoneC.text.trim(),
        address: addressC.text.trim(),
        city: cityC.text.trim(),
        state: stateC.text.trim(),
        pincode: pincodeC.text.trim(),
        description: descriptionC.text.trim(),
      );
      final bool ok = await ref
          .read(createCenterControllerProvider.notifier)
          .submit(request);
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.centerCreatedSnack)),
          );
        onCreated();
      } else {
        final String message =
            ref.read(createCenterControllerProvider).errorMessage ??
                AppStrings.centerCreateError;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }

    final String stepTitle = switch (step.value) {
      0 => AppStrings.centerWizardStepBasics,
      1 => AppStrings.centerWizardStepLocation,
      _ => AppStrings.centerWizardStepReview,
    };

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sp16,
            AppSpacing.sp16,
            AppSpacing.sp16,
            AppSpacing.sp32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showTitle) ...<Widget>[
                Text(
                  AppStrings.centerCreateTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp8),
                Text(
                  AppStrings.centerCreateIntro,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp24),
              ],
              // The step indicator sits at the top of the screen.
              CenterStepIndicator(
                  currentStep: step.value, stepCount: _stepCount),
              const SizedBox(height: AppSpacing.sp16),
              Text(
                stepTitle,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sp16),
              // Each step's fields live in their own Form so validation only
              // touches the mounted step.
              Form(
                key: formKey,
                child: _StepContent(
                  step: step.value,
                  nameC: nameC,
                  descriptionC: descriptionC,
                  addressC: addressC,
                  cityC: cityC,
                  stateC: stateC,
                  pincodeC: pincodeC,
                  phoneC: phoneC,
                ),
              ),
              const SizedBox(height: AppSpacing.sp24),
              _NavButtons(
                step: step.value,
                stepCount: _stepCount,
                submitting: submitting,
                onBack: goBack,
                onNext: goNext,
                onCreate: create,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The fields for the current [step].
class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.step,
    required this.nameC,
    required this.descriptionC,
    required this.addressC,
    required this.cityC,
    required this.stateC,
    required this.pincodeC,
    required this.phoneC,
  });

  final int step;
  final TextEditingController nameC;
  final TextEditingController descriptionC;
  final TextEditingController addressC;
  final TextEditingController cityC;
  final TextEditingController stateC;
  final TextEditingController pincodeC;
  final TextEditingController phoneC;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Field(
              label: AppStrings.centerFieldName,
              controller: nameC,
              validator: AuthValidators.notEmpty,
            ),
            _Field(
              label: AppStrings.centerCreateFieldDescription,
              controller: descriptionC,
              maxLines: 4,
              helperText: AppStrings.centerCreateFieldDescriptionHint,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Field(
              label: AppStrings.centerFieldAddress,
              controller: addressC,
              maxLines: 2,
              validator: AuthValidators.notEmpty,
            ),
            _Field(
              label: AppStrings.centerCreateFieldCity,
              controller: cityC,
              validator: AuthValidators.notEmpty,
            ),
            _Field(
              label: AppStrings.centerCreateFieldState,
              controller: stateC,
              validator: AuthValidators.notEmpty,
            ),
            _Field(
              label: AppStrings.centerCreateFieldPincode,
              controller: pincodeC,
              keyboardType: TextInputType.number,
              validator: AuthValidators.notEmpty,
            ),
            _Field(
              label: AppStrings.centerFieldPhone,
              controller: phoneC,
              keyboardType: TextInputType.phone,
              validator: AuthValidators.phone,
            ),
          ],
        );
      default:
        return _ReviewList(
          nameC: nameC,
          descriptionC: descriptionC,
          addressC: addressC,
          cityC: cityC,
          stateC: stateC,
          pincodeC: pincodeC,
          phoneC: phoneC,
        );
    }
  }
}

/// The review-step summary of everything entered.
class _ReviewList extends StatelessWidget {
  const _ReviewList({
    required this.nameC,
    required this.descriptionC,
    required this.addressC,
    required this.cityC,
    required this.stateC,
    required this.pincodeC,
    required this.phoneC,
  });

  final TextEditingController nameC;
  final TextEditingController descriptionC;
  final TextEditingController addressC;
  final TextEditingController cityC;
  final TextEditingController stateC;
  final TextEditingController pincodeC;
  final TextEditingController phoneC;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          AppStrings.centerWizardReviewHint,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: AppSpacing.sp16),
        _ReviewRow(label: AppStrings.centerFieldName, value: nameC.text),
        _ReviewRow(
          label: AppStrings.centerCreateFieldDescription,
          value: descriptionC.text,
        ),
        _ReviewRow(label: AppStrings.centerFieldAddress, value: addressC.text),
        _ReviewRow(label: AppStrings.centerCreateFieldCity, value: cityC.text),
        _ReviewRow(
            label: AppStrings.centerCreateFieldState, value: stateC.text),
        _ReviewRow(
          label: AppStrings.centerCreateFieldPincode,
          value: pincodeC.text,
        ),
        _ReviewRow(label: AppStrings.centerFieldPhone, value: phoneC.text),
      ],
    );
  }
}

/// A label / value row in the review step. Falls back to "Not provided" for an
/// empty optional value.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final String trimmed = value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            trimmed.isEmpty ? AppStrings.centerWizardNotProvided : trimmed,
            style: textTheme.bodyLarge?.copyWith(
              color: trimmed.isEmpty ? palette.textMuted : palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Back / Next / Create button row. Step 0 shows only the primary button.
class _NavButtons extends StatelessWidget {
  const _NavButtons({
    required this.step,
    required this.stepCount,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.onCreate,
  });

  final int step;
  final int stepCount;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool isLast = step == stepCount - 1;

    final Widget primary = FilledButton(
      onPressed: submitting ? null : (isLast ? () => onCreate() : onNext),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ownerAccent,
        foregroundColor: AppColors.neutralWhite,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sp12),
        ),
      ),
      child: submitting
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.neutralWhite,
              ),
            )
          : Text(
              isLast
                  ? AppStrings.centerCreateSubmit
                  : AppStrings.centerWizardNext,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    );

    if (step == 0) return primary;

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: submitting ? null : onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.textPrimary,
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: palette.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sp12),
              ),
            ),
            child: const Text(
              AppStrings.centerWizardBack,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sp12),
        Expanded(child: primary),
      ],
    );
  }
}

/// A labelled text field used across the wizard steps.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: palette.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.inputFill,
              helperText: helperText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp16,
                vertical: AppSpacing.sp12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sp12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
