/// Gradient + soft colored-orb background used by hero screens (auth, onboarding).
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_palette.dart';

/// A full-bleed atmospheric background composed of a soft diagonal gradient
/// plus up to three radial-gradient "orbs" in different brand colors.
///
/// The orbs are painted as `RadialGradient(orbColor → transparent)` containers
/// — soft auras at near-zero cost. We do **not** wrap orbs in [BackdropFilter];
/// the blur effect on glass surfaces is owned by [GlassPanel]. When a
/// `GlassPanel` sits over this backdrop its `BackdropFilter` re-blurs the
/// orb-tinted pixels behind it, producing the frosted aura that makes glass
/// read as glass.
///
/// Use [orbColors] to pick brand accents (e.g. all three role colors on
/// onboarding, or `[studentPrimary, studentPrimaryDark]` for auth). Only the
/// first three colors are used; pass an empty list to draw just the gradient.
/// [seed] tints the gradient; defaults to the first orb color or
/// [AppColors.studentPrimary].
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({
    super.key,
    required this.child,
    this.orbColors = const <Color>[],
    this.seed,
  });

  /// Foreground content painted over the backdrop.
  final Widget child;

  /// Up to three colors used as orb tints, in order: top-left, bottom-right,
  /// mid-right. Empty list → gradient only.
  final List<Color> orbColors;

  /// Color used to tint the diagonal gradient. Falls back to the first orb
  /// color, then [AppColors.studentPrimary].
  final Color? seed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color tintSeed = seed ??
        (orbColors.isNotEmpty ? orbColors.first : AppColors.studentPrimary);
    final List<Color> orbs = orbColors.take(3).toList();
    final double orbAlpha = isLight ? 0.35 : 0.18;

    return Stack(
      children: <Widget>[
        // 1) The diagonal gradient that sets the room temperature.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  palette.background,
                  Color.alphaBlend(
                    tintSeed.withValues(alpha: 0.10),
                    palette.background,
                  ),
                ],
              ),
            ),
          ),
        ),
        // 2) Up to three soft radial orbs in fixed positions.
        if (orbs.isNotEmpty)
          Positioned(
            top: -AppEffects.orbDiameter * 0.35,
            left: -AppEffects.orbDiameter * 0.25,
            child: _Orb(color: orbs[0], alpha: orbAlpha),
          ),
        if (orbs.length >= 2)
          Positioned(
            bottom: -AppEffects.orbDiameter * 0.30,
            right: -AppEffects.orbDiameter * 0.20,
            child: _Orb(color: orbs[1], alpha: orbAlpha),
          ),
        if (orbs.length >= 3)
          Positioned(
            top: AppEffects.orbDiameter * 0.50,
            right: -AppEffects.orbDiameter * 0.30,
            child: _Orb(color: orbs[2], alpha: orbAlpha * 0.85),
          ),
        // 3) Foreground.
        Positioned.fill(child: child),
      ],
    );
  }
}

/// A single soft radial orb. The radial gradient (color → transparent) is what
/// makes the orb feather at the edges — no [BackdropFilter] needed.
class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.alpha});

  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: AppEffects.orbDiameter,
        height: AppEffects.orbDiameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0.0),
            ],
            stops: const <double>[0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
