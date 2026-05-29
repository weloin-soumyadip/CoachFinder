# 0027 — Floating bottom-nav restyle (from external spec)

**Status:** Accepted (supersedes the bottom-bar styling in the tab-bar work of
decision-era 0011/0016 notes; the rail is unchanged)
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (external navbar spec + 3 reconciliation choices via `/flutter-ui`)
+ Claude (adaptation)

## Context

The user supplied a prescriptive spec for a "custom bottom navbar" (mint-green
page, white floating card with drop shadows, top-right `+` FAB, an active-tab
name label, `StatefulWidget` + `IndexedStack`, files at `lib/widgets/` +
`lib/screens/`, `print()` callbacks) and asked to "change our existing
bottomNavbar to this".

Taken literally this would break the app: our bottom nav is
`AdaptiveNavigation`, driven by **go_router across three role shells** and
swapping to a **NavigationRail ≥768 px**; an `IndexedStack`/`StatefulWidget`
replacement bypasses routing, the role shells, the rail, deep-links and the
redirect guards. The spec also conflicts with the `flutter-ui` skill (off-brand
green, drop-shadows vs the flat rule, hardcoded colours, `print` fails analyze)
and its tabs (Home/Chat/Favourites + "Ahmed Emon") don't match the real
per-role tabs.

Via three clarifying questions the user chose: **restyle the existing nav**,
**brand + theme-aware** colours, and **real tabs, no FAB/label**.

## Decision

Restyled only the compact-width branch of `AdaptiveNavigation` into a floating
rounded card; kept everything else (go_router, all role shells, the rail,
routing/redirects, the real per-role destinations).

- The bottom bar moved from a Material `NavigationBar` to a custom
  `_FloatingBottomBar`: a `palette.surface` card with `sp24` rounded corners,
  horizontal + bottom margins (so it floats), and a soft shadow
  (`neutralBlack` @ 0.08, blur 20, offset (0,4)) — a deliberate, documented
  exception to the skill's "no shadows" rule because a floating bar needs
  elevation to read. It stays in the `bottomNavigationBar` slot (not a Stack
  overlay) so the Scaffold still reserves its height and screen content is
  never hidden behind it.
- Icon-only, no labels / no indicator pill: active = `palette.textPrimary`
  filled icon at size 26, inactive = `palette.iconFaint` outlined icon at 24,
  **cross-faded** on change via `AnimatedSwitcher` (200 ms). Even spacing via
  `Expanded` tap targets. Theme-aware (works in light and dark).
- The `NavigationRail` branch (wide screens) is unchanged.

### Not done (per the user's choices / conventions)

Mint-green palette, green FAB, top-right `+` FAB, the active-tab name label,
`lib/widgets/` + `lib/screens/`, `StatefulWidget` + `IndexedStack`, and
`print()` were all **declined** — they'd break the architecture and the design
system. No new files; the change is contained to `adaptive_navigation.dart`.

## Consequences

- The earlier tooltip-suppression workaround is moot (no `NavigationDestination`
  / no tooltips now); the nav test was updated to assert the icon-only bar
  (and to supply `AppTheme` so the bar's `context.palette` resolves).
- All three role shells get the floating look for free (shared widget).
- Drive-by: removed now-dead `_TopBar` + an unused `mockUser` import in
  `search_screen.dart` (a commented-out top bar had left analyzer warnings) to
  keep `flutter analyze` clean.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* ·
`flutter test test/adaptive_navigation_tooltip_test.dart` → passed ·
`flutter build apk --debug` → built. (Look/motion verified by construction, not
yet watched on a device.)

## Update (2026-05-27) — bar overlays content (`extendBody`)

Follow-up ("floating behind, all contents visible"): the compact Scaffold now
sets `extendBody: true`, so the page extends **behind** the floating bar instead
of sitting in a reserved slot. Because the bar is opaque, a shared
`floatingNavClearance(BuildContext)` helper (in `adaptive_navigation.dart`,
width-aware: full bar footprint + system inset on mobile, just the inset on the
wide rail) was added and applied as the bottom scroll padding on every
scrollable shell screen (Home, Search, Saved + the owner/teacher dashboards,
inboxes, manage-center, profiles, and the edit forms) so their last content
clears the bar. Bottom-anchored elements were lifted too: Home's chat FAB and
the enquiry-detail reply box now sit `floatingNavClearance` above the bottom.

## Update (2026-05-27) — wide-screen rail matched to the bar

Follow-up ("make the desktop nav look like this"): the `NavigationRail` branch
(initially left as the old labelled rail + `VerticalDivider`) was replaced with
a `_FloatingSideRail` — a floating, rounded `palette.surface` card pill on the
left, **icon-only**, reusing the same `_NavIcon` (active `textPrimary` filled,
inactive `iconFaint` outlined, `AnimatedSwitcher` cross-fade) and the shared
`_navShadow`. `_NavIcon` was made orientation-agnostic (the bottom bar wraps it
in `Expanded`; the rail in a sized box within a centered `Column`). The Material
`NavigationRail` + divider and the now-unused `ColorScheme` local were removed,
so both layouts share one floating-card aesthetic. Re-verified (analyze, nav
test, build).
