/// All TextStyle constants - display, headline, title, body, label, caption.
library;

import 'package:flutter/material.dart';

/// Application text-style tokens. Mirrors the Material 3 type scale.
///
/// `fontFamily` is intentionally left `null` so Flutter falls back to Roboto on
/// Android and the platform default sans-serif on iOS (see decision 0004).
abstract final class AppTextStyles {
  AppTextStyles._();

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    height: 1.12,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    height: 1.16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    height: 1.22,
    fontWeight: FontWeight.w400,
  );

  // Headline
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    height: 1.29,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );

  // Title
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    height: 1.27,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.15,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.15,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.33,
    letterSpacing: 0.4,
    fontWeight: FontWeight.w400,
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    height: 1.33,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    height: 1.45,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
  );

  // Convenience alias
  static const TextStyle caption = bodySmall;
}
