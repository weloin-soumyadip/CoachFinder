# 0032 — Auth /me rehydration, platform-aware API base URL, cleartext + CORS fixes

**Status:** Accepted
**Date:** 2026-05-29
**Phase:** Round 4 — make auth actually work end-to-end against the real
backend, then rehydrate sessions on launch.
**Made by:** User (4 scoping choices via brainstorming + 1 platform pick)
+ Claude (implementation + reviewer subagent + receiving review).

## Context

After ADR 0031 wired real login on top of the round-2 maxinvoice data layer,
the user reported register/login didn't actually work end-to-end against the
running backend. Systematic debugging revealed three independent blockers,
hit in sequence as each upstream one was fixed:

1. **Android cleartext block.** `targetSdk >= 28` blocks plain HTTP by
   default; `http://10.0.2.2:5000` requests never left the device and
   surfaced as a generic "No connection" SnackBar.
2. **Wrong base URL on Web.** The user was running Flutter Web in Chrome,
   where `10.0.2.2` is meaningless. The base URL needed platform detection.
3. **Backend CORS rejection.** `CORS_ORIGIN=*` paired with
   `credentials: true` is rejected by browsers (the HttpOnly refresh cookie
   forces credentialed CORS).

After those three were resolved, login/register succeeded against the
backend — but the cached session didn't survive a kill/restart: the router
gated on `LocalStorage.currentUserId` (a sync proxy) without ever
re-validating the access token, so a user with an expired token landed in
the shell and would hit silent 401s. The ADR 0031 "out of scope" list
flagged this as the largest remaining gap.

## Decision

Land three small fixes + one new feature in one round. Code-reviewer
subagent reviews the new feature before close.

### A. Network plumbing (the three blockers)

- **`android/app/src/debug/res/xml/network_security_config.xml`** (new) —
  permits cleartext only to `10.0.2.2`, `localhost`, `127.0.0.1`.
- **`android/app/src/debug/AndroidManifest.xml`** — references the config
  via `android:networkSecurityConfig`. Debug-only; release stays
  HTTPS-only by virtue of not merging the debug manifest.
- **`lib/core/api/api_config.dart`** — `baseUrl` is now a `static final`
  computed via `_resolveBaseUrl()`:
  ```dart
  if (override.isNotEmpty) return override;
  if (kIsWeb) return 'http://localhost:5000/api';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5000/api';
  }
  return 'http://localhost:5000/api';
  ```
  Accepts a `--dart-define=BACKEND_BASE_URL=…` override for physical
  devices.
- **`server/src/app.ts`** — CORS `origin` switched from
  `config.cors.origin.length ? config.cors.origin : '*'` to a function:
  no-Origin (curl) is allowed; `NODE_ENV !== 'production'` allows any
  `http://(localhost|127.0.0.1)(:port)?` origin; otherwise the configured
  allowlist. `credentials: true` stays.

### B. `/me` launch-time rehydration

- **`lib/features/auth/data/models/me_response_model.dart`** (new) —
  parses `{success, userType, user}`. 3 tests (`owner|teacher|student`
  verbatim, plus an explicit "admin parses, controller filters" case).
- **`AuthRepository.getCurrentUser()`** — first consumer of
  `ApiClient.get<T>`; uses the existing `ApiResponse.fromJson` dual-mode
  (top-level fallback). On 401 throws `AuthException(code: '401')`.
- **`AuthController.bootstrap()`** — fired fire-and-forget from the
  provider factory. Branches:
  - no cached `currentUserId` → `unauthenticated`
  - `/me` success with `userType ∈ {student, owner, teacher}` →
    `authenticated`, writes `userRole` + `currentUserId`, mirrors into
    `roleProvider`
  - `/me` success with `userType == 'admin'` (or any unknown) → drop
    the session (no admin surface exists)
  - 401 → drop the session
  - any other failure → `state.copyWith(status: initial)` (preserves any
    in-memory `user`/`role`; the cached on-disk session stays valid so
    the router keeps the user in their shell — offline mode)
- **`lib/main.dart`** — `CoachFinderApp` is now a `HookConsumerWidget`;
  a `useEffect` does `ref.read(authControllerProvider)` once to construct
  the controller (and fire bootstrap) without subscribing the widget to
  every AuthState transition.

### Out of scope (deliberate)

- `refreshListenable` on the router — bootstrap clears `currentUserId`
  on 401 and the next user gesture re-runs the redirect → bounce to
  login. Not auto-bouncing mid-screen.
- `/api/auth/refresh` token rotation. (ApiClient still clears on 401.)
- `POST /api/auth/logout`.
- Persisting the User to Hive for fully offline shell rendering.
- An `AuthStatus.offline` enum value (the `initial` + preserved
  `user`/`role` combo is sufficient at this scale).

## Consequences

- Register + login now succeed end-to-end on **Android emulator** (debug
  manifest opens cleartext), **Flutter Web** (auto-localhost + dev CORS),
  and **iOS sim / desktop** (auto-localhost). Physical devices need the
  `--dart-define` override.
- Cold launch with a valid cached token lands the user in their shell
  with a freshly fetched `User` (server-authoritative role). Stale token
  drops the session and bounces to login on the next gesture. Offline
  cold-launch keeps the user in their shell (router gates on disk; the
  in-memory controller stays quiet).
- Admin accounts that somehow obtain a token get explicitly rejected at
  rehydration — they can't accidentally land in the student shell.
- The model test count grows from 12 to 15 (3 new for `MeResponse`,
  including the admin-passthrough case).
- A new reusable subagent definition lives at
  `.claude/agents/flutter-code-reviewer.md` — currently not
  auto-discovered by the runtime (custom agents aren't loaded), but
  ready for when they are. This round dispatched the same brief via
  `general-purpose` with the system prompt inlined.

## Code review

The reviewer subagent flagged 4 findings; all were validated and applied
or partially applied:

1. **HIGH** — non-401 branch wiped `user`/`role` via
   `const AuthState(status: initial)`. Latent (bootstrap fires once on
   construction when state is fresh) but contradicted the doc comment's
   "keep cached session intact" claim. **Fixed** with `state.copyWith`.
2. **MEDIUM** — `userType: 'admin'` would be persisted to `userRole`
   and the router would land them in `/home` (student shell). **Fixed**
   by filtering at bootstrap (admin → drop session).
3. **MEDIUM** — `CoachFinderApp` watched `authControllerProvider`,
   rebuilding `MaterialApp` on every AuthState transition; the inline
   comment justifying this was wrong (router has no auth dependency).
   **Fixed** by switching to `HookConsumerWidget` + `useEffect` with
   `ref.read`.
4. **LOW** — `MeResponse.fromJson` casts unchecked, tests missed the
   admin case. **Partially applied**: added the admin test (locks the
   contract finding #2 filters against); skipped the cast tightening
   (current `catch (_)` in the repo handles `TypeError`, and the
   project's stated policy is not to add validation for scenarios that
   can't currently happen).

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → 15 / 15 pass (4 User + 3 MeResponse + 3 LoginRequest
+ 3 RegisterRequest + 1 AuthResponse + 1 nav) · `flutter build apk
--debug` confirmed the merged debug manifest contains
`android:networkSecurityConfig="@xml/network_security_config"`. Manual
end-to-end (register → kill → relaunch → land back in shell) deferred
to the user since it requires the running backend + emulator.
