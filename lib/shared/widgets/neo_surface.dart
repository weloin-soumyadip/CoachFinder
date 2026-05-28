/// Outset / inset neomorphic surface for the soft-and-premium design system.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_effects.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// A soft neomorphic surface — outset (lifted off the page) by default, or
/// inset (recessed) via [inset]. Calibrated for the "soft & premium" intensity:
/// subtle dual shadows on outset, a darker fill + hairline border on inset.
///
/// In dark mode the "light" outset shadow is intentionally near-invisible —
/// there is no real light source to fake — so a 1 px [AppPalette.borderSubtle]
/// edge is added for definition. Inset variants always carry the hairline so
/// the recessed feel reads in both themes (the project's Flutter doesn't
/// support `BoxShadow(inset: true)`, so we lean on the darker [AppPalette.inputFill]
/// background + border instead of drawing inverse shadows).
///
/// The outer fill defaults to [AppPalette.surface] (or [AppPalette.inputFill]
/// for the inset variant); pass [fill] to override (e.g. an accent fill for an
/// embossed brand badge).
class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.sp16),
    this.radius = AppSpacing.sp16,
    this.inset = false,
    this.fill,
  });

  /// Foreground content painted inside the surface.
  final Widget child;

  /// Padding between the surface edge and [child].
  final EdgeInsets padding;

  /// Corner radius in logical pixels.
  final double radius;

  /// When `true`, the surface uses the recessed-well treatment: darker
  /// [AppPalette.inputFill] background + hairline border + no drop shadows.
  /// Used behind text fields.
  final bool inset;

  /// Override fill color. Defaults to [AppPalette.surface] (outset) or
  /// [AppPalette.inputFill] (inset).
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background =
        fill ?? (inset ? palette.inputFill : palette.surface);

    final List<BoxShadow>? shadows = inset
        ? null
        : <BoxShadow>[
            BoxShadow(
              color: palette.neoShadowDark,
              offset: AppEffects.neoOutsetOffsetDark,
              blurRadius: AppEffects.neoOutsetBlur,
            ),
            BoxShadow(
              color: palette.neoShadowLight,
              offset: AppEffects.neoOutsetOffsetLight,
              blurRadius: AppEffects.neoOutsetBlur,
            ),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
        border:
            (isDark || inset) ? Border.all(color: palette.borderSubtle) : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
