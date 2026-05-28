# 0031 — Auth login wiring (round 3)

**Status:** Accepted
**Date:** 2026-05-28
**Phase:** Round 3 — login wiring on top of round 2's maxinvoice data layer
**Made by:** User (3 scoping choices via brainstorming) + Claude (spec, plan,
implementation).

## Context

Round 2 (ADR 0030) pivoted the auth data layer to the maxinvoice pattern
(LocalStorage + TokenStorage + ApiClient + AuthRepository throwing
AuthException + StateNotifier<AuthState> + AuthStatus enum) and wired
signup against the real backend. LoginScreen still ran a `kDebugMode`
test-credential shortcut that fabricated a session for development.

The user asked to wire real login next. Three scoping choices via
brainstorming: (1) remove the `kDebugMode` shortcut entirely, (2) lower
the password validator from >= 8 to >= 6 to match the backend's register
endpoint, (3) remove the inert "Remember for 30 days" toggle.

## Decision

Mirror the signup wiring on top of the existing round-2 infrastructure.

- **`LoginRequest`** (`lib/features/auth/data/models/login_request_model.dart`)
  — new model with `{userType, email, password}` + `toJson`. Three
  tests in `test/features/auth/data/models/login_request_model_test.dart`
  matching the register-request pattern.
- **`AuthRepository.login(LoginRequest)`** — added directly after
  `register()`. Same try/catch shape: `ApiClient.rawPost` →
  `ApiResponse.fromJson` → check `success` → persist tokens → return
  `AuthResponse`. Catches `ApiError` → throws `AuthException`.
- **`AuthController.signIn({email, password, role})`** — added directly
  after `register()`. Same `state = Loading → Authenticated|Error`
  pipeline; on success writes `userRole` + `currentUserId` to
  `LocalStorage` and updates `roleProvider`.
- **`AuthValidators.password`** — min length 8 → 6. The `AppStrings`
  constant `validatorPasswordShort` message updated to "at least 6
  characters." Aligns with the backend's register validator.
- **`LoginScreen`** — full rewrite. Drops the `kDebugMode` block,
  `_RememberToggle` widget, `_DebugCredentialHint` widget. Adds
  `ref.listen<AuthState>` like the register screen (`AuthStatus.authenticated`
  → `goNamed`, `AuthStatus.error` → SnackBar). The Sign In button uses
  `AuthPrimaryButton.isLoading`. The Remember/Forgot row becomes just a
  right-aligned "Forgot password?" link.
- **Cleanup**: deleted `lib/core/constants/dev_credentials.dart` (no
  remaining consumers) and four unused `AppStrings`:
  `loginInvalidCredentials`, `stubAuthNotImplemented`,
  `loginTestAccountLabel`, `authRememberMe`.

### Out of scope (deliberate)

- `/api/auth/refresh` rotation (ApiClient still clears on 401).
- `/api/auth/me` rehydration on launch.
- `POST /api/auth/logout` (local-only sign-out via `TokenStorage.clearTokens`).
- Social login (Google/Facebook stub SnackBars retained).
- "Remember 30 days" persistence behaviour — toggle removed entirely
  rather than wired, since the refresh-token cookie already gives
  persistent sessions and the backend has no per-session lifetime
  parameter.

## Consequences

- Real login works end-to-end against the running backend; a user who
  registered in round 1 / 2 can re-sign in after sign-out or app restart.
- The client-side validator no longer false-rejects 6-7 char passwords
  the backend accepts on register.
- Test-credential offline path is gone. Iterating on the login UI now
  requires either the backend running or a mock. Acceptable — the same
  is true for register since round 1.
- The 9 model tests grow to 12 (3 new for `LoginRequest`). No widget
  tests added; the screen + repo + controller wiring stays on manual
  verification (ADR 0029 / 0030 precedent).
- Future rounds (`/refresh`, `/me`, server `/logout`) slot in by adding
  methods to `AuthRepository` and `AuthController`. Nothing in this
  round needs re-plumbing.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → 12 / 12 pass (4 User + 3 RegisterRequest + 3 LoginRequest
+ 1 AuthResponse + 1 nav) · `flutter build apk --debug` → built · manual:
sign in with a round-2-registered account → lands on role shell; wrong
password → "Invalid credentials" SnackBar; kill backend → offline
SnackBar.
