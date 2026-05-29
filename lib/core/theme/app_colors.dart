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

  /// Darker shade of [studentPrimary] - the second stop of the auth hero
  /// gradient (brand element; white-on-blue reads in both themes).
  static const Color studentPrimaryDark = Color(0xFF1444A8);

  /// Soft neutral fill used for form input backgrounds in the auth flow.
  static const Color inputFill = Color(0xFFEEF1F6);

  /// Selected-tab indicator colour on the bottom NavigationBar.
  static const Color navIndicator = Color(0xFFC5E8C8);

  /// "Per hour" price text colour on coach cards.
  static const Color priceGreen = Color(0xFF2E7D4F);

  /// Rating star colour.
  static const Color ratingStar = Color(0xFFFFB400);

  /// Accent colour used by the coaching-owner experience.
  static const Color ownerAccent = Color(0xFFE05A2B);

  /// Accent colour used by the teacher experience.
  static const Color teacherAccent = Color(0xFF0D9488);

  /// Light tint of [teacherAccent], used for icon-chip backgrounds.
  static const Color teacherAccentTint = Color(0xFFCCFBF1);

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

  // Dark-theme neutrals ("Dim charcoal"). These are the dark counterparts of
  // the light neutrals above and are consumed only by [AppPalette.dark] - UI
  // code reads brightness-aware tokens via `context.palette`, never these
  // directly.
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF1A1D23);
  static const Color darkBorder = Color(0xFF2A2F38);
  static const Color darkBorderSubtle = Color(0xFF21252C);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFFC7CDD6);
  static const Color darkTextMuted = Color(0xFF9CA3AF);
  static const Color darkIconFaint = Color(0xFF4B5563);
  static const Color darkInputFill = Color(0xFF21252C);

  /// Brand blue lightened for legibility as a foreground on dark surfaces.
  static const Color darkPrimary = Color(0xFF7AA2F7);

  /// Dark counterpart of [studentPrimaryTint] (badge / avatar fills).
  static const Color darkPrimaryTint = Color(0xFF25304A);
}
