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
  (outset shadows; inset variant uses darker `inputFill` + hairline border
  because `BoxShadow.inset` isn't available on this Flutter version),
  `NeoButton` (pressable; settled state drops shadows + tinted bg + accent
  border on `selected`). One helper: `neoInputDecoration`.
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
- Inset variant: darker `inputFill` background + 1 px `borderSubtle` hairline
  (no inverse shadows; the Flutter version doesn't support `BoxShadow.inset`).
- Glass fill: alpha 60 % (light) / 24 % (dark); blur sigma 24.
- Neo press animation: 220 ms `easeOut` shadow swap; pressed / selected
  states drop the outset shadows entirely (settles into the surface).
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
- The original spec called for `BoxShadow(inset: true)` for the recessed
  well; the project's Flutter version doesn't support that parameter, so
  the inset variants of `NeoSurface` and `NeoButton` use a darker fill +
  hairline border (and, for `NeoButton`, an accent-colored border + tinted
  background on `selected`). Functionally equivalent visual signal, no
  perf cost.
- Manual visual verification is the gate for this round (no widget tests
  assert surface shape).

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* ·
`flutter test test/adaptive_navigation_tooltip_test.dart` → passed ·
`flutter build apk --debug` → built. Manual walk Onboarding → Login →
Forgot Password → back → Register in light and dark to verify the orb
backdrop reads softly, glass panels read frosted, neo press feedback feels
tactile, and input contrast in dark mode is unchanged.
