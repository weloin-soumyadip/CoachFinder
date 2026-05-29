# 0026 — Student Home animation + shared entrance widget

**Status:** Accepted
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (`/flutter-ui` → "modify the student dashboard, add animation
effects and modern UI principles") + Claude (implementation)

## Context

The user asked (via the `flutter-ui` skill) to add animation + modern polish to
the "student dashboard". The student has no screen literally named *dashboard* —
the equivalent is the **Home** feed (`home_screen.dart`). The onboarding redesign
([0025]) had introduced a staggered fade/slide entrance via a private
`_EntranceItem`; reusing that here is the obvious move.

## Decision

Animated the Home feed using built-ins only (no packages), and **extracted the
entrance helper into a shared widget** so Home and onboarding share one
implementation.

- **`lib/shared/widgets/entrance_fade_slide.dart`** (new) — `EntranceFadeSlide`
  ({`animation`, `start`, `end`, `child`, `offsetY`}): maps a driving
  `AnimationController` through a per-item `Interval` to a fade + slide-up
  (`AnimatedBuilder` + `Opacity` + `Transform.translate`; no `CurvedAnimation`
  allocations). Onboarding was refactored to use it (its private `_EntranceItem`
  removed — behaviour identical).
- **Home entrance:** `HomeScreen` now creates a `useAnimationController` (900 ms,
  played once via `useEffect`) and wraps each section
  (top bar → greeting → next-session card → trending → recommended → personalized
  → chat FAB) in `EntranceFadeSlide` with staggered `start`s, so the feed
  cascades in on load.
- **Animated progress ring:** `_PersonalizedPathCard`'s `_ProgressRing` now uses
  `TweenAnimationBuilder` to animate the arc fill **and** count the percentage up
  from 0 on first build.
- **Modern principle — width cap:** the scroll content is wrapped in
  `Center` + `ConstrainedBox(maxWidth: 720)` so the feed is capped and centered on
  tablets / wide windows (matching the owner dashboard and the skill's guidance).
  The chat FAB stays pinned to the screen edge.

## Consequences

- All content/behaviour is unchanged (still fixture-backed; taps are the same
  placeholders); this is purely visual + motion.
- `EntranceFadeSlide` is now the canonical entrance animation; future screens
  that want a load animation should use it rather than re-implementing.
- The FAB keeps its Material `elevation` (idiomatic for a FAB; the skill's
  "no shadows" rule targets cards, not FABs).

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build
apk --debug` → built. (Motion verified by construction, not yet watched on a
device — durations/stagger are easy to tune.)
