# Neoglass Design System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pivot CoachFinder's flat design system to a hybrid neomorphism + glassmorphism look — round 1 = update the `flutter-ui` skill and restyle onboarding + the three auth screens as a showcase.

**Architecture:** Add 4 brightness-aware palette tokens + 1 numerics file. Build 4 small Flutter widgets (`BrandBackdrop`, `GlassPanel`, `NeoSurface`, `NeoButton`) + 1 helper (`neoInputDecoration`). Refactor `AuthFieldWidget` / `AuthPrimaryButton` / `AuthOAuthButton` to delegate to the new primitives without changing their public APIs. Restyle four screens to use the new primitives over a `BrandBackdrop`. Rewrite the `flutter-ui` skill so future UI follows the new rule "**Glass surrounds, neo presses.**"

**Tech Stack:** Flutter (Material 3), `flutter_hooks`, `hooks_riverpod`, existing `AppPalette` / `AppColors` / `AppSpacing` tokens. No new packages. `BackdropFilter` + `ImageFilter.blur` ship in Flutter core.

**Source spec:** `docs/superpowers/specs/2026-05-28-neoglass-design-system-design.md`

---

## File structure

**New files:**
- `lib/core/theme/app_effects.dart` — motion/blur/shadow numeric tokens
- `lib/shared/widgets/brand_backdrop.dart` — gradient + colored orbs background
- `lib/shared/widgets/glass_panel.dart` — frosted blur surface
- `lib/shared/widgets/neo_surface.dart` — outset/inset shadow surface
- `lib/shared/widgets/neo_button.dart` — pressable neo affordance
- `lib/shared/widgets/neo_input_decoration.dart` — InputDecoration helper for neo fields
- `decisions/0028-neoglass-design-system.md` — ADR for this round

**Modified files:**
- `lib/core/theme/app_palette.dart` — add `neoShadowDark`, `neoShadowLight`, `glassFill`, `glassBorder` (+ lerp + copyWith)
- `lib/features/auth/presentation/widgets/auth_field_widget.dart` — wrap field in `NeoSurface(inset: true)`
- `lib/features/auth/presentation/widgets/auth_widgets.dart` — `AuthPrimaryButton` / `AuthOAuthButton` delegate to `NeoButton`
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` — backdrop + glass shelf + neo tiles + neo CTA
- `lib/features/auth/presentation/screens/login_screen.dart` — backdrop + glass form + glass OAuth row
- `lib/features/auth/presentation/screens/register_screen.dart` — backdrop + glass form + glass OAuth row
- `lib/features/auth/presentation/screens/forgot_password_screen.dart` — backdrop + glass form
- `.claude/skills/flutter-ui/SKILL.md` — rewrite aesthetic + patterns sections

**Conventions reminder:**
- Every class + public method gets a `///` doc comment.
- No hardcoded values — strings → `AppStrings`, colors → `context.palette.*` / `AppColors.*` / new palette tokens, sizes → `AppSpacing.*` / `AppEffects.*`.
- Screens are `HookConsumerWidget`; widgets that need hooks are `HookWidget`; everything else `StatelessWidget`.
- Each task ends with `flutter analyze` (must report *No issues found!*) and a commit.

---

## Task 1: Add `AppEffects` numerics

**Files:**
- Create: `lib/core/theme/app_effects.dart`

- [ ] **Step 1: Create the file**

