/// Themed input field used by the auth forms — transparent on glass.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';

/// A Material 3 `TextFormField` with a subtle accent-tinted fill ([accent] at
/// 6 % alpha) so the underlying [GlassPanel] still shows through while the
/// field reads as part of the role's brand. A hairline `palette.borderSubtle`
/// outline marks the field at rest; the outline + floating label tween to
/// [accent] (defaults to `context.palette.primary`) when the field is focused.
///
/// Pass a [validator] (runs when the enclosing `Form` is validated); for
/// password inputs pass `obscureText: true` and use [trailing] for the
/// visibility-toggle button.
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color brand = accent ?? palette.primary;
    final BorderRadius radius = BorderRadius.circular(AppSpacing.sp12);

    OutlineInputBorder outline(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: textTheme.bodyLarge?.copyWith(color: palette.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodyLarge?.copyWith(color: palette.textMuted),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(
          color: brand,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        filled: true,
        fillColor: brand.withValues(alpha: 0.06),
        prefixIcon: Icon(icon, color: palette.textMuted, size: 20),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp12,
          vertical: AppSpacing.sp16,
        ),
        border: outline(palette.borderSubtle),
        enabledBorder: outline(palette.borderSubtle),
        focusedBorder: outline(brand, width: 1.5),
        errorBorder: outline(palette.border),
        focusedErrorBorder: outline(brand, width: 1.5),
      ),
    );
  }
}
