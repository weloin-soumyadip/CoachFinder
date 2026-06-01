# 0033 — Branded splash screen as the launch route

**Status:** Accepted
**Date:** 2026-05-29
**Phase:** Round 5 — first widget rendered on launch is a brand-correct
splash that hides the auth `/me` bootstrap latency.
**Made by:** User (one-line directive: "add a splash screen which will
load first when the app will load") + Claude (design + implementation +
code-reviewer subagent + receiving-review fixes).

## Context

ADR 0032 added `AuthController.bootstrap()` which calls
`GET /api/auth/me` on launch to validate the cached access token and
refresh the in-memory `User` + role from the server. The bootstrap can
take anywhere from ~50 ms (cached, fast network) to several seconds
(slow / failing network), and the router previously sent users straight
to the shell (or onboarding) — meaning a returning user could see the
shell flicker before either a valid `User` showed up or a 401 bounced
them to login.

The user asked for a splash screen as the first thing rendered on
launch. The aim is twofold:

1. Brand-correct reveal — first impression matches the auth /
   onboarding neoglass aesthetic.
2. Hide the `/me` round-trip behind the splash so the user doesn't see
   stale shell chrome before their session is validated.

## Decision

Add a `SplashScreen` as the initial route. It watches
`authControllerProvider`, waits for `bootstrap` to settle, then
`goNamed`s into the right first screen.

### Routing behaviour

- `AuthState.authenticated` + role → role's shell home via
  `landingRouteForRole(role)`.
- `AuthState.unauthenticated` → `login` if a role is cached, else
  `onboarding`.
- `bootstrap` stalled (`initial` after `loading`, or a 4 s safety
  timeout) → trust `LocalStorage`: cached session → role shell;
  cached role only → login; otherwise onboarding.

### Timing

- **Min-show**: 600 ms after bootstrap settles. Without it, the splash
  flickers on cold starts with no cached session (which settle
  synchronously — see below).
- **Max-wait**: 4 s safety net. Covers the documented network-failure
  stall path from ADR 0032 (`bootstrap` returns to `initial` after a
  non-401 failure; no further transition is observable).

### Visual

- `BrandBackdrop` with the brand-blue orb pair
  (`studentPrimary` / `studentPrimaryDark`).
- Centered `NeoSurface` framing an `Icons.school_outlined` brand mark.
- App name + tagline + a small `CircularProgressIndicator`.
- Stays on the neoglass design system; no new design tokens added.
  Three local visual sizes (`_logoSize` 56, `_spinnerSize` 28,
  `_spinnerStroke` 2.5) are private statics so the build body has no
  bare numbers.

### Code structure

- **NEW** `lib/features/splash/presentation/screens/splash_screen.dart`.
- **MODIFIED** `lib/core/router/app_router.dart`:
  - `initialLocation` flipped from `/onboarding` to `/splash`.
  - Redirect now early-returns `null` when `loc == '/splash'`. The
    splash owns its own navigation.
  - New `GoRoute('/splash')` at the top of the routes list.
- **MODIFIED** `lib/core/router/app_routes.dart` — added
  `AppRoutes.splash = 'splash'`.
- **MODIFIED** `lib/core/constants/app_strings.dart` — added
  `splashTagline`.
- `lib/main.dart` left untouched — its `useEffect`-driven
  `ref.read(authControllerProvider)` (ADR 0032) is still useful as a
  deep-link safety net for entry routes that bypass `/splash`.

### Out of scope (deliberate)

- A custom Android `LaunchTheme` / Lottie pre-Flutter splash. The
  Flutter splash is enough.
- `flutter_native_splash` package — adds a dependency for one screen.
- A "skip splash" debug flag.
- Animating the brand mark (entrance pulse, etc.). Punt to design.

## Code review

The reviewer subagent (`general-purpose` with the inline
`flutter-code-reviewer` brief; the custom subagent type isn't
auto-discovered in this runtime) flagged 5 findings; all validated
against the codebase and applied:

1. **HIGH — cold-start stall.** `AuthController.bootstrap()` is `async`
   but its no-cached-id branch reaches `state = unauthenticated`
   *synchronously* (no `await` before that line). Dart's async function
   body runs synchronously up to the first `await`, so the provider
   factory returns the controller already in `unauthenticated`. The
   splash's `ref.listen` doesn't fire for the initial value, so on a
   fresh install the splash would sit on the 4 s safety timer.
   **Fixed** with a `useEffect` that checks for an already-terminal
   `authState` at mount and schedules the same `_minShow` + navigate.
2. **HIGH — disposal hazard.** The original `_routeFromHere(context,
   ref)` read `authControllerProvider` and `roleProvider` from `ref`
   inside a `Future.delayed` callback. After widget disposal the
   captured `WidgetRef` is no longer safe to use. **Fixed** by
   capturing `auth` and `cachedRole` at scheduling time (when `ref` is
   definitely live) and passing them as parameters — `_routeFromHere`
   no longer takes a `WidgetRef`.
3. **MEDIUM — explicit timer cancel.** The max-wait `Timer` continued
   to tick after the `ref.listen` path had already navigated. **Fixed**
   by storing the timer in `useRef<Timer?>` and cancelling it from
   `navigateNow`.
4. **MEDIUM — misleading watch comment.** The original justified the
   `ref.watch` as "rebuilds when bootstrap finishes," but the rebuilds
   are what the new cold-start `useEffect` rides on, not what drives
   navigation. **Fixed** by rewriting the comment.
5. **LOW — bare numeric sizes.** 56 / 28 / 2.5 violated the project's
   "no bare numbers in body" rule. **Fixed** with the `_logoSize` /
   `_spinnerSize` / `_spinnerStroke` private constants (judgement
   call: these don't belong in the shared `AppSpacing` / `AppEffects`
   token sets since they're splash-specific).

## Consequences

- The first frame on every launch is the branded splash, regardless of
  cached state. No more flicker of cached shell chrome before `/me`
  validates.
- Cold start with no cached session settles in ~600 ms (min-show only,
  bootstrap completes synchronously).
- Cold start with a cached valid token settles in `min-show +
  /me-latency` (~700–1200 ms typically). The user sees their shell
  with a fresh `User` from the server.
- Cold start with a stale token: 401 in bootstrap → splash → login
  (`min-show + /me-latency`).
- Cold start while offline: bootstrap stalls at `initial` (per ADR
  0032); the 4 s safety timer fires; splash falls back to cached
  `LocalStorage` state. Worst case is 4 s of brand before the cached
  shell. Tradeoff is acceptable — the cached state is genuinely
  unknown-valid until the next user action.
- Deep links to other routes (`/home`, `/dashboard`, etc.) still work
  — the redirect doesn't bounce them to the splash; `main.dart`'s
  `useEffect` continues to fire bootstrap as the deep-link safety net.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → 15 / 15 pass (no new tests; the splash is presentation
and per ADR 0029/0030 precedent we don't add widget tests for screens
of this complexity). Manual launch-flow smoke testing deferred to the
user.
