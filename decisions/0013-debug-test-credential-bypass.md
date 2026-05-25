# 0013 — Debug-only test-credential sign-in bypass

**Status:** Accepted
**Date:** 2026-05-25
**Phase:** Post-Phase-1 iteration
**Made by:** User (mechanism, credential, debug-only) + Claude (constant extraction, register safety-gate)

## Context

Real authentication isn't built yet. To exercise the role-gated UI end-to-end,
the login and register buttons previously accepted **any** input, wrote a
placeholder JWT (`phase1-dev-token`), and navigated into the role's shell. The
user asked for a more deliberate testing mechanism: a known **test credential**
that the sign-in logic recognises.

## Decision

### Login — gated to a fixed test credential, debug only

`handleLogIn` now compares the typed email/password against a hard-coded test
account and only signs in on an exact match **in debug builds**:

- Credential: `test@gmail.com` / `test-password`, stored as
  `DevCredentials.testEmail` / `DevCredentials.testPassword` in
  `lib/core/constants/dev_credentials.dart` (named constants, not magic
  strings).
- Match is gated by `kDebugMode`, so release builds never accept it.
- Email comparison is case-insensitive and trimmed.
- On non-match: in debug, show `loginInvalidCredentials`
  ("Invalid email or password."); in release, show `stubAuthNotImplemented`
  (the bypass is fully disabled, real auth doesn't exist).
- On match: write the `phase1-dev-token` JWT and land via
  `landingRouteForRole(role)` using the **onboarding-chosen** role (per the
  user's choice — the bypass does not pick a role itself).

### Register — same debug gate, for safety

The register dev-shortcut was a latent backdoor: it accepted any input and
entered the app in **all** builds. It is now wrapped in `kDebugMode` too — in
release it shows `stubAuthNotImplemented` and does nothing. This was beyond the
literal sign-in request but follows directly from the user's "debug builds only"
preference; it keeps register from shipping a bypass. (Register still accepts
any input in debug, since it represents account *creation*, not signing in with
the existing test account.)

## Alternatives considered

- **One-tap "Use test account" button / pre-filled fields / dev quick-switch.**
  Rejected by the user — they want the credential typed into the normal form and
  checked in the sign-in logic.
- **Let the bypass choose the role.** Rejected — use the onboarding role.
- **Always-visible bypass.** Rejected — debug-only.
- **Inline magic strings in `handleLogIn`.** Rejected in favor of named
  `DevCredentials` constants for clarity and single-point removal.

## Consequences

- Testing flow: pick a role on onboarding → Continue → on login type
  `test@gmail.com` / `test-password` → Log In → land on that role's shell.
- The bypass is concentrated behind `DevCredentials` + `kDebugMode` and tagged
  with `TODO(real-auth)`, so it is removed in one place when real auth lands.
- `login_screen.dart` and `register_screen.dart` now import
  `package:flutter/foundation.dart` (for `kDebugMode`) — this Flutter version
  does not re-export it via `material.dart`.

## Follow-ups

- Remove `DevCredentials` and both `TODO(real-auth)` shortcuts when real
  authentication is wired (ties into the same follow-up noted in
  [0012](0012-teacher-role.md)).
- A debug-only hint showing the test credential under the Log In button is
  built (`_DebugCredentialHint`, gated by `kDebugMode`).
