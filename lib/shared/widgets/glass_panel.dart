/// Frosted-glass surface — clipped BackdropFilter + translucent fill.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_effects.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// A frosted-glass shelf for framing content over a colored / blurred backdrop.
///
/// Order of operations is intentional: `ClipRRect` first → `BackdropFilter`
/// second → translucent fill third. Without the outer `ClipRRect`, blur leaks
/// past the radius and the corners look ragged.
///
/// **Perf:** [BackdropFilter] is GPU-heavy. Prefer one large `GlassPanel` over
/// many small ones, and **never** put a `GlassPanel` inside a `ListView.builder`
/// item — every scroll frame triggers a fresh blur and the app stutters. Glass
/// is for outer chrome, not list rows.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.sp24),
    this.radius = AppSpacing.sp24,
    this.blur = AppEffects.glassBlur,
  });

  /// Foreground content painted inside the glass.
  final Widget child;

  /// Padding between the glass edge and [child].
  final EdgeInsets padding;

  /// Corner radius in logical pixels.
  final double radius;

  /// `BackdropFilter` blur sigma. Defaults to [AppEffects.glassBlur].
  final double blur;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: palette.glassFill,
            borderRadius: borderRadius,
            border: Border.all(color: palette.glassBorder),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
