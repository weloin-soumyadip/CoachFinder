/// Themed input field used by login and register forms.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';

/// Themed text input used by the auth screens.
///
/// Layout: a label row above the field, then a soft-filled rounded text field
/// with a leading [icon]. For password inputs pass `obscureText: true` and use
/// [trailing] to embed the visibility-toggle button. The label row can carry
/// a right-aligned widget via [labelTrailing] (used for "Forgot Password?").
class AuthFieldWidget extends StatelessWidget {
  const AuthFieldWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.trailing,
    this.labelTrailing,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final Widget? labelTrailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final radius = BorderRadius.circular(AppSpacing.sp12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (labelTrailing != null) ...<Widget>[
              const Spacer(),
              labelTrailing!,
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sp8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: textTheme.bodyLarge?.copyWith(color: palette.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.inputFill,
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            prefixIcon: Icon(icon, color: palette.textMuted, size: 20),
            suffixIcon: trailing,
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: palette.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp16,
              vertical: AppSpacing.sp16,
            ),
          ),
        ),
      ],
    );
  }
}
