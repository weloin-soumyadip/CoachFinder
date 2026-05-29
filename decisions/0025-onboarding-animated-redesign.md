# 0025 — Onboarding animated redesign

**Status:** Accepted
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (request: "more attractive, latest UI principles, a bit of
animation") + Claude (design + implementation)

## Context

The onboarding role selector worked but looked plain: a wordmark, centered
title/subtitle, three big centered icon cards, and a Continue button. The user
asked to make it more attractive with modern UI and "a bit" of animation. The
fixed tech stack rules out animation packages (lottie/rive/flutter_animate), so
animation must be built-in.

## Decision

Rebuilt the screen (same navigation logic) around clearer hierarchy, per-role
brand colour, and tasteful motion using only Flutter built-ins + `flutter_hooks`.

- **Layout / hierarchy:** a brand hero lockup (rounded logo badge + wordmark)
  → question title → subtitle → three role options → pinned Continue CTA.
  Width-capped at 480 px and centered (tablets/wide windows); the scroll-safe
  bottom-pin behaviour (minHeight + `IntrinsicHeight` + `Spacer`) is preserved.
- **Role options** changed from large centered cards to modern **horizontal
  rows**: an accent icon tile, title + blurb, and a trailing radio/check
  indicator. Each role uses its **own brand accent** — student blue
  (`studentPrimary`), owner orange (`ownerAccent`), teacher teal
  (`teacherAccent`) — for the icon tile tint, selected border, and tint
  background. (Fixed accents are used so they read on white text and in both
  themes per [0017].)
- **Animation (built-in only):**
  - *Entrance:* one `useAnimationController` (850 ms, played once via
    `useEffect`) drives a staggered fade-and-slide-up; each element is wrapped
    in a `_EntranceItem` that maps the controller through a per-item `Interval`
    (`AnimatedBuilder` + `Opacity` + `Transform.translate` — no `CurvedAnimation`
    objects to leak, no per-child controllers).
  - *Selection:* the role row's border/tint animate via `AnimatedContainer`;
    the indicator fills and scales in a check via `AnimatedScale`
    (`easeOutBack`).
  - *CTA:* an `AnimatedContainer` whose colour animates from the disabled grey
    to the **selected role's accent** — selecting Owner turns the button orange,
    Teacher teal, etc.

## Consequences

- The Continue button is a custom `AnimatedContainer` + `InkWell` (not
  `FilledButton`) so its fill colour can tween between role accents; behaviour
  (disabled until a role is picked) is unchanged.
- No new strings or packages; `handleContinue` (persist role → `roleProvider`
  → `goNamed(login)`) is untouched.
- Establishes the reusable entrance pattern (`useAnimationController` + interval
  mapping) that other screens can adopt for tasteful load animations.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build
apk --debug` → built. (Animations verified statically/by construction, not yet
watched on a device.)
