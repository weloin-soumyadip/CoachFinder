# Neoglass Design System — Design Spec

**Date:** 2026-05-28
**Phase:** Post-Phase-1 design system pivot (round 1 of a phased rollout)
**Scope this round:** Update the `flutter-ui` skill + restyle Onboarding and the three Auth screens (Login, Register, Forgot Password) as the showcase. Other shells (student/owner/teacher feeds and edit forms) stay flat for now and will be migrated in later phases once this direction is validated on device.

---

## 1. Intent

Pivot the CoachFinder visual language from the current "flat, bordered, no shadows" system to a hybrid **neomorphism + glassmorphism** system, calibrated as **soft & premium** (subtle outset shadows, gentle frosted blur — the Apple / Linear / Vercel register, not heavy 2020-style skeumorphism).

The mantra that resolves the two styles into one design system:

> **Glass surrounds. Neo presses.**

Glass is used for surfaces that **frame other content** — the form shelf an input lives in, the OAuth row, future AppBars / sticky headers / sheets / snackbars. Neo is used for surfaces that **are themselves an affordance** — buttons, role tiles, chips, text fields (inset). The two styles don't fight because they have different jobs.

This spec is the single source of truth for the new tokens, primitives, decision rule, and screen-level application — for the four screens in scope this round, **and** for every screen the skill will guide in future rounds.

## 2. Out of scope (this round)

- Student / owner / teacher shell screens (feeds, dashboards, enquiries, manage center, profiles, edit forms) — explicit "do these later" per the user's phased-development preference.
- Navigation chrome (the floating bottom bar / side rail from ADR 0027) — keeps its current floating-card aesthetic for now. May be revisited in a later round if device validation shows the new system should reach it.
- New dependencies — `BackdropFilter` and `ImageFilter.blur` ship in Flutter core; no packages added.
- Animations beyond the existing `EntranceFadeSlide` and `AnimatedContainer` motion — neo press feedback is a 250 ms `AnimatedContainer` shadow swap, no new motion library.

## 3. Architecture

### 3.1 New design tokens

Two new groups, both **brightness-aware** (added to `AppPalette`), plus one fixed-numeric file:

**`AppPalette` additions** (`lib/core/theme/app_palette.dart`)

| Token | Light value | Dark value | Purpose |
|---|---|---|---|
| `neoShadowDark` | `neutralBlack.withValues(alpha: 0.08)` | `neutralBlack.withValues(alpha: 0.50)` | The "weight" shadow on outset neo surfaces (bottom-right). |
| `neoShadowLight` | `neutralWhite.withValues(alpha: 0.90)` | `surface.withValues(alpha: 0.06)` (effectively a barely-there top-left highlight) | The "light" shadow on outset neo surfaces (top-left). In dark mode this is intentionally near-invisible — there is no real light source to fake. |
| `glassFill` | `surface.withValues(alpha: 0.60)` | `surface.withValues(alpha: 0.24)` | Translucent fill behind `BackdropFilter`. |
| `glassBorder` | `neutralWhite.withValues(alpha: 0.60)` | `neutralWhite.withValues(alpha: 0.08)` | Hairline edge that catches the light on a glass panel. |

**`AppEffects`** — new file `lib/core/theme/app_effects.dart`. Holds **fixed, non-color** motion / blur / shadow numerics so they don't pollute `AppColors`:

```dart
abstract final class AppEffects {
  static const double glassBlur = 24;
  static const double glassBlurStrong = 36;          // optional, for hero overlays
  static const Offset neoOutsetOffsetDark = Offset(6, 6);
  static const Offset neoOutsetOffsetLight = Offset(-6, -6);
  static const double neoOutsetBlur = 18;
  static const Offset neoInsetOffsetDark = Offset(-4, -4);
  static const Offset neoInsetOffsetLight = Offset(4, 4);
  static const double neoInsetBlur = 12;
  static const Duration neoPressDuration = Duration(milliseconds: 220);
  static const double orbDiameter = 320;             // backdrop orb size
  static const double orbBlurSigma = 80;             // backdrop orb blur
}
```

