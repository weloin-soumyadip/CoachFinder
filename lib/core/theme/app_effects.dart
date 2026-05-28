/// Fixed motion / blur / shadow numerics shared across the neoglass primitives.
library;

import 'package:flutter/material.dart';

/// Geometric (non-color) tokens for the neoglass design system. Pure numerics
/// stay here so [AppColors] / [AppPalette] don't grow with motion knobs.
abstract final class AppEffects {
  AppEffects._();

  /// Default `BackdropFilter` sigma for [GlassPanel]. Calibrated for the
  /// "soft & premium" intensity — heavier blur reads as 2020 skeumorphism.
  static const double glassBlur = 24;

  /// Stronger blur for hero overlays / future modal sheets.
  static const double glassBlurStrong = 36;

  /// Bottom-right "weight" shadow offset on outset neo surfaces.
  static const Offset neoOutsetOffsetDark = Offset(6, 6);

  /// Top-left "light" highlight offset on outset neo surfaces.
  static const Offset neoOutsetOffsetLight = Offset(-6, -6);

  /// Outset shadow blur radius.
  static const double neoOutsetBlur = 18;

  /// Top-left "dark" shadow offset on inset (recessed) neo surfaces.
  static const Offset neoInsetOffsetDark = Offset(-4, -4);

  /// Bottom-right "light" highlight offset on inset (recessed) neo surfaces.
  static const Offset neoInsetOffsetLight = Offset(4, 4);

  /// Inset shadow blur radius.
  static const double neoInsetBlur = 12;

  /// Animation duration for [NeoButton] press feedback.
  static const Duration neoPressDuration = Duration(milliseconds: 220);

  /// Diameter of decorative backdrop orbs.
  static const double orbDiameter = 320;
}
