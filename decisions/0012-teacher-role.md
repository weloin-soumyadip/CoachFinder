# 0012 — Teacher role (third role)

**Status:** Accepted
**Date:** 2026-05-25
**Phase:** Post-Phase-1 iteration
**Made by:** User (role meaning, tabs, scope) + Claude (accent, routing/layout mechanics)

## Context

CoachFinder shipped with two roles — Student and Coaching Owner — wired through
`role_provider.dart`, a binary redirect guard in `app_router.dart`, two
`ShellRoute`s, and two onboarding role cards. The user asked to add a third
role, **Teacher**, selectable on onboarding and driving its own post-login
shell.

## Decision

### Role meaning — hybrid

A teacher is a **hybrid**: they can operate as an independent tutor (be
discovered and receive enquiries directly) **and/or** be associated with an
organization / coaching center. This is why their shell carries both
supply-side ops (Enquiries, Schedule) and a discovery surface (Search, for
finding orgs to associate with) — not a student-style "browse coaches" search.

### Tabs (5)

`Home · Search · Enquiries · Schedule · Profile`

- **Home** — overview (upcoming sessions, quick stats).
- **Search** — find/browse organizations & centers to associate with.
- **Enquiries** — students who contacted the teacher directly (solo operation).
- **Schedule** — availability / upcoming sessions.
- **Profile** — public listing + settings.

Five is the practical maximum for a `NavigationBar`; on the rail (≥768 px) it is
comfortable. `AdaptiveNavigation` already supports ≥2 destinations, so no widget
change was needed.

### Accent — teal `#0D9488`

Each role has its own accent (Student `#1A56DB`, Owner `#E05A2B`). Teacher uses
teal `#0D9488` with a light tint `#CCFBF1`, both added to `AppColors`. Teal is
clearly separable from the other two at a glance and avoids colliding with the
existing price-green.

### Routing

Five flat paths under a shared `/teacher-` stem:
`/teacher-home`, `/teacher-search`, `/teacher-enquiries`, `/teacher-schedule`,
`/teacher-profile`. A new `_TeacherShell` mirrors `_StudentShell` /
`_OwnerShell`.

**Redirect guard refactor.** The guard was binary
(`role == roleStudent ? '/home' : '/dashboard'`), which would have funneled a
teacher into the student home. Replaced with:

- `_homeFor(role)` → the role's shell-home path (single place to land/bounce).
- A generalized cross-shell guard: *"if the location belongs to a shell that
  isn't this role's, bounce to this role's home."* Scales to N roles and fixes
  the latent any-non-student-becomes-student bug.

`landingRouteForRole(role)` was added to `app_routes.dart` as the single source
of truth for the post-auth landing **route name**, shared by the login and
register dev-shortcuts (the router keeps its own path-based `_homeFor`).

### Onboarding layout

Adding a third role card overflows the previous non-scrolling
`Column` + `Spacer` on small phones. The onboarding body was converted to the
standard scroll-safe pattern
(`LayoutBuilder` → `SingleChildScrollView` → `ConstrainedBox(minHeight)` →
`IntrinsicHeight` → `Column` + `Spacer`): the Continue button stays pinned to
the bottom when there is room and the screen scrolls when content is tall.

### Scope

**Plumbing + placeholders only.** Role constant, third onboarding card, teacher
routes, the teacher shell, and five placeholder screens (each a
`HookConsumerWidget` showing its tab label + "Coming soon" in the teacher
accent). Real teacher screen UIs are built later, one at a time, from designs —
matching the established flow.

## Alternatives considered

- **Teacher = staff-only (managed under an Owner's center).** Rejected: the user
  said a teacher can also operate individually.
- **Teacher = student-like discovery user.** Rejected for the same reason.
- **3-tab set (`Home · Search · Profile`).** The user initially sketched this but
  chose the fuller 5-tab set to cover the hybrid model.
- **Indigo / purple / green accent.** Rejected in favor of teal (indigo too close
  to student blue; green collides with price-green).

## Consequences

- The redirect guard now scales to any number of roles via `_homeFor` + the
  generalized cross-shell check; adding a future role is mostly additive.
- Two helpers map role → destination: `landingRouteForRole` (route **name**, for
  `goNamed`) and `AppRouter._homeFor` (path, for redirect). They must be kept in
  sync; both live for different call APIs.
- `app_routes.dart` now imports `role_provider.dart` (one-directional, no cycle)
  to back `landingRouteForRole`.

## Follow-ups

- **Backend register payload** must accept `"teacher"`. Auth is still stubbed
  (`phase1-dev-token`), so nothing calls the backend yet — wire this when the
  real auth contract lands (tracked with the existing `TODO(real-auth)`).
- Teacher feature folders currently hold only `presentation/screens/`. Their
  `data/` layers (models/controllers/repository) come with the real screens.
