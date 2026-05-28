# 0029 — Auth data layer + signup wiring (round 1)

**Status:** Accepted
**Date:** 2026-05-28
**Phase:** First real-backend wiring in the Flutter app
**Made by:** User (request + 3 scoping choices via brainstorming) + Claude
(design, spec, plan, implementation).

## Context

The `lib/features/auth/data/` tree was scaffolded at project setup but
every file was `// TODO: implement`. The `RegisterScreen` shipped with a
`kDebugMode` JWT shortcut that wrote `'phase1-dev-token'` to Hive and
navigated to the role landing — useful for iterating on UI, useless against
a real backend. The Node/Express server documented at `server/api.md`
exposes `POST /api/auth/register` returning
`{success, accessToken, refreshToken, user}` (the `success` flag is
informational; the actual contract is the three token / user fields).

Via brainstorming the user chose to: capture + persist the refresh token
now (so the future `/refresh` round can drop in without re-plumbing
storage), auto-authenticate + route on signup success (matching the prior
stub UX), and surface backend errors as a SnackBar with the verbatim
`message` field (the backend's strings are user-friendly — "Email already
registered as <role>").

## Decision

Filled in the auth data layer with the following shape:

- **Models** (`lib/features/auth/data/models/`)
  - `User` — common backend fields, `_id` → `id`, tolerates role-specific
    extras (teacher's `bio`, student's `currentClass`, etc.). Has both
    `fromJson` (parse the server envelope) and `fromCache` (parse the
    Hive blob) so the JSON key differs without overloading.
  - `AuthResponse` — `{accessToken, refreshToken, user}` parse-only.
  - `RegisterRequest` — `{userType, name, email, password, phone?}` with
    `phone` omitted from JSON when null or empty.
  - Sealed `AuthState`: `AuthInitial`, `AuthLoading`,
    `AuthAuthenticated(user, role)`, `AuthUnauthenticated`,
    `AuthError(message)`.
- **`Result<T>`** in `lib/core/error/` — generic `sealed` with `Ok<T>` /
  `Err<T>` (the failure side carries `AppFailure`). Lives in `core/` so
  any feature repo can use the pattern.
- **`AuthRemoteDataSource`** — Dio call to `ApiEndpoints.authRegister`.
  Translates `DioException`:
  - connection / timeout / DNS → `NetworkException("No connection. Check
    your internet and try again.")`;
  - 4xx with `{message: ...}` body → `ServerException(message,
    statusCode)`;
  - 5xx → `ServerException("Something went wrong, please try again.",
    statusCode)`;
  - parse / unknown → `ServerException("Unexpected error" / "Unexpected
    response shape")`.
- **`AuthLocalDataSource`** + `AuthSession` value class —
  `saveSession` writes `keyJwtToken`, `keyRefreshToken`, `keyCurrentUser`
  (as `jsonEncode(user.toJson())`) to `boxAuth` and `keyUserRole` to
  `boxSettings`; `readSession` returns `null` if any field is missing or
  the user JSON is malformed; `clearSession` deletes the auth-box keys
  but preserves the role.
- **`AuthRepository`** + **`AuthRepositoryImpl`** — `register` catches
  `AppException`, maps to `AppFailure`, returns `Result<AuthSession>`.
  Also exposes `cachedSession()` (used by the controller's `build`) and
  `signOut()` (unused this round; ready for the next).
- **`AuthNotifier`** (`Notifier<AuthState>`) — `build()` hydrates from
  the cache and seeds `roleProvider` so the router can route past auth
  without an onboarding hop; `register(...)` flips
  Loading → (Authenticated | Error) via `Result` pattern-matching.
- **`AuthPrimaryButton`** gains an `isLoading` flag — swaps the label
  for a 20×20 white `CircularProgressIndicator` and disables `onPressed`.
- **`RegisterScreen`** drops the `kDebugMode` shortcut. `onCreateAccount`
  calls `ref.read(authProvider.notifier).register(...)`; `ref.listen`
  drives navigation + SnackBar.
- New Hive key: `HiveKeys.keyRefreshToken`.

### Backend contract footnote

Mid-implementation the backend renamed the body field from `token` to
`accessToken` and added a `success: true` wrapper. The Dart `AuthResponse`
field is named to match (`accessToken`) so the JSON-to-model mapping is
1:1 readable. The `success` flag is parsed-but-ignored — we read the
tokens / user directly.

### Not done (deliberate)

- Login API call — `LoginScreen` keeps its `kDebugMode` test-credential
  bypass. Wiring login will reuse 100 % of this round's scaffolding via a
  new `AuthRepository.login(...)` method + a corresponding
  `AuthNotifier.signIn(...)`.
- `/me` rehydration on app start — `AuthNotifier.build` only reads cached
  token + role. Token validity is not server-checked; the next protected
  call will 401 if expired, and `AuthInterceptor` clears the session.
- Refresh-token rotation — captured + stored, but `AuthInterceptor.onError`
  still does the Phase-1 "clear on 401" behaviour. Implementing `/refresh`
  (with the Cookie-header dance for mobile) is a later round.
- Logout API — local-only sign-out is sufficient for now.

## Consequences

- Future rounds (login, `/me`, refresh, logout) slot in by adding methods
  to `AuthRemoteDataSource` / `AuthRepository` and matching mutations on
  `AuthNotifier`. Nothing in this round needs to be re-plumbed.
- Tests cover the model parsing / serialisation only — the repository,
  controller, and screen wiring are gated on manual verification against
  the running backend, matching the project's existing test discipline.
- `User` carries `fromJson` *and* `fromCache` factories because the
  backend keys the id as `_id` and we key the Hive blob as `id`. The
  alternative — always using `_id` — would be confusing on the cache
  side where the value never originated from Mongo.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* ·
`flutter test test/features/auth/data/models/` → all model tests pass ·
`flutter test test/adaptive_navigation_tooltip_test.dart` → still passes ·
manual signup against `cd ../server && npm run dev` → fresh email lands
on the role's shell, Hive auth box populated with token + refresh + user
+ role; re-attempt same email → SnackBar "Email already registered as
<role>"; kill the backend → SnackBar "No connection. Check your internet
and try again.".
