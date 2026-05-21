# 0011 — `lib/shared/` folder and `AdaptiveNavigation` widget

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** Post-Phase-1 iteration
**Made by:** User (folder structure) + Claude (M3 adaptive behaviour, defaults)

## Context

After Phase 1 shipped, the user asked for an adaptive navigation widget that renders a `NavigationBar` on mobile widths and a `NavigationRail` on wider widths. They specified a new top-level folder `lib/shared/` with two sub-folders: `layouts/` and `widgets/`.

This diverges from the original Phase 1 folder spec, which had only `lib/core/` (with `core/widgets/` for primitives) and `lib/features/`.

## Decision

Created the folder structure:

```
lib/shared/
├── layouts/
│   └── adaptive_navigation.dart   (the new widget)
└── widgets/                       (empty for now; reserved for future use)
```

`AdaptiveNavigation` is a stateless widget that takes a list of `AdaptiveDestination`s and switches between `NavigationBar` (width < 768) and `NavigationRail` (width ≥ 768). The breakpoint is configurable via the `breakpoint` parameter.

**Breakpoint history:** Initially set to 600 (Material 3 default) on creation. Bumped to **768** when the user adopted that as the app-wide responsive breakpoint for the Home redesign. 768 keeps phone landscape on the bottom-bar layout; only tablets and desktop see the rail/sidebar.

**Bottom-nav styling:** `indicatorColor: AppColors.navIndicator` (soft green pill) and `backgroundColor: AppColors.neutralWhite` are hardcoded in the widget to match the Home screen design. Both student and owner shells inherit this — if owner needs a different accent later, parameterise.

`_StudentShell` (4 tabs) and `_OwnerShell` (3 tabs) in `app_router.dart` were both refactored to consume `AdaptiveNavigation`. The previous hardcoded `NavigationBar` is gone from `app_router.dart`.

Selected confirmations from the user (via the `AskUserQuestion` flow):

- File path: `lib/shared/layouts/adaptive_navigation.dart`
- Adaptation rule: 2 breakpoints, NavigationBar / NavigationRail
- Owner shell: also swapped to use `AdaptiveNavigation`
- Scope: shell only — Home / Search / Saved / Profile screens stay as placeholders

## Distinction from existing `core/widgets/`

The original Phase 1 spec already had a "shared widgets" location at `core/widgets/` (intended for primitives: `app_button`, `app_text_field`, `loading_shimmer`, `empty_state_widget` — all currently skeletons).

Going forward:

- `core/widgets/` — atomic primitives (button, input, shimmer, empty-state) used across the whole app.
- `shared/layouts/` — layout-shaped widgets that wrap a `child` and arrange chrome around it (navigation, app frames, master/detail).
- `shared/widgets/` — composite UI pieces that don't fit "atomic primitive" and aren't layouts. Empty for now; will hold things like a banner, a card variant family, etc., as they emerge.

No migration of existing `core/widgets/` is planned in this change. If the categories collapse in practice, a future decision record will consolidate.

## Alternatives considered

- **Put `AdaptiveNavigation` under `core/widgets/`.** Rejected: the user explicitly asked for `lib/shared/`.
- **3-breakpoint M3 adaptive (Bar / Rail / Drawer).** Rejected by the user — they picked the simpler 2-breakpoint version.
- **Custom design (wait for screenshots).** Rejected by the user — they wanted the M3 default for now.

## Consequences

- Single source of truth for nav chrome across both roles. Changing the breakpoint, label style, or selection accent now needs one edit.
- Future Claude reading the codebase will see two shared-widget locations (`core/widgets/` and `shared/widgets/`) and needs this record to understand why.
- `NavigationRail` is only triggered at >=768 px (updated from 600 dp). Phone portrait and landscape both stay on the bottom bar. Tablets and desktop see the rail.
