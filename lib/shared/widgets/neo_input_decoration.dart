/// InputDecoration helper that pairs with a NeoSurface(inset: true) wrapper.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// Returns an [InputDecoration] tuned for a neo "recessed well" text field.
/// The decoration is **borderless and unfilled** — the visual surface (fill +
/// hairline border) is supplied by a surrounding [NeoSurface] with `inset: true`.
///
/// Pass [label] for the floating M3 label, [icon] for the leading icon,
/// [hint] for placeholder text, and [suffix] for the trailing visibility / clear
/// button.
InputDecoration neoInputDecoration({
  required BuildContext context,
  required String label,
  required IconData icon,
  String? hint,
  Widget? suffix,
}) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  final palette = context.palette;
  return InputDecoration(
    labelText: label,
    labelStyle: textTheme.bodyLarge?.copyWith(color: palette.textMuted),
    floatingLabelStyle: textTheme.labelLarge?.copyWith(
      color: palette.primary,
      fontWeight: FontWeight.w600,
    ),
    hintText: hint,
    hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
    filled: false,
    isDense: false,
    prefixIcon: Icon(icon, color: palette.textMuted, size: 20),
    suffixIcon: suffix,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sp4,
      vertical: AppSpacing.sp12,
    ),
  );
}
