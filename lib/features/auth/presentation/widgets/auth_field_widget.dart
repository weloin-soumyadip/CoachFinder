/// Themed input field used by the auth forms — neo "recessed well" styling.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/neo_input_decoration.dart';
import '../../../../shared/widgets/neo_surface.dart';

/// A Material 3 `TextFormField` styled as a recessed neo well: the field sits
/// inside a [NeoSurface] with `inset: true` so it reads as pressed-into the
/// page. Pass a [validator] (runs when the enclosing `Form` is validated); for
/// password inputs pass `obscureText: true` and use [trailing] for the
/// visibility-toggle button. [accent] colors the floating label when the
/// field is focused; defaults to `context.palette.primary`.
class AuthFieldWidget extends StatelessWidget {
  const AuthFieldWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.trailing,
    this.validator,
    this.accent,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? trailing;
  final String? Function(String?)? validator;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return NeoSurface(
      inset: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp4),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: palette.textPrimary),
        decoration: neoInputDecoration(
          context: context,
          label: label,
          icon: icon,
          hint: hint,
          suffix: trailing,
          accent: accent,
        ),
      ),
    );
  }
}