These are stable enough to be `const` and **not** brightness-aware (they're geometric, not chromatic).

### 3.2 Backdrop

New file `lib/shared/widgets/brand_backdrop.dart` — a single widget:

```dart
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({
    super.key,
    required this.child,
    this.orbColors = const <Color>[],
    this.seed,
  });
  final Widget child;
  final List<Color> orbColors;  // up to 3 used
  final Color? seed;             // for the gradient tint; falls back to first orb / studentPrimary
  // implementation: Stack with
  //   1) DecoratedBox holding a LinearGradient(begin: topLeft, end: bottomRight,
  //      colors: [palette.background, Color.alphaBlend(seed @ 0.10, palette.background)])
  //   2) up to 3 Positioned containers (corners + one offset), each:
  //        SizedBox(AppEffects.orbDiameter) ->
  //        DecoratedBox(
  //          shape: BoxShape.circle,
  //          gradient: RadialGradient(
  //            colors: [
  //              orbColor.withValues(alpha: light ? 0.35 : 0.18),
  //              orbColor.withValues(alpha: 0.0),
  //            ],
  //            stops: [0.0, 1.0],
  //          ),
  //        )
  //      The RadialGradient (color -> transparent) is what makes the orb soft;
  //      we do NOT wrap orbs in BackdropFilter — that's reserved for GlassPanel.
  //      An orb painted this way costs one cheap radial-gradient draw, vs the
  //      GPU cost of a full-frame BackdropFilter per orb.
  //   3) the child (Stack siblings paint on top of the orbs)
  // Note: when a GlassPanel sits over this backdrop, its BackdropFilter will
  // re-blur the orb-tinted pixels behind it, producing the frosted aura that
  // makes glass read as glass. That is the entire interaction loop: gradient
  // + RadialGradient orbs supply the color, GlassPanel supplies the blur.
}
```

**Why a single widget, not a `Theme`-level decoration:** the backdrop only appears on auth + onboarding (and, in future rounds, possibly hero / empty / loading screens). Putting it in the global theme would force every screen to pay the perf cost; making it opt-in keeps the rest of the app flat.

**Orb count by screen:**
- Onboarding → 3 orbs, colors `[studentPrimary, ownerAccent, teacherAccent]` (celebrates the choice).
- Login / Register / Forgot Password → 2 orbs, colors `[studentPrimary, studentPrimaryDark]` (single brand identity).

### 3.3 Neo primitives (3 widgets)

New file `lib/shared/widgets/neo_surface.dart`:

```dart
class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.sp16),
    this.radius = AppSpacing.sp16,
    this.inset = false,
    this.fill,            // overrides palette.surface
  });
  // outset: BoxDecoration with two BoxShadows from AppEffects + palette.neoShadowDark/Light
  // inset:  BoxDecoration with two *inverted* BoxShadows (top-left dark, bottom-right light)
  //         on palette.inputFill (so it reads as a recessed well, used by NeoInputDecoration)
  // dark mode: when palette.brightness == Brightness.dark, add a 1px palette.borderSubtle
  //            to give the surface an edge — the "light" shadow is too faint to define it
}
```

New file `lib/shared/widgets/neo_button.dart`:

```dart
class NeoButton extends HookWidget {
  const NeoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filled = false,        // true: accent-fill primary; false: surface-fill secondary
    this.accent,                // null falls back to palette.primary
    this.height = 52,
    this.radius = AppSpacing.sp12,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
  });
  // hook: ValueNotifier<bool> pressed = useState(false)
  // GestureDetector(onTapDown -> pressed=true, onTapUp/Cancel -> pressed=false, onTap -> onPressed)
  // child wrapped in AnimatedContainer(AppEffects.neoPressDuration, easeOut)
  //   decoration swaps from outset shadows (resting) to inset shadows (pressed)
  // filled:true => background uses accent and *omits the light shadow* (would clash)
  // foreground color: white if filled, else accent (for label/icon)
}
```

New file `lib/shared/widgets/neo_input_decoration.dart` — **not a widget**, just a helper:

```dart
InputDecoration neoInputDecoration({
  required BuildContext context,
  required String label,
  required IconData icon,
  String? hint,
  Widget? suffix,
}) {
  // returns an InputDecoration with palette.inputFill, no border, sp12 radius,
  // floating-label palette.primary, prefix/suffix icons.
}

// AuthFieldWidget then wraps the TextFormField in a NeoSurface(inset: true)
// (since BoxDecoration shadows live *outside* the InputDecorator paint, the wrapper is the only way).
```

**Why three small widgets, not one mega `Neomorphic`:** keeps each file < 100 lines, makes the press-state hook live only where it's needed (the button), and matches the existing project style (see `EntranceFadeSlide` — small, dedicated widgets).

### 3.4 Glass primitive (1 widget)

New file `lib/shared/widgets/glass_panel.dart`:

```dart
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.sp24),
    this.radius = AppSpacing.sp24,
    this.blur = AppEffects.glassBlur,
  });
  // ClipRRect(borderRadius) ->
  //   BackdropFilter(ImageFilter.blur(sigmaX: blur, sigmaY: blur)) ->
  //     DecoratedBox(palette.glassFill, border palette.glassBorder) ->
  //       Padding -> child
}
```

That's it — 4 new widget files + 1 token file. Total new surface area for the entire design system pivot.

### 3.5 Decision rule (the canonical surface→style table)

| Surface | Style | Notes |
|---|---|---|
| Page background (auth, onboarding) | `BrandBackdrop` | Other screens still use plain `palette.background`. |
| Form shelves, OAuth row, sticky AppBars (future), sheets (future), snackbars (future) | `GlassPanel` | Containers that frame content. |
| Feed cards, stat strips, recent-enquiries previews (future migration) | `NeoSurface` (outset) | Independent content cards, need weight. |
| Primary CTA / Continue button | `NeoButton(filled: true, accent: …)` | Tactile, pressable. |
| Role tiles, selectable chips | `NeoButton(filled: false)` flipping to `inset` when selected | The depress IS the selection signal — replaces the current border-shift animation. |
| Text fields (auth + future forms) | `NeoSurface(inset: true)` around the `TextFormField` | Affordance for typing — visually recessed. |
| Avatars / brand badges | `NeoSurface` accent fill | The Hero logo badge becomes embossed. |
| Dialogs, alert sheets (future) | `GlassPanel` | Overlays. |
| Debug-only chrome (e.g. `_DebugCredentialHint`) | Stays flat | Not a production surface; styling it is noise. |

Mantra to remember the rule: **glass surrounds, neo presses.**

## 4. Screen-by-screen application (this round)

### 4.1 Onboarding (`onboarding_screen.dart`)

- Wrap body in `BrandBackdrop(orbColors: [studentPrimary, ownerAccent, teacherAccent])`.
- `_Hero`: the 64×64 logo badge becomes a `NeoSurface` with `fill: AppColors.studentPrimary` — feels embossed against the backdrop.
- The three `_RoleOption` rows wrap in a single `GlassPanel` shelf (the trio sits on one frosted card).
- Each option **becomes a `NeoButton`**:
  - Resting: outset shadows on `palette.surface` (the role tile feels lifted off the glass).
  - Selected: animates to **inset** shadows and adopts `accent.withValues(alpha: 0.08)` as fill. The current `AnimatedContainer` border-thickness animation is removed (the inset depress replaces it as the selection signal).
  - `_SelectIndicator` stays exactly as is (radio dot).
- `_ContinueButton` → `NeoButton(filled: true, accent: ctaAccent, height: 56, radius: sp16)`. Existing "animate accent to selected role" behavior preserved — `NeoButton` accepts an `accent` that can re-tween.
- Entrance animation (`EntranceFadeSlide` staggered fade-slide) preserved unchanged.

### 4.2 Login (`login_screen.dart`)

- Wrap body in `BrandBackdrop(orbColors: [studentPrimary, studentPrimaryDark])`.
- Title + subtitle stay on the open backdrop (no glass behind them — the open space lets the orbs read).
- The whole form (email + password + remember/forgot row + Sign In button) sits inside one `GlassPanel`.
- A second, shorter `GlassPanel` holds the OAuth row (Google + Facebook). The "Or" divider sits between the two glass panels (on the backdrop).
- `AuthFieldWidget` internally wraps its `TextFormField` in `NeoSurface(inset: true)` — caller API unchanged. Floating label still goes `palette.primary` when focused.
- `AuthPrimaryButton` → `NeoButton(filled: true, accent: AppColors.studentPrimary)`. Same external API.
- `AuthOAuthButton` → `NeoButton(filled: false)` with icon + label, foreground `palette.textPrimary`.
- `_RememberToggle` stays as the existing `Checkbox` (Material gives us enough; over-engineering a neo checkbox is YAGNI for this scope).
- `_DebugCredentialHint` stays flat.

### 4.3 Register (`register_screen.dart`)

Same shape as Login. The form glass panel holds: first/last name row, email, password, confirm password, Sign Up button. A second glass panel holds the OAuth row. Validators and the `kDebugMode` shortcut preserved exactly.

### 4.4 Forgot Password (`forgot_password_screen.dart`)

Same shape as Login but with one input (email) and one button. No OAuth panel. Single glass shelf.

### 4.5 Shared widgets the screens consume

`auth_widgets.dart` — both `AuthPrimaryButton` and `AuthOAuthButton` are reimplemented internally to delegate to `NeoButton`. **Their public API (constructor parameters) does not change**, so the screen call sites only need to change if a screen is being restyled this round (the only callers are the three auth screens, all in scope).

`auth_field_widget.dart` — internal implementation changes; constructor parameters and behavior unchanged.

`AuthOrDivider` — stays as a simple divider; arguably better contrast on the open backdrop than on glass. **No change** beyond color-token review.

`AuthBottomLink` — stays as is. The link sits on the backdrop, not in glass.

## 5. Skill update (`.claude/skills/flutter-ui/SKILL.md`)

The skill is rewritten in place. Specifically:

1. **Aesthetic section** — replace the "Flat, bordered surfaces — not shadows" non-negotiable with:
   - The mantra **"Glass surrounds, neo presses."**
   - The full surface→style table from §3.5 above.
   - Soft & premium calibration note: outset blur ≈ 18, dark-shadow alpha ≈ 8% / 50%; glass blur ≈ 24, fill alpha ≈ 60% / 24%. Stay under these — anything heavier reads as 2020 skeumorphism.
   - Backdrop is **opt-in** per screen; the rest of the app still uses `palette.background`.

2. **Tokens section** — add the four palette tokens and the `AppEffects` file.

3. **Copy-paste patterns section** — add four snippets:
   - `NeoSurface` (outset card)
   - `NeoSurface(inset: true)` (recessed well)
   - `NeoButton` (filled primary, unfilled secondary, role-tile selectable)
   - `GlassPanel` (form shelf)
   - `BrandBackdrop` (with orb-color guidance per screen type)
   - Remove the obsolete "Surface card" flat snippet (or keep it as "legacy flat — only when explicitly off the new system").

4. **Dark mode neo calibration** — new bullet:
   - In dark mode the "light" outset shadow is intentionally near-invisible (no real light source to fake).
   - Add a 1px `palette.borderSubtle` to dark-mode neo surfaces for edge definition.
   - Glass fill alpha is *lower* in dark (24%, not 60%) — translucent over a dark backdrop reads as smoke, not milk.

5. **Performance note** — new bullet:
   - `BackdropFilter` is GPU-heavy. **Prefer one large `GlassPanel` over many small ones.**
   - **Never** put a `GlassPanel` inside a `ListView.builder` item (scroll-time blur calls = jank). Glass is for outer chrome.
   - Orb backdrops cost too — only use `BrandBackdrop` on hero screens (auth, onboarding, future landing / empty states).

6. **Workflow** — unchanged. Add `AppEffects.*` to the "no hardcoded values" enumeration.

7. **Constraints** — unchanged. No new packages needed.

## 6. Data flow

No state changes. Everything in this spec is purely presentational:
- `BrandBackdrop` is a pure layout widget (no state).
- `GlassPanel` is a pure layout widget.
- `NeoSurface` is pure layout.
- `NeoButton` holds a *local* `pressed` boolean via `useState` — never escapes the widget.
- The four screens' existing Riverpod providers, hooks, form keys, validators, and navigation all remain untouched.

## 7. Error handling & edge cases

- **Reduce-motion users:** the press animation is 220 ms `AnimatedContainer`; if `MediaQuery.disableAnimations` is true, the `AnimatedContainer` snaps to its end state — Flutter handles this automatically. No custom guard needed.
- **Very wide windows (≥ 768 px tablet/desktop):** the auth / onboarding capped width stays at 480 px. The backdrop fills the screen behind it; the gradient + orbs scale via the `Stack`.
- **Very short windows (keyboard up):** existing `SingleChildScrollView` behavior preserved. The backdrop is fixed (doesn't scroll); the form scrolls over it.
- **Dark mode contrast:** glass fill at 24% over the dark backdrop keeps `textPrimary` (light) legible. Inputs use `palette.inputFill` not the glass fill, so input text contrast is unchanged from today. Verified by reading the existing dark palette.
- **`BackdropFilter` outside `ClipRRect` warning:** every `GlassPanel` clips first, blurs second. Implementation must keep that order to avoid the "blur leaks past the radius" rendering glitch.

## 8. Testing

No automated tests change in this round.

- The existing `test/adaptive_navigation_tooltip_test.dart` doesn't touch any of the four screens — unaffected.
- No existing widget test asserts auth/onboarding surface shape, so introducing the new primitives breaks nothing.
- **Manual verification gate** (per the workflow): launch the app in light and dark mode, walk Onboarding → Login → Forgot Password → back → Register, confirm:
  - Backdrop orbs render softly (no hard edges).
  - Glass panels read as frosted, not flat-tinted.
  - Press feedback on the Continue button + Sign In button + OAuth buttons + role tiles feels tactile (depress visible).
  - Text contrast in dark mode is unchanged on inputs and primary text.
  - Scrolling auth forms with the keyboard up isn't janky.

If on-device testing reveals jank from the orb backdrop, the immediate fallback is to drop to 2 orbs / a `sigmaX/Y: 60` blur — both are token tweaks, no architectural change.

## 9. File-level change list (concrete)

**New files:**
- `lib/core/theme/app_effects.dart`
- `lib/shared/widgets/brand_backdrop.dart`
- `lib/shared/widgets/glass_panel.dart`
- `lib/shared/widgets/neo_surface.dart`
- `lib/shared/widgets/neo_button.dart`
- `lib/shared/widgets/neo_input_decoration.dart`

**Modified files:**
- `lib/core/theme/app_palette.dart` — add the 4 new color tokens (light + dark) and lerp/copyWith entries.
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` — apply per §4.1.
- `lib/features/auth/presentation/screens/login_screen.dart` — apply per §4.2.
- `lib/features/auth/presentation/screens/register_screen.dart` — apply per §4.3.
- `lib/features/auth/presentation/screens/forgot_password_screen.dart` — apply per §4.4.
- `lib/features/auth/presentation/widgets/auth_widgets.dart` — reimplement `AuthPrimaryButton` / `AuthOAuthButton` over `NeoButton`.
- `lib/features/auth/presentation/widgets/auth_field_widget.dart` — wrap `TextFormField` in `NeoSurface(inset: true)`.
- `.claude/skills/flutter-ui/SKILL.md` — full rewrite of the aesthetic + patterns sections per §5.

**Bookkeeping:**
- New ADR: `decisions/0028-neoglass-design-system.md` recording this round's decisions + the deferred screens.
- Tick the corresponding line in `task.md` if any exists for design system work; otherwise leave alone.

## 10. Verification (closing checklist)

1. `dart format lib` — clean.
2. `flutter analyze` — *No issues found!*
3. `flutter test test/adaptive_navigation_tooltip_test.dart` — still passes.
4. `flutter build apk --debug` — builds.
5. Manual on-device or simulator walkthrough per §8.
6. ADR 0028 written and committed alongside the implementation.
