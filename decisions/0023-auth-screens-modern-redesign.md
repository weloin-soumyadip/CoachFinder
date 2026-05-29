# 0023 — Auth screens modern redesign (hero header + form)

**Status:** Superseded by [0024](0024-auth-redesign-from-spec.md) (the hero
layout was replaced by a flatter spec-driven layout; the floating-label
`AuthFieldWidget` introduced here survives, upgraded to `TextFormField`)
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (direction + scope choices) + Claude (implementation)

## Context

The user asked to make the sign-in / sign-up screens "more modern" using
"latest components". Via clarifying questions they chose a **hero-header + form**
layout and a **visual refresh only** (no behaviour changes). This was also the
first real exercise of the new `flutter-ui` project skill (decision-era skill
file at `.claude/skills/flutter-ui/`).

## Decision

Redesigned `LoginScreen` and `RegisterScreen` around a shared brand hero, with
the form card floated over it. **All behaviour is unchanged** — the
`kDebugMode` test-credential login, role passing (`initialRole` →
`landingRouteForRole`), SnackBar stubs, password-visibility toggles, the terms
checkbox, and all navigation are identical.

- **`AuthHero`** (new shared widget) — a full-bleed blue brand **gradient** band
  (`studentPrimary → studentPrimaryDark`, new token) with rounded bottom
  corners, carrying a logo badge, the CoachFinder wordmark, a title, and a
  subtitle in white. Extends under the status bar (pads via the top view inset)
  and reserves an `overlap` of bottom room. **`AuthHeroBackButton`** (new) is a
  white-on-translucent circular back button for the register hero's `leading`.
- The form section is pulled up over the hero with
  `Transform.translate(Offset(0, -sp32))` inside the scroll column, so the card
  overlaps the gradient (and the leftover phantom space becomes natural bottom
  padding).
- **`AuthFieldWidget`** modernised to a Material 3 **floating-label** filled
  field (label animates up on focus/fill) — replacing the old label-row-above
  layout; the `labelTrailing` slot was removed and login's "Forgot password?"
  moved to a right-aligned link below the password field.
- **`AuthCard`** gained a `borderSubtle` border so the floated card reads as
  distinct over the hero (no shadow — honouring the `flutter-ui` skill's
  flat/bordered rule).
- Removed the now-unused `AuthBrandingBadge` and register's `_RegisterTopBar`
  (the hero replaces both); titles/subtitles moved from the cards into the hero.

## Consequences

- The hero gradient is a fixed brand element (white-on-blue) shown the same in
  light and dark, consistent with other brand fills (NextSession card, FAB).
- `studentPrimaryDark` (#1444A8) added to `AppColors` as the gradient's second
  stop.
- No new user-facing strings; existing `loginTitle/Subtitle`,
  `registerTitle/Subtitle`, and `appName` are reused (now rendered in the hero).
- Per the user's "visual refresh only" choice, no validation / password-strength
  UX was added — that remains a future option.
- Deliberately kept the card border-only (no elevation shadow) to match the
  project design system; a soft shadow could be revisited if more "lift" is
  wanted.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build
apk --debug` → built.
