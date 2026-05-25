/// Brightness-aware semantic colour tokens, exposed as a [ThemeExtension].
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic, theme-aware colours for surfaces, text, borders, and the brand
/// foreground. Light values match the original fixed palette exactly (so light
/// mode is unchanged); dark values are the "Dim charcoal" set.
///
/// UI code reads these via the [BuildContextPalette.palette] extension - e.g.
/// `context.palette.surface` - so a single widget tree adapts to light and dark
/// automatically. Fixed brand / semantic colours that read well in both themes
/// (rating star, success, error, the solid brand fill behind white text, etc.)
/// continue to come straight from [AppColors].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.iconFaint,
    required this.inputFill,
    required this.primary,
    required this.primaryTint,
  });

  /// App / scaffold background (was `neutralGrey50`).
  final Color background;

  /// Card / sheet / elevated surface fill (was `neutralWhite`).
  final Color surface;

  /// Standard border / outline (was `neutralGrey200`).
  final Color border;

  /// Subtle border, divider, or neutral chip fill (was `neutralGrey100`).
  final Color borderSubtle;

  /// Primary text and headings (was `neutralBlack` / `neutralGrey900`).
  final Color textPrimary;

  /// Secondary text and standard icons (was `neutralGrey700`).
  final Color textSecondary;

  /// Muted / tertiary text and hints (was `neutralGrey500`).
  final Color textMuted;

  /// Faint decorative icons - chevrons, trailing glyphs (was `neutralGrey300`).
  final Color iconFaint;

  /// Auth form input background (was `inputFill`).
  final Color inputFill;

  /// Brand colour used as a foreground (text / icon / border). Lightened in
  /// dark mode for contrast (was `studentPrimary` when used as a foreground).
  final Color primary;

  /// Tinted brand fill behind [primary] foregrounds - badges, avatars
  /// (was `studentPrimaryTint`).
  final Color primaryTint;

  /// Light palette - identical to the original fixed colours.
  static const AppPalette light = AppPalette(
    background: AppColors.neutralGrey50,
    surface: AppColors.neutralWhite,
    border: AppColors.neutralGrey200,
    borderSubtle: AppColors.neutralGrey100,
    textPrimary: AppColors.neutralBlack,
    textSecondary: AppColors.neutralGrey700,
    textMuted: AppColors.neutralGrey500,
    iconFaint: AppColors.neutralGrey300,
    inputFill: AppColors.inputFill,
    primary: AppColors.studentPrimary,
    primaryTint: AppColors.studentPrimaryTint,
  );

  /// Dark palette - the "Dim charcoal" set.
  static const AppPalette dark = AppPalette(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    border: AppColors.darkBorder,
    borderSubtle: AppColors.darkBorderSubtle,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    iconFaint: AppColors.darkIconFaint,
    inputFill: AppColors.darkInputFill,
    primary: AppColors.darkPrimary,
    primaryTint: AppColors.darkPrimaryTint,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? iconFaint,
    Color? inputFill,
    Color? primary,
    Color? primaryTint,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      iconFaint: iconFaint ?? this.iconFaint,
      inputFill: inputFill ?? this.inputFill,
      primary: primary ?? this.primary,
      primaryTint: primaryTint ?? this.primaryTint,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      iconFaint: Color.lerp(iconFaint, other.iconFaint, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
    );
  }
}

/// Ergonomic access to the active [AppPalette]: `context.palette.surface`.
extension BuildContextPalette on BuildContext {
  /// The [AppPalette] registered on the current theme.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
