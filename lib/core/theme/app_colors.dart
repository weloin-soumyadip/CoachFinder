/// Centralised colour tokens - brand, accent, semantic, and neutral.
library;

import 'package:flutter/material.dart';

/// Application colour palette. All colours used in the UI MUST come from this
/// file - no hard-coded hex literals anywhere else in the codebase.
abstract final class AppColors {
  AppColors._();

  /// Primary brand colour for the student experience.
  static const Color studentPrimary = Color(0xFF1A56DB);

  /// Light tint of [studentPrimary], used for icon-chip backgrounds.
  static const Color studentPrimaryTint = Color(0xFFE3EBFC);

  /// Soft neutral fill used for form input backgrounds in the auth flow.
  static const Color inputFill = Color(0xFFEEF1F6);

  /// Accent colour used by the coaching-owner experience.
  static const Color ownerAccent = Color(0xFFE05A2B);

  /// High-emphasis call-to-action colour (call, enquire).
  static const Color ctaAmber = Color(0xFFF59E0B);

  // Neutrals
  static const Color neutralBlack = Color(0xFF111827);
  static const Color neutralGrey900 = Color(0xFF1F2937);
  static const Color neutralGrey700 = Color(0xFF374151);
  static const Color neutralGrey500 = Color(0xFF6B7280);
  static const Color neutralGrey300 = Color(0xFFD1D5DB);
  static const Color neutralGrey200 = Color(0xFFE5E7EB);
  static const Color neutralGrey100 = Color(0xFFF3F4F6);
  static const Color neutralGrey50 = Color(0xFFF9FAFB);
  static const Color neutralWhite = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