```dart
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
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/core/theme/app_effects.dart && flutter analyze lib/core/theme/app_effects.dart
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_effects.dart
git commit -m "feat(theme): add AppEffects numerics for neoglass design system

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Add neoglass tokens to `AppPalette`

**Files:**
- Modify: `lib/core/theme/app_palette.dart`

- [ ] **Step 1: Add the four new fields, their constructor entries, light + dark values, plus lerp + copyWith entries**

Replace the entire file content with:

```dart
/// Brightness-aware semantic colour tokens, exposed as a [ThemeExtension].
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic, theme-aware colours for surfaces, text, borders, the brand
/// foreground, and the new neoglass effect tokens. Light values match the
/// original fixed palette exactly (so light mode is unchanged); dark values are
/// the "Dim charcoal" set with calibrated neoglass alphas.
///
/// UI code reads these via the [BuildContextPalette.palette] extension — e.g.
/// `context.palette.surface` — so a single widget tree adapts to light and dark
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
    required this.neoShadowDark,
    required this.neoShadowLight,
    required this.glassFill,
    required this.glassBorder,
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

  /// Faint decorative icons — chevrons, trailing glyphs (was `neutralGrey300`).
  final Color iconFaint;

  /// Auth form input background (was `inputFill`).
  final Color inputFill;

  /// Brand colour used as a foreground (text / icon / border). Lightened in
  /// dark mode for contrast (was `studentPrimary` when used as a foreground).
  final Color primary;

  /// Tinted brand fill behind [primary] foregrounds — badges, avatars
  /// (was `studentPrimaryTint`).
  final Color primaryTint;

  /// "Weight" shadow on outset neo surfaces (bottom-right). Calibrated soft.
  final Color neoShadowDark;

  /// "Light" highlight on outset neo surfaces (top-left). Intentionally faint
  /// in dark mode — there is no real light source to fake.
  final Color neoShadowLight;

  /// Translucent fill behind [GlassPanel]'s [BackdropFilter]. Lower alpha in
  /// dark mode so translucent reads as smoke, not milk.
  final Color glassFill;

  /// Hairline edge that catches the light on a glass panel.
  final Color glassBorder;

  /// Light palette — identical to the original fixed colours plus neoglass.
  static AppPalette get light => AppPalette(
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
        neoShadowDark: AppColors.neutralBlack.withValues(alpha: 0.08),
        neoShadowLight: AppColors.neutralWhite.withValues(alpha: 0.90),
        glassFill: AppColors.neutralWhite.withValues(alpha: 0.60),
        glassBorder: AppColors.neutralWhite.withValues(alpha: 0.60),
      );

  /// Dark palette — the "Dim charcoal" set plus neoglass dark calibration.
  static AppPalette get dark => AppPalette(
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
        neoShadowDark: AppColors.neutralBlack.withValues(alpha: 0.50),
        neoShadowLight: AppColors.darkSurface.withValues(alpha: 0.06),
        glassFill: AppColors.darkSurface.withValues(alpha: 0.24),
        glassBorder: AppColors.neutralWhite.withValues(alpha: 0.08),
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
    Color? neoShadowDark,
    Color? neoShadowLight,
    Color? glassFill,
    Color? glassBorder,
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
      neoShadowDark: neoShadowDark ?? this.neoShadowDark,
      neoShadowLight: neoShadowLight ?? this.neoShadowLight,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
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
      neoShadowDark: Color.lerp(neoShadowDark, other.neoShadowDark, t)!,
      neoShadowLight: Color.lerp(neoShadowLight, other.neoShadowLight, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

/// Ergonomic access to the active [AppPalette]: `context.palette.surface`.
extension BuildContextPalette on BuildContext {
  /// The [AppPalette] registered on the current theme.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
```

**Note:** `light` and `dark` are now `static get`-ters (not `const` fields) because the alpha-modified colors aren't compile-time constants. Any existing call site that uses `AppPalette.light` / `AppPalette.dark` continues to work — getters are interchangeable with fields at the call site.

- [ ] **Step 2: Verify `AppPalette.light` / `AppPalette.dark` aren't read in a `const` context anywhere**

```bash
grep -rn "AppPalette\.\(light\|dark\)" lib/ test/
```

Expected: All call sites use the values at runtime (e.g. passed into `ThemeData.copyWith` or `extensions`). If any usage is inside a `const` expression, replace with `final` or evaluate at runtime — the typical theme builder site is already runtime.

- [ ] **Step 3: Verify clean analyze**

```bash
dart format lib/core/theme/app_palette.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_palette.dart
git commit -m "feat(theme): add neoglass tokens to AppPalette (light + dark)

Adds neoShadowDark, neoShadowLight, glassFill, glassBorder with calibrated
soft-and-premium alphas. Light keeps the existing palette; dark uses lower
glass alpha so translucent reads as smoke not milk, and a near-invisible
'light' shadow because there is no real light source to fake.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Build `BrandBackdrop`

**Files:**
- Create: `lib/shared/widgets/brand_backdrop.dart`

- [ ] **Step 1: Create the file**

```dart
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
    final Color tintSeed =
        seed ?? (orbColors.isNotEmpty ? orbColors.first : AppColors.studentPrimary);
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
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/shared/widgets/brand_backdrop.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/brand_backdrop.dart
git commit -m "feat(ui): add BrandBackdrop (gradient + soft radial orbs)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Build `GlassPanel`

**Files:**
- Create: `lib/shared/widgets/glass_panel.dart`

- [ ] **Step 1: Create the file**

```dart
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
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/shared/widgets/glass_panel.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/glass_panel.dart
git commit -m "feat(ui): add GlassPanel (frosted blur surface)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Build `NeoSurface`

**Files:**
- Create: `lib/shared/widgets/neo_surface.dart`

- [ ] **Step 1: Create the file**

```dart
/// Outset / inset neomorphic surface for the soft-and-premium design system.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_effects.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// A soft neomorphic surface — outset (lifted off the page) by default, or
/// inset (recessed) via [inset]. Calibrated for the "soft & premium" intensity:
/// subtle shadows, no hard edges, accessible in both themes.
///
/// In dark mode the "light" shadow is intentionally near-invisible — there is
/// no real light source to fake — so a 1 px [AppPalette.borderSubtle] edge is
/// added for definition. This is handled automatically.
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

  /// When `true`, the shadows reverse to give a recessed "well" look. Used
  /// behind text fields and selected role tiles.
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

    final List<BoxShadow> shadows = inset
        ? <BoxShadow>[
            BoxShadow(
              color: palette.neoShadowDark,
              offset: AppEffects.neoInsetOffsetDark,
              blurRadius: AppEffects.neoInsetBlur,
              inset: true,
            ),
            BoxShadow(
              color: palette.neoShadowLight,
              offset: AppEffects.neoInsetOffsetLight,
              blurRadius: AppEffects.neoInsetBlur,
              inset: true,
            ),
          ]
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
        border: isDark
            ? Border.all(color: palette.borderSubtle)
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
```

**Note on `BoxShadow(inset: true)`:** Flutter's `BoxShadow` supports an `inset` flag as of recent stable versions. If `flutter analyze` complains that `inset` is not a parameter of `BoxShadow`, fall back to wrapping `DecoratedBox` with a custom painter — but try the simple form first, it should compile.

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/shared/widgets/neo_surface.dart && flutter analyze
```

Expected: *No issues found!*

If `BoxShadow.inset` is not recognized on this Flutter version, replace the inset shadow logic with a `CustomPaint` overlay (see fallback below) and re-verify. **Fallback for inset shadows** if needed:

```dart
// Replace the `inset` BoxShadow list with: an outset surface drawn underneath,
// plus a CustomPaint child that paints two inverted-direction shadows clipped
// to the rounded rect. Concretely:
//
//   return ClipRRect(
//     borderRadius: BorderRadius.circular(radius),
//     child: CustomPaint(
//       painter: _InsetShadowPainter(palette: palette, radius: radius),
//       child: Padding(padding: padding, child: child),
//     ),
//   );
//
// where _InsetShadowPainter paints two soft offset shadow circles clipped by
// the rounded rect. See https://github.com/flutter/flutter/issues/18636 for the
// canonical pattern. Only fall back to this if BoxShadow.inset truly isn't
// supported — current Flutter stable supports it.
```

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/neo_surface.dart
git commit -m "feat(ui): add NeoSurface (outset / inset soft neomorphic surface)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Build `NeoButton`

**Files:**
- Create: `lib/shared/widgets/neo_button.dart`

- [ ] **Step 1: Create the file**

```dart
/// Pressable neomorphic affordance — animates from outset to inset on press.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// A neomorphic, pressable surface that swaps from outset to inset shadows on
/// tap. Used for primary CTAs, role tiles, OAuth buttons, and any other "press
/// to act" affordance in the soft-and-premium design system.
///
/// - [filled] `true` → accent-fill primary (white label / icon, no "light"
///   shadow because the accent would clash with white).
/// - [filled] `false` → surface-fill secondary, label / icon coloured by
///   [accent] (defaults to `palette.primary`).
/// - [selected] true → starts in the inset state. Used by toggle-like tiles
///   (the onboarding role selector) where the press IS the selection signal.
///
/// Disable by passing `onPressed: null`.
class NeoButton extends HookWidget {
  const NeoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filled = false,
    this.accent,
    this.selected = false,
    this.height = 52,
    this.radius = AppSpacing.sp12,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
  });

  /// Tap handler. `null` disables the button.
  final VoidCallback? onPressed;

  /// Foreground content (typically a `Row` of icon + label, or just text).
  final Widget child;

  /// `true` → accent-fill primary. `false` → surface-fill secondary.
  final bool filled;

  /// Brand accent. Defaults to `context.palette.primary`.
  final Color? accent;

  /// Sticky inset (selected) state for toggle-like tiles.
  final bool selected;

  /// Tap-target height. Default 52 (matches existing auth buttons).
  final double height;

  /// Corner radius. Default [AppSpacing.sp12].
  final double radius;

  /// Horizontal padding around [child].
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color brand = accent ?? palette.primary;
    final ValueNotifier<bool> pressed = useState<bool>(false);
    final bool enabled = onPressed != null;
    final bool inset = selected || pressed.value;

    final Color background = filled
        ? (enabled ? brand : palette.border)
        : (selected ? brand.withValues(alpha: 0.08) : palette.surface);

    final List<BoxShadow> shadows = inset
        ? <BoxShadow>[
            BoxShadow(
              color: palette.neoShadowDark,
              offset: AppEffects.neoInsetOffsetDark,
              blurRadius: AppEffects.neoInsetBlur,
              inset: true,
            ),
            if (!filled)
              BoxShadow(
                color: palette.neoShadowLight,
                offset: AppEffects.neoInsetOffsetLight,
                blurRadius: AppEffects.neoInsetBlur,
                inset: true,
              ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: palette.neoShadowDark,
              offset: AppEffects.neoOutsetOffsetDark,
              blurRadius: AppEffects.neoOutsetBlur,
            ),
            if (!filled)
              BoxShadow(
                color: palette.neoShadowLight,
                offset: AppEffects.neoOutsetOffsetLight,
                blurRadius: AppEffects.neoOutsetBlur,
              ),
          ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => pressed.value = true : null,
      onTapUp: enabled ? (_) => pressed.value = false : null,
      onTapCancel: enabled ? () => pressed.value = false : null,
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: AppEffects.neoPressDuration,
        curve: Curves.easeOut,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadows,
          border: isDark && !filled
              ? Border.all(color: palette.borderSubtle)
              : null,
        ),
        child: Center(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: filled
                  ? (enabled ? AppColors.neutralWhite : palette.textMuted)
                  : brand,
              fontWeight: FontWeight.w700,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: filled ? AppColors.neutralWhite : brand,
                size: 20,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/shared/widgets/neo_button.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/neo_button.dart
git commit -m "feat(ui): add NeoButton (pressable neomorphic affordance)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Build `neoInputDecoration` helper

**Files:**
- Create: `lib/shared/widgets/neo_input_decoration.dart`

- [ ] **Step 1: Create the file**

```dart
/// InputDecoration helper that pairs with a NeoSurface(inset: true) wrapper.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// Returns an [InputDecoration] tuned for a neo "recessed well" text field.
/// The decoration is **borderless and unfilled** — the visual surface (fill +
/// inset shadows) is supplied by a surrounding [NeoSurface] with `inset: true`.
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
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/shared/widgets/neo_input_decoration.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/neo_input_decoration.dart
git commit -m "feat(ui): add neoInputDecoration helper for neo text fields

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Refactor `AuthFieldWidget` over `NeoSurface(inset)` + `neoInputDecoration`

**Files:**
- Modify: `lib/features/auth/presentation/widgets/auth_field_widget.dart`

The public API of `AuthFieldWidget` does not change. Only its internal `build` method is replaced.

- [ ] **Step 1: Replace the file contents**

```dart
/// Themed input field used by the auth forms — neo "recessed well" styling.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/neo_input_decoration.dart';
import '../../../../shared/widgets/neo_surface.dart';

/// A Material 3 `TextFormField` styled as a recessed neo well: the field sits
/// inside a [NeoSurface] with `inset: true` so it reads as pressed-into the
/// page. Pass a [validator] (runs when the enclosing `Form` is validated); for
/// password inputs pass `obscureText: true` and use [trailing] for the
/// visibility-toggle button.
class AuthFieldWidget extends StatelessWidget {
  const AuthFieldWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.trailing,
    this.validator,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? trailing;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return NeoSurface(
      inset: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: palette.textPrimary),
        decoration: neoInputDecoration(
          context: context,
          label: label,
          icon: icon,
          hint: hint,
          suffix: trailing,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/features/auth/presentation/widgets/auth_field_widget.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/widgets/auth_field_widget.dart
git commit -m "feat(auth): re-style AuthFieldWidget as a neo recessed well

Public constructor parameters unchanged; only the internal build is replaced
with NeoSurface(inset: true) + neoInputDecoration. Call sites in login,
register, and forgot password are unaffected.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Refactor `AuthPrimaryButton` + `AuthOAuthButton` over `NeoButton`

**Files:**
- Modify: `lib/features/auth/presentation/widgets/auth_widgets.dart`

Both buttons' public APIs (constructor parameters) are preserved. `AuthOrDivider` and `AuthBottomLink` are unchanged.

- [ ] **Step 1: Replace the file contents**

```dart
/// Shared widgets used by the login, register, and forgot-password screens.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/neo_button.dart';

/// Full-width filled primary CTA with an optional trailing icon, styled as a
/// neo primary button on the brand fill.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return NeoButton(
      onPressed: onPressed,
      filled: true,
      accent: AppColors.studentPrimary,
      height: 52,
      radius: AppSpacing.sp12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.neutralWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailingIcon != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sp8),
            Icon(trailingIcon, size: 18, color: AppColors.neutralWhite),
          ],
        ],
      ),
    );
  }
}

/// Full-width social-auth button (Google / Facebook), styled as a neo
/// secondary button on the surface fill.
class AuthOAuthButton extends StatelessWidget {
  const AuthOAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return NeoButton(
      onPressed: onPressed,
      filled: false,
      accent: palette.textPrimary,
      height: 52,
      radius: AppSpacing.sp12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 20, color: palette.textPrimary),
          const SizedBox(width: AppSpacing.sp8),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal divider with centred text — "Or".
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: palette.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12),
          child: Text(
            text,
            style: textTheme.labelMedium?.copyWith(color: palette.textMuted),
          ),
        ),
        Expanded(child: Divider(color: palette.border)),
      ],
    );
  }
}

/// Footer link — `prefix` text followed by a blue tappable `actionLabel`.
class AuthBottomLink extends StatelessWidget {
  const AuthBottomLink({
    super.key,
    required this.prefix,
    required this.actionLabel,
    required this.onAction,
  });

  final String prefix;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          prefix,
          style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sp4),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/features/auth/presentation/widgets/auth_widgets.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/widgets/auth_widgets.dart
git commit -m "feat(auth): re-style AuthPrimaryButton/AuthOAuthButton over NeoButton

Public APIs preserved; the buttons now use the neoglass NeoButton primitive
so press feedback is consistent with role tiles and future controls.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Re-style Login screen

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`

- [ ] **Step 1: Replace the file contents**

The form (inputs + remember/forgot row + Sign In + debug hint) goes inside one `GlassPanel`; the OAuth row goes inside a second, shorter `GlassPanel`; everything sits on a `BrandBackdrop`. Title/subtitle/AuthBottomLink remain on the open backdrop.

```dart
/// Sign In screen consuming authProvider.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/dev_credentials.dart';
import '../../../../core/constants/hive_keys.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/hive_service_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_backdrop.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../auth_validators.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Sign In screen.
///
/// The form validates on submit (email format + 8-char password). Phase 1: a
/// `kDebugMode` test credential ([DevCredentials]) signs in and lands on the
/// role-appropriate shell; any other input shows an error, and release builds
/// disable the bypass. [initialRole] arrives from onboarding via GoRouter
/// `extra`. The "Remember for 30 days" toggle and social buttons are local /
/// stubbed until the backend auth contract lands.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final passwordVisible = useState(false);
    final rememberMe = useState(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> handleSignIn() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final email = emailCtrl.text.trim().toLowerCase();
      final password = passwordCtrl.text;
      final isTestUser = kDebugMode &&
          email == DevCredentials.testEmail &&
          password == DevCredentials.testPassword;
      if (!isTestUser) {
        stub(kDebugMode
            ? AppStrings.loginInvalidCredentials
            : AppStrings.stubAuthNotImplemented);
        return;
      }
      final hive = ref.read(hiveServiceProvider);
      await hive.authBox.put(HiveKeys.keyJwtToken, 'phase1-dev-token');
      final role = ref.read(roleProvider) ?? initialRole ?? roleStudent;
      if (!context.mounted) return;
      context.goNamed(landingRouteForRole(role));
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[
          AppColors.studentPrimary,
          AppColors.studentPrimaryDark,
        ],
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp24,
                  AppSpacing.sp32,
                  AppSpacing.sp24,
                  AppSpacing.sp32,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        AppStrings.loginTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp8),
                      Text(
                        AppStrings.loginSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            AuthFieldWidget(
                              label: AppStrings.fieldEmail,
                              hint: AppStrings.hintEmail,
                              icon: Icons.mail_outline,
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.email,
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthFieldWidget(
                              label: AppStrings.fieldPassword,
                              icon: Icons.lock_outline,
                              controller: passwordCtrl,
                              obscureText: !passwordVisible.value,
                              textInputAction: TextInputAction.done,
                              validator: AuthValidators.password,
                              trailing: IconButton(
                                icon: Icon(
                                  passwordVisible.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: palette.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => passwordVisible.value =
                                    !passwordVisible.value,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                _RememberToggle(
                                  value: rememberMe.value,
                                  onChanged: (bool v) => rememberMe.value = v,
                                ),
                                GestureDetector(
                                  onTap: () => context
                                      .pushNamed(AppRoutes.forgotPassword),
                                  child: Text(
                                    AppStrings.forgotPassword,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: palette.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sp24),
                            AuthPrimaryButton(
                              label: AppStrings.signIn,
                              onPressed: handleSignIn,
                            ),
                            if (kDebugMode) ...<Widget>[
                              const SizedBox(height: AppSpacing.sp12),
                              const _DebugCredentialHint(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      const AuthOrDivider(text: AppStrings.authOr),
                      const SizedBox(height: AppSpacing.sp16),
                      GlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.sp16),
                        child: Column(
                          children: <Widget>[
                            AuthOAuthButton(
                              label: AppStrings.socialGoogle,
                              icon: Icons.g_mobiledata,
                              onPressed: () => stub(AppStrings.stubGoogleSignIn),
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            AuthOAuthButton(
                              label: AppStrings.socialFacebook,
                              icon: Icons.facebook,
                              onPressed: () =>
                                  stub(AppStrings.stubAppleSignIn),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      AuthBottomLink(
                        prefix: AppStrings.dontHaveAccount,
                        actionLabel: AppStrings.signUp,
                        onAction: () => context.goNamed(
                          AppRoutes.register,
                          extra: initialRole,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Remember for 30 days" checkbox + label.
class _RememberToggle extends StatelessWidget {
  const _RememberToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (bool? v) => onChanged(v ?? false),
            activeColor: palette.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sp4),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppSpacing.sp8),
        Text(
          AppStrings.authRememberMe,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

/// Debug-only hint showing the test-account credentials beneath the Sign In
/// button. Only rendered when `kDebugMode` is true, so it never ships.
class _DebugCredentialHint extends StatelessWidget {
  const _DebugCredentialHint();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp12,
          vertical: AppSpacing.sp8,
        ),
        decoration: BoxDecoration(
          color: palette.borderSubtle,
          borderRadius: BorderRadius.circular(AppSpacing.sp8),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.info_outline, size: 16, color: palette.textMuted),
            const SizedBox(width: AppSpacing.sp8),
            Flexible(
              child: Text(
                '${AppStrings.loginTestAccountLabel}: '
                '${DevCredentials.testEmail} / ${DevCredentials.testPassword}',
                style: textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/features/auth/presentation/screens/login_screen.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/login_screen.dart
git commit -m "feat(auth): re-style Login over BrandBackdrop + GlassPanel

Two glass shelves (form + OAuth row) on a brand backdrop with soft orbs.
Title/subtitle/footer sit on the open backdrop. Validators, kDebugMode
shortcut, and routing preserved unchanged.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Re-style Register screen

**Files:**
- Modify: `lib/features/auth/presentation/screens/register_screen.dart`

Same shape as Login: backdrop, glass form panel (all five inputs + Sign Up), glass OAuth panel.

- [ ] **Step 1: Replace the file contents**

```dart
/// Sign Up screen consuming authProvider — sends the chosen role to the backend.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/hive_keys.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/hive_service_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_backdrop.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../auth_validators.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Sign Up screen.
///
/// The form validates on submit (required names, email format, 8-char password,
/// matching confirmation). Phase 1: on a valid submit a debug-only shortcut
/// writes a placeholder JWT and lands on the role-appropriate shell; release
/// builds show the not-implemented stub. The chosen [initialRole] will be
/// included in the register POST once the backend lands.
class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstNameCtrl = useTextEditingController();
    final lastNameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final passwordVisible = useState(false);
    final confirmVisible = useState(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> onCreateAccount() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (!kDebugMode) {
        stub(AppStrings.stubAuthNotImplemented);
        return;
      }
      final hive = ref.read(hiveServiceProvider);
      await hive.authBox.put(HiveKeys.keyJwtToken, 'phase1-dev-token');
      final role = ref.read(roleProvider) ?? initialRole ?? roleStudent;
      if (!context.mounted) return;
      context.goNamed(landingRouteForRole(role));
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[
          AppColors.studentPrimary,
          AppColors.studentPrimaryDark,
        ],
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp24,
                  AppSpacing.sp32,
                  AppSpacing.sp24,
                  AppSpacing.sp32,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        AppStrings.registerTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp8),
                      Text(
                        AppStrings.registerSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: AuthFieldWidget(
                                    label: AppStrings.fieldFirstName,
                                    hint: AppStrings.hintFirstName,
                                    icon: Icons.person_outline,
                                    controller: firstNameCtrl,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    validator: AuthValidators.notEmpty,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sp12),
                                Expanded(
                                  child: AuthFieldWidget(
                                    label: AppStrings.fieldLastName,
                                    hint: AppStrings.hintLastName,
                                    icon: Icons.person_outline,
                                    controller: lastNameCtrl,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    validator: AuthValidators.notEmpty,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthFieldWidget(
                              label: AppStrings.fieldEmail,
                              hint: AppStrings.hintEmail,
                              icon: Icons.mail_outline,
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.email,
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthFieldWidget(
                              label: AppStrings.fieldPassword,
                              icon: Icons.lock_outline,
                              controller: passwordCtrl,
                              obscureText: !passwordVisible.value,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.password,
                              trailing: IconButton(
                                icon: Icon(
                                  passwordVisible.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: palette.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => passwordVisible.value =
                                    !passwordVisible.value,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthFieldWidget(
                              label: AppStrings.fieldConfirmPassword,
                              icon: Icons.shield_outlined,
                              controller: confirmCtrl,
                              obscureText: !confirmVisible.value,
                              textInputAction: TextInputAction.done,
                              validator: (String? v) =>
                                  AuthValidators.confirmPassword(
                                v,
                                passwordCtrl.text,
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  confirmVisible.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: palette.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => confirmVisible.value =
                                    !confirmVisible.value,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp24),
                            AuthPrimaryButton(
                              label: AppStrings.signUp,
                              onPressed: onCreateAccount,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      const AuthOrDivider(text: AppStrings.authOr),
                      const SizedBox(height: AppSpacing.sp16),
                      GlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.sp16),
                        child: Column(
                          children: <Widget>[
                            AuthOAuthButton(
                              label: AppStrings.socialGoogle,
                              icon: Icons.g_mobiledata,
                              onPressed: () => stub(AppStrings.stubGoogleSignIn),
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            AuthOAuthButton(
                              label: AppStrings.socialFacebook,
                              icon: Icons.facebook,
                              onPressed: () =>
                                  stub(AppStrings.stubAppleSignIn),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      AuthBottomLink(
                        prefix: AppStrings.alreadyHaveAccount,
                        actionLabel: AppStrings.signIn,
                        onAction: () => context.goNamed(
                          AppRoutes.login,
                          extra: initialRole,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/features/auth/presentation/screens/register_screen.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/register_screen.dart
git commit -m "feat(auth): re-style Register over BrandBackdrop + GlassPanel

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: Re-style Forgot Password screen

**Files:**
- Modify: `lib/features/auth/presentation/screens/forgot_password_screen.dart`

Single glass shelf (email + recover button), no OAuth panel.

- [ ] **Step 1: Replace the file contents**

```dart
/// Forgot Password screen — request a recovery link by email.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_backdrop.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../auth_validators.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Forgot Password screen.
///
/// Collects the account email and validates it on submit. Phase 1 shows a
/// success SnackBar (no backend yet). The spec's stray "password" field is
/// intentionally omitted — you don't enter a password to recover one.
class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    void onRecover() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.forgotSuccess)),
        );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[
          AppColors.studentPrimary,
          AppColors.studentPrimaryDark,
        ],
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp24,
                  AppSpacing.sp32,
                  AppSpacing.sp24,
                  AppSpacing.sp32,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        AppStrings.forgotTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp8),
                      Text(
                        AppStrings.forgotSubtitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp4),
                      Text(
                        AppStrings.forgotDescription,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            AuthFieldWidget(
                              label: AppStrings.fieldEmail,
                              hint: AppStrings.hintEmail,
                              icon: Icons.mail_outline,
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: AuthValidators.email,
                            ),
                            const SizedBox(height: AppSpacing.sp24),
                            AuthPrimaryButton(
                              label: AppStrings.recoverPasswordButton,
                              onPressed: onRecover,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      AuthBottomLink(
                        prefix: AppStrings.forgotRememberPrefix,
                        actionLabel: AppStrings.signIn,
                        onAction: () => context.goNamed(AppRoutes.login),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/features/auth/presentation/screens/forgot_password_screen.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/forgot_password_screen.dart
git commit -m "feat(auth): re-style Forgot Password over BrandBackdrop + GlassPanel

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 13: Re-style Onboarding screen

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`

- 3-orb backdrop celebrating the role choice (`studentPrimary`, `ownerAccent`, `teacherAccent`).
- Hero badge becomes embossed (`NeoSurface` accent-fill).
- Role trio wraps in one `GlassPanel`; each option is a `NeoButton(selected: …)`.
- `_ContinueButton` becomes a `NeoButton(filled: true)` that re-tweens to the selected role's accent.
- Staggered entrance animation preserved.

- [ ] **Step 1: Replace the file contents**

```dart
/// Role selector — writes the chosen role to Hive and routes to login.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/hive_keys.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/hive_service_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_backdrop.dart';
import '../../../../shared/widgets/entrance_fade_slide.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/neo_button.dart';
import '../../../../shared/widgets/neo_surface.dart';

/// A selectable onboarding role, with its own brand accent.
class _RoleOptionData {
  const _RoleOptionData({
    required this.role,
    required this.title,
    required this.blurb,
    required this.icon,
    required this.accent,
  });

  final String role;
  final String title;
  final String blurb;
  final IconData icon;
  final Color accent;
}

/// Onboarding screen — neoglass styling, three-orb brand backdrop, glass role
/// shelf, neo role tiles (the inset depress IS the selection signal), and a
/// neo Continue CTA that re-tweens to the selected role's accent.
class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = useState<String?>(null);
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    final entrance = useAnimationController(
      duration: const Duration(milliseconds: 850),
    );
    useEffect(() {
      entrance.forward();
      return null;
    }, const <Object?>[]);

    final roles = <_RoleOptionData>[
      const _RoleOptionData(
        role: roleStudent,
        title: AppStrings.roleStudentTitle,
        blurb: AppStrings.roleStudentBlurb,
        icon: Icons.school_outlined,
        accent: AppColors.studentPrimary,
      ),
      const _RoleOptionData(
        role: roleOwner,
        title: AppStrings.roleOwnerTitle,
        blurb: AppStrings.roleOwnerBlurb,
        icon: Icons.storefront_outlined,
        accent: AppColors.ownerAccent,
      ),
      const _RoleOptionData(
        role: roleTeacher,
        title: AppStrings.roleTeacherTitle,
        blurb: AppStrings.roleTeacherBlurb,
        icon: Icons.cast_for_education_outlined,
        accent: AppColors.teacherAccent,
      ),
    ];

    Color ctaAccent = AppColors.studentPrimary;
    for (final _RoleOptionData r in roles) {
      if (r.role == selectedRole.value) ctaAccent = r.accent;
    }

    Future<void> handleContinue() async {
      final role = selectedRole.value;
      if (role == null) return;
      final hive = ref.read(hiveServiceProvider);
      await hive.settingsBox.put(HiveKeys.keyUserRole, role);
      ref.read(roleProvider.notifier).state = role;
      if (!context.mounted) return;
      context.goNamed(AppRoutes.login, extra: role);
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[
          AppColors.studentPrimary,
          AppColors.ownerAccent,
          AppColors.teacherAccent,
        ],
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.sp24,
                            AppSpacing.sp16,
                            AppSpacing.sp24,
                            AppSpacing.sp16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const SizedBox(height: AppSpacing.sp16),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.0,
                                end: 0.45,
                                child: const _Hero(),
                              ),
                              const SizedBox(height: AppSpacing.sp32),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.10,
                                end: 0.55,
                                child: Text(
                                  AppStrings.onboardingTitle,
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp12),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.18,
                                end: 0.63,
                                child: Text(
                                  AppStrings.onboardingSubtitle,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: palette.textMuted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp32),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.26,
                                end: 0.80,
                                child: GlassPanel(
                                  padding: const EdgeInsets.all(AppSpacing.sp16),
                                  child: Column(
                                    children: <Widget>[
                                      for (int i = 0;
                                          i < roles.length;
                                          i++) ...<Widget>[
                                        if (i > 0)
                                          const SizedBox(
                                              height: AppSpacing.sp12),
                                        _RoleTile(
                                          data: roles[i],
                                          selected: selectedRole.value ==
                                              roles[i].role,
                                          onTap: () => selectedRole.value =
                                              roles[i].role,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: AppSpacing.sp24),
                              EntranceFadeSlide(
                                animation: entrance,
                                start: 0.55,
                                end: 1.0,
                                child: NeoButton(
                                  onPressed: selectedRole.value == null
                                      ? null
                                      : handleContinue,
                                  filled: true,
                                  accent: ctaAccent,
                                  height: 56,
                                  radius: AppSpacing.sp16,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        AppStrings.onboardingContinue,
                                        style:
                                            textTheme.titleMedium?.copyWith(
                                          color: AppColors.neutralWhite,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sp8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 18,
                                        color: AppColors.neutralWhite,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Brand lockup: an embossed neo logo badge above the CoachFinder wordmark.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        NeoSurface(
          fill: AppColors.studentPrimary,
          padding: const EdgeInsets.all(AppSpacing.sp16),
          radius: AppSpacing.sp16,
          child: const Icon(
            Icons.school_rounded,
            color: AppColors.neutralWhite,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.sp12),
        Text(
          AppStrings.appName,
          style: textTheme.titleLarge?.copyWith(
            color: context.palette.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A selectable role row — accent icon tile + title + blurb + radio indicator,
/// presented as a [NeoButton] whose inset (selected) state IS the signal.
class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _RoleOptionData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return NeoButton(
      onPressed: onTap,
      selected: selected,
      accent: data.accent,
      filled: false,
      height: 88,
      radius: AppSpacing.sp16,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sp12),
            ),
            child: Icon(data.icon, color: data.accent, size: 24),
          ),
          const SizedBox(width: AppSpacing.sp16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  data.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp4),
                Text(
                  data.blurb,
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp12),
          _SelectIndicator(selected: selected, accent: data.accent),
        ],
      ),
    );
  }
}

/// Radio-style indicator: outlined circle that fills with [accent] when
/// [selected], with an animated checkmark.
class _SelectIndicator extends StatelessWidget {
  const _SelectIndicator({required this.selected, required this.accent});

  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accent : Colors.transparent,
        border: Border.all(
          color: selected ? accent : palette.border,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: const Icon(
          Icons.check,
          size: 16,
          color: AppColors.neutralWhite,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/features/onboarding/presentation/screens/onboarding_screen.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/presentation/screens/onboarding_screen.dart
git commit -m "feat(onboarding): re-style with BrandBackdrop + GlassPanel + NeoButton tiles

Three-orb brand backdrop celebrates the choice; the role trio sits in one
glass shelf; each tile is a NeoButton whose inset (selected) state IS the
selection signal; embossed neo hero badge; neo Continue CTA re-tweens to the
selected role's accent. Staggered entrance animation preserved.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 14: Rewrite `flutter-ui` skill

**Files:**
- Modify: `.claude/skills/flutter-ui/SKILL.md`

- [ ] **Step 1: Replace the file contents**

```markdown
---
name: flutter-ui
description: >-
  Use when building, restyling, or reviewing ANY Flutter UI in this CoachFinder
  app — screens, widgets, cards, forms, lists. Generates modern, theme-aware UI
  that follows the project's neoglass design system (BrandBackdrop, GlassPanel,
  NeoSurface, NeoButton over context.palette / AppColors / AppSpacing /
  AppEffects), folder structure, Riverpod + hooks conventions, and the
  established card / chip / section / stats-strip / read-view+edit-form patterns.
---

# CoachFinder Flutter UI — Neoglass

How to build UI in this repo so it looks modern AND matches existing screens.
The reference implementations are the **onboarding** and **auth** features —
mirror them for hero / atmospheric surfaces. The student/owner/teacher shell
screens are mid-migration; do not regress those that have already moved to
neoglass.

## The aesthetic (what "modern" means here)

**Mantra:** **Glass surrounds. Neo presses.**

| Surface | Style | Why |
|---|---|---|
| Page background on hero / auth / onboarding / future empty-state screens | `BrandBackdrop` | Sets atmosphere; gives glass something to blur. |
| Form shelves, OAuth row, sticky AppBars, sheets, snackbars (future) | `GlassPanel` | Containers that frame other content. |
| Feed cards, stat strips, recent-enquiries previews (future migration) | `NeoSurface` (outset) | Independent content cards, need weight. |
| Primary CTA / Continue button | `NeoButton(filled: true, accent: …)` | Tactile, pressable. |
| Role tiles, selectable chips | `NeoButton(selected: …)` | The inset depress IS the selection signal. |
| Text fields | `AuthFieldWidget` (already wraps `NeoSurface(inset: true)`) | Recessed "well" — affordance for typing. |
| Avatars / brand badges | `NeoSurface` (accent fill) | Embossed brand. |
| Dialogs, modal sheets (future) | `GlassPanel` | Overlays. |
| Debug-only chrome | Stays flat | Not a production surface. |

**Intensity: soft & premium.** Subtle shadows, gentle blur. Calibration baked
into `AppEffects`: outset blur 18, dark-shadow alpha 8% (light) / 50% (dark);
glass blur 24, fill alpha 60% (light) / 24% (dark). Heavier reads as 2020
skeumorphism.

**The rhythm:** bold section title → glass shelf or neo card → next title.
Keep generous whitespace; use `AppSpacing.sp24` between sections.

**Capped & centered on wide screens** (the app has a NavigationRail ≥ 768 px):
wrap scroll content in `Align(alignment: Alignment.topCenter)` +
`ConstrainedBox(maxWidth: …)`. Use **480** for auth / onboarding, **600** for
account / profile, **720** for feeds / lists / forms.

## Non-negotiable conventions

- **No hardcoded values.** Strings → `AppStrings`. Colours → `context.palette.*`
  or `AppColors.*`. Sizes / spacing → `AppSpacing.*`. Motion / blur / shadow
  numerics → `AppEffects.*`. Never inline a hex literal, a `Duration` for an
  animation, or a `Color.withValues(alpha: 0.something)` shadow.
- **Theme-aware by default.** Read neutrals / text via `context.palette` (import
  `core/theme/app_palette.dart`). A widget that reads `context.palette` can't be
  `const` — that's expected; keep `const` only on fixed-`AppColors` literals.
- **Screens** extend `HookConsumerWidget`. **Widgets** are `HookWidget` (need
  hooks) or `StatelessWidget`. Private sub-widgets (`_Foo`) inlined in the
  screen file are fine for single-use pieces.
- **Riverpod only** (no get_it). Read-only screens use fixtures directly; UI
  that mutates shared state across navigation uses a **`NotifierProvider`** in
  `data/controllers/` (see enquiries / manage-center / teacher-profile).
- **`///` doc comment** on every class and public method. `const` constructors
  where possible.
- Only `data/repository/` may touch Dio / Hive. Fixtures live in
  `data/mock_<feature>_data.dart` (models + fixtures together).

## Design tokens

`context.palette` (brightness-aware — `lib/core/theme/app_palette.dart`):
`background`, `surface`, `border`, `borderSubtle`, `textPrimary`,
`textSecondary`, `textMuted`, `iconFaint`, `inputFill`, `primary`,
`primaryTint`, **`neoShadowDark`**, **`neoShadowLight`**, **`glassFill`**,
**`glassBorder`**.

`AppColors` (fixed — `lib/core/theme/app_colors.dart`): role accents
`studentPrimary` (#1A56DB), `ownerAccent` (#E05A2B), `teacherAccent` (#0D9488);
`studentPrimaryDark` (gradient stop); `ratingStar`, `priceGreen`, `ctaAmber`;
semantic `success` / `warning` / `error` / `info`; `neutralWhite`, `neutralBlack`.

`AppSpacing`: `sp4 sp8 sp12 sp16 sp24 sp32 sp48`.

`AppEffects` (`lib/core/theme/app_effects.dart`): `glassBlur` (24),
`glassBlurStrong` (36), `neoOutsetOffsetDark/Light`, `neoOutsetBlur` (18),
`neoInsetOffsetDark/Light`, `neoInsetBlur` (12), `neoPressDuration` (220 ms),
`orbDiameter` (320).

### Picking the accent

- **Student** screens → `palette.primary` (foreground) / `AppColors.studentPrimary` (fill).
- **Owner** screens → `AppColors.ownerAccent`.
- **Teacher** screens → `AppColors.teacherAccent`.
- **Auth + global brand surfaces** → `AppColors.studentPrimary` (the brand blue).
- **Onboarding** → all three role accents on the backdrop (one each).

### Dark mode neo calibration

- In dark mode the "light" outset shadow is intentionally near-invisible —
  there is no real light source to fake. `NeoSurface` / `NeoButton` add a 1 px
  `palette.borderSubtle` automatically for edge definition. Don't bypass this.
- Glass fill alpha is *lower* in dark (24 %, not 60 %) — translucent over a
  dark backdrop reads as smoke, not milk. The token handles it.
- Brand foregrounds on dark surfaces use `palette.primary` (the lightened blue
  `AppColors.darkPrimary`), not `AppColors.studentPrimary`.

### Fill-vs-foreground rule (still critical)

- A brand accent (`studentPrimary` / `ownerAccent` / `teacherAccent`) is **fixed**
  — use it as a *foreground* (text / icon / border), as a *fill behind white text*
  (filled NeoButton, selected pills, avatars), or as a `withValues(alpha: 0.08–0.14)`
  tint.
- `palette.surface` is a *fill*; `AppColors.neutralWhite` is only for
  *foreground on a coloured fill* (e.g. a white initial on an accent avatar).
- For student screens specifically, brand *foregrounds* use `palette.primary`
  (lightens in dark); brand *fills* keep `AppColors.studentPrimary`.
- Decorative "content" colours (fixture pastels for topic chips / tag pills)
  must still adapt: tint via `seed.withValues(alpha: ~0.2)` in dark mode and
  lighten any coloured icon via
  `HSLColor.fromColor(seed).withLightness(0.72).toColor()`.

## Performance notes

- `BackdropFilter` (inside `GlassPanel`) is GPU-heavy. **Prefer one large
  `GlassPanel` over many small ones.**
- **Never** put a `GlassPanel` inside a `ListView.builder` item — every scroll
  frame triggers a fresh blur and the app stutters. Glass is for outer chrome,
  not list rows.
- `BrandBackdrop` orbs are cheap (one `RadialGradient` paint each), but stack
  cost grows; **only use `BrandBackdrop` on hero / atmospheric screens** (auth,
  onboarding, future landing / empty states). Shell pages keep plain
  `palette.background`.

## Copy-paste component patterns

**Brand backdrop** (auth, onboarding, hero screens)
```dart
Scaffold(
  backgroundColor: palette.background,
  body: BrandBackdrop(
    orbColors: const <Color>[AppColors.studentPrimary, AppColors.studentPrimaryDark],
    child: SafeArea(child: …),
  ),
)
```

**Glass shelf** (form panel, OAuth row, sheet)
```dart
GlassPanel(
  padding: const EdgeInsets.all(AppSpacing.sp24),
  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[ … ]),
)
```

**Neo surface card** (independent content card; future shell migration)
```dart
NeoSurface(
  padding: const EdgeInsets.all(AppSpacing.sp16),
  child: …,
)
```

**Neo recessed well** (used internally by AuthFieldWidget; lift up for custom forms)
```dart
NeoSurface(
  inset: true,
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12),
  child: TextFormField(
    decoration: neoInputDecoration(context: context, label: 'Email', icon: Icons.mail_outline),
  ),
)
```

**Primary CTA** (filled accent)
```dart
NeoButton(
  onPressed: onPressed,
  filled: true,
  accent: AppColors.studentPrimary,
  child: const Text('Continue'),
)
```

**Secondary / OAuth-style button** (surface fill, accent foreground)
```dart
NeoButton(
  onPressed: onPressed,
  filled: false,
  accent: palette.textPrimary,
  child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
    Icon(Icons.g_mobiledata, size: 20),
    SizedBox(width: AppSpacing.sp8),
    Text('Continue with Google'),
  ]),
)
```

**Selectable role tile / chip** (inset on select)
```dart
NeoButton(
  onPressed: onTap,
  selected: isSelected,
  accent: roleAccent,
  filled: false,
  height: 88,
  radius: AppSpacing.sp16,
  child: …,  // row of icon + title + blurb + indicator
)
```

**Accent-tinted icon tile** (unchanged from the previous system; still useful)
```dart
Container(
  width: 40, height: 40, alignment: Alignment.center,
  decoration: BoxDecoration(
    color: accent.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(AppSpacing.sp12),
  ),
  child: Icon(icon, size: 22, color: accent),
)
```

**Section title** (unchanged)
```dart
Text(title, style: textTheme.titleMedium?.copyWith(
  fontWeight: FontWeight.w700, color: palette.textPrimary));
```

**Stats strip** (unchanged for now; will move to `NeoSurface` outer + inner divisions during the next migration phase)
```dart
Container(
  decoration: BoxDecoration(
    color: palette.surface,
    borderRadius: BorderRadius.circular(AppSpacing.sp16),
    border: Border.all(color: palette.borderSubtle),
  ),
  child: IntrinsicHeight(child: Row(children: [Expanded(_Stat), VerticalDivider(color: palette.borderSubtle), …])),
)
```

**Screen scaffold shell** (hero variant — backdrop + glass shelves)
```dart
Scaffold(
  backgroundColor: palette.background,
  body: BrandBackdrop(
    orbColors: const <Color>[AppColors.studentPrimary, AppColors.studentPrimaryDark],
    child: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sp24, AppSpacing.sp32, AppSpacing.sp24, AppSpacing.sp32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
              Text('Title', …),
              SizedBox(height: AppSpacing.sp24),
              GlassPanel(child: …),  // form / shelf
              SizedBox(height: AppSpacing.sp24),
              NeoButton(filled: true, accent: AppColors.studentPrimary, onPressed: …, child: …),
            ]),
          ),
        ),
      ),
    ),
  ),
)
```

**Screen scaffold shell** (shell variant — plain background, no backdrop) — keep using `palette.background` for the student / owner / teacher tabbed shells until they migrate in a later round.

## Read-view + edit-form pattern (for editable features)

1. `data/mock_<feature>_data.dart`: the model (with `copyWith`) + a fixture.
2. `data/controllers/<feature>_provider.dart`: a `Notifier<Model>` seeded from
   the fixture, exposing mutators; `final fooProvider = NotifierProvider<…>(FooNotifier.new);`.
3. Read screen `ref.watch`es the provider; an Edit button `context.pushNamed`es
   the edit route (so back returns within the shell).
4. Edit screen `ref.read`s the provider **once** into local hook draft state
   (`useTextEditingController(text: …)`, `useState`), then on Save calls
   `notifier.save(current.copyWith(...))`, shows a snackbar, and `context.pop()`.
5. Add the route name to `AppRoutes` and a nested `GoRoute` in `app_router.dart`.
6. Detail / edit screens pushed inside a shell use `AppBar` with
   `leading: BackButton(onPressed: () => context.pop())`.

## Workflow when generating UI

1. Add any new strings to `app_strings.dart`, routes to `app_routes.dart` +
   `app_router.dart`.
2. Build the screen / widgets following the neoglass patterns above; brand by
   role. Default to `palette.background` + flat surfaces for non-hero screens
   until the shell migration phase lands.
3. Verify: `dart format lib` → `flutter analyze` (must be *No issues found!*) →
   `flutter build apk --debug`. For new hero screens, also walk the screen on a
   device or simulator in **both light and dark** modes — neoglass is most
   fragile when the calibration is off.
4. Record the decision: add `decisions/00NN-<slug>.md` and tick `task.md`.

## Constraints

- **Tech stack is FIXED** — do NOT add a package not already in `pubspec.yaml`
  (no charts, image pickers, url_launcher, no neumorphism / glass packages —
  we hand-built four small widgets specifically to avoid that). Hand-draw with
  `CustomPainter` for unusual visuals and stub unavailable actions with a
  "Coming soon" snackbar (`AppStrings.stubComingSoon`).
- Photos / uploads are coloured placeholder tiles until a picker exists.
- Mock / in-memory state is the Phase-1 norm; note it resets on restart.
- **Migration boundary:** Until further notice, only auth + onboarding screens
  use `BrandBackdrop` + `GlassPanel`. Other screens stay flat (still use
  `palette.surface` cards with `palette.borderSubtle` hairlines from the prior
  system). When asked to restyle one, confirm scope with the user before
  rolling the new system to it.
```

- [ ] **Step 2: Verify the skill file is well-formed**

```bash
head -5 .claude/skills/flutter-ui/SKILL.md
```

Expected: starts with `---` frontmatter block.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/flutter-ui/SKILL.md
git commit -m "docs(skill): rewrite flutter-ui skill for neoglass design system

Replaces the 'flat, bordered, no shadows' non-negotiable with the neoglass
'Glass surrounds, neo presses' rule plus a surface->style table, soft &
premium calibration notes, dark-mode neo guidance, BackdropFilter perf
rules, and copy-paste snippets for BrandBackdrop / GlassPanel / NeoSurface /
NeoButton. Marks the migration boundary — only auth + onboarding use the
new primitives this round; other screens stay flat until later phases.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 15: Add ADR 0028

**Files:**
- Create: `decisions/0028-neoglass-design-system.md`

- [ ] **Step 1: Create the file**

```markdown
# 0028 — Neoglass design system (round 1: skill + auth/onboarding)

**Status:** Accepted
**Date:** 2026-05-28
**Phase:** Post-Phase-1 design-system pivot, first of a phased rollout
**Made by:** User (request + 3 scoping choices via `/flutter-ui` + brainstorming flow)
+ Claude (design, spec, plan, implementation)

## Context

The flutter-ui skill enforced "flat, bordered surfaces — not shadows" as a
non-negotiable. The user asked to pivot to a hybrid neomorphism +
glassmorphism look and update the skill so future UI inherits it. Phased
delivery: this round only updates the skill and restyles onboarding + the
three auth screens (login, register, forgot password) as a showcase before
propagating further.

Via three brainstorming questions the user chose: **phased rollout starting
with skill + onboarding + auth**, **brand gradient + blurred orbs** as the
glass backdrop, and **soft & premium** intensity.

## Decision

Adopted a hybrid system with the rule **"Glass surrounds, neo presses."**:
glass for surfaces that frame content (form shelves, OAuth row, future sheets
and AppBars), neo for surfaces that are themselves an affordance (CTAs, role
tiles, chips, inputs).

- New design tokens: `neoShadowDark`, `neoShadowLight`, `glassFill`,
  `glassBorder` on `AppPalette` (brightness-aware), plus an `AppEffects` file
  for non-color motion / blur / shadow numerics.
- Four new widgets: `BrandBackdrop` (gradient + radial-gradient orbs),
  `GlassPanel` (ClipRRect → BackdropFilter → translucent fill), `NeoSurface`
  (outset / inset shadows), `NeoButton` (pressable, animates outset → inset on
  tap; sticky inset via `selected: true`). One helper:
  `neoInputDecoration`.
- `AuthFieldWidget` / `AuthPrimaryButton` / `AuthOAuthButton` rebuilt
  internally over the new primitives — public APIs preserved so the rewrite
  is contained.
- Screens restyled: onboarding (3-orb backdrop, glass shelf, neo role tiles,
  neo Continue), login (2 glass shelves on backdrop), register (same shape),
  forgot password (single glass shelf).
- `.claude/skills/flutter-ui/SKILL.md` rewritten: aesthetic section replaced
  with the surface→style table, copy-paste snippets, dark-mode calibration,
  and a performance section calling out the `BackdropFilter` and orb costs.
- The migration boundary is documented: only auth + onboarding use the new
  primitives this round; shell screens stay flat until later phases.

### Calibration (the "soft & premium" choice)

- Outset shadow: alpha 8 % (light) / 50 % (dark), blur 18, offset ±6.
- Inset shadow: alpha as above, blur 12, offset ±4.
- Glass fill: alpha 60 % (light) / 24 % (dark); blur sigma 24.
- Neo press animation: 220 ms `easeOut` shadow swap.
- Orb diameter: 320 logical pixels with `RadialGradient(color → transparent)`.

### Not done (deliberate, per the phased plan)

- Student / owner / teacher shell screens (feeds, dashboards, enquiries,
  manage-center, profiles, edit forms) stay flat.
- The floating bottom nav / side rail (ADR 0027) is unchanged.
- No new dependencies; everything ships in Flutter core.
- No new tests; existing `test/adaptive_navigation_tooltip_test.dart` still
  passes (it touches none of these files).

## Consequences

- Future UI work goes through the rewritten skill by default. The skill
  marks the migration boundary so generated code doesn't apply neoglass to
  shells before the user signs off on it.
- `AppPalette.light` / `AppPalette.dark` became static getters (not
  `const` fields) because alpha-modified colors aren't compile-time
  constants. Call sites at runtime are unaffected.
- Manual visual verification is the gate for this round (no widget tests
  assert surface shape).

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* ·
`flutter test test/adaptive_navigation_tooltip_test.dart` → passed ·
`flutter build apk --debug` → built. Manual walk Onboarding → Login →
Forgot Password → back → Register in light and dark to verify the orb
backdrop reads softly, glass panels read frosted, neo press feedback feels
tactile, and input contrast in dark mode is unchanged.
```

- [ ] **Step 2: Commit**

```bash
git add decisions/0028-neoglass-design-system.md
git commit -m "docs(adr): record 0028 — neoglass design system round 1

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 16: Final verification

**Files:**
- None modified — verification only.

- [ ] **Step 1: Run full format + analyze**

```bash
dart format lib
flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 2: Run the existing test**

```bash
flutter test test/adaptive_navigation_tooltip_test.dart
```

Expected: All tests pass.

- [ ] **Step 3: Build the debug APK**

```bash
flutter build apk --debug
```

Expected: build completes without errors.

- [ ] **Step 4: Manual visual verification**

Launch the app (e.g. `flutter run`) and walk the four screens in **both light
and dark themes**:

1. App opens to **Onboarding** → confirm three soft orbs (blue / orange / teal)
   read in the corners; the glass role shelf reads frosted; tapping a role
   visibly depresses the tile (inset); the Continue CTA tweens to the picked
   role's accent and depresses on tap.
2. Tap Continue → **Login** → confirm two-orb backdrop (blue / dark blue);
   form sits in glass with recessed inputs; password visibility toggle works;
   Sign In button depresses; in `kDebugMode` the debug hint chip renders
   below the button.
3. Tap "Forgot password?" → **Forgot Password** → single glass shelf, one
   email input, one neo button. Submit shows the success SnackBar.
4. Back to Login → tap "Sign up" → **Register** → 5-field glass form + glass
   OAuth row; password + confirm-password visibility toggles work
   independently; submit goes to the landing screen for the selected role.

Toggle dark mode in the OS / system tray (or via the in-app appearance
toggle if available) and re-walk to confirm:
- Glass reads as soft smoke, not milky / washed-out.
- Neo press feedback is still visible (1 px border helps define edges).
- Input text contrast is unchanged.

If on-device testing reveals jank from the orb backdrop, the immediate
fallback is to drop to 2 orbs (already the case for auth) or lower
`AppEffects.glassBlur` from 24 to 18 — both are token tweaks, no
architectural change.

- [ ] **Step 5: Update `task.md`** (if there's a line for design-system work; otherwise skip)

- [ ] **Step 6: No final commit needed** — bookkeeping commits in Tasks 14 + 15 already cover the round.

---

## Self-review notes (post-write)

- **Spec coverage:** every §3 token + every §3.x widget has a dedicated task; every screen in §4 has a dedicated task; the skill rewrite is its own task; ADR 0028 captures the round-level decision; final verification covers §10's checklist.
- **Placeholder scan:** no "TODO", no "TBD", no "implement later" — every code step contains the actual code; every command step contains the actual command.
- **Type consistency:** the four primitive widgets are referenced by their exact class names in every later task that uses them (`BrandBackdrop`, `GlassPanel`, `NeoSurface`, `NeoButton`, `neoInputDecoration`). `AuthFieldWidget` / `AuthPrimaryButton` / `AuthOAuthButton` constructor parameters in Tasks 8–9 match the call sites in Tasks 10–12.
- **Known fragility:** the `BoxShadow.inset` parameter assumes a recent enough Flutter stable. Task 5 documents the fallback if it's unavailable. The `AppPalette.light/dark` `const` → `static get` change is documented inline in Task 2 with a grep step to catch any const-context call site.
