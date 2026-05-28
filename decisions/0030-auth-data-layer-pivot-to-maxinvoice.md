# 0030 — Auth data layer pivot to maxinvoice architecture

**Status:** Accepted
**Date:** 2026-05-28
**Phase:** Round 2 — re-architecture
**Made by:** User (request + 1 scoping choice "full pivot") + Claude
(spec, plan, implementation).

## Context

Round 1 (ADR 0029) wired the signup API call using `HiveService` (instance
class with `authBox`/`settingsBox` getters), `Notifier<sealed AuthState>`,
`Result<T>` returns, and a `Remote/LocalDataSource` repository split.

While reviewing, the user pointed at `/home/weloin/Projects/maxinvoice-app/`
and asked the coaching-app's data layer to match. The two patterns differed
on 8 axes (storage class style, secure-storage usage, ApiClient wrapper,
repository shape, error model, state-management primitive, folder layout).
The user picked **full pivot** so both projects share one mental model.

## Decision

Adopted the maxinvoice data-layer architecture verbatim, parameterised for
the coaching-app's auth contract.

### New core infrastructure

- **`LocalStorage`** (`lib/core/storage/local_storage.dart`) — static
  methods over a single Hive box (`coachfinder_settings`). `StorageKeys`
  holds the three keys we use this round (`themeMode`, `userRole`,
  `currentUserId`).
- **`TokenStorage`** (`lib/core/storage/token_storage.dart`) — instance
  class wrapping `flutter_secure_storage` (Keychain / EncryptedSharedPrefs).
  Holds the access + refresh JWTs. The token never lives in Hive.
- **`ApiClient`** (`lib/core/api/api_client.dart`) — Dio wrapper. Injects
  the bearer header on every request via `TokenStorage.getAccessToken`,
  clears the tokens on a 401 response (Phase-1 behaviour; `/refresh`
  rotation is a later round). Exposes `get` / `post` / `rawPost` returning
  either `ApiResponse<T>` or the raw Dio `Response` (the auth repo uses
  `rawPost` because the backend's envelope is non-standard at top level).
- **`ApiConfig`** / **`ApiError`** / **`ApiResponse<T>`** — the small
  supporting types. `ApiResponse.fromJson` falls back to top-level when
  `data` is absent, so the auth endpoints' `{success, accessToken,
  refreshToken, user}` envelope parses without special casing.

### New auth layer

- **`data/repositories/auth_repository.dart`** — single concrete class.
  Throws `AuthException` on failure. Persists tokens via `TokenStorage`
  on success.
- **`data/providers/auth_providers.dart`** — `AuthStatus` enum +
  regular `AuthState` class (`copyWith`, `isLoading`, `isAuthenticated`
  helpers) + `AuthController extends StateNotifier<AuthState>` +
  `apiClientProvider` / `tokenStorageProvider` / `authRepositoryProvider`
  / `authControllerProvider`. The controller mirrors `role` to both
  `AuthState.role` and the top-level `roleProvider` (which the router
  reads).

### Migration

- `main.dart` initialises `LocalStorage` and reads role + theme from it.
- `onboarding_screen.dart` writes role through `LocalStorage`.
- `owner_profile_screen.dart` (and the missed `student_profile_screen.dart`
  + `teacher_profile_screen.dart`, picked up mid-execution) toggle theme
  through `LocalStorage` and sign out through
  `authControllerProvider.logout()` (which clears the secure-storage
  tokens).
- `login_screen.dart` keeps its `kDebugMode` test-credential shortcut but
  now writes the placeholder token to `TokenStorage` and the role to
  `LocalStorage`.
- `register_screen.dart` is wired to `authControllerProvider` —
  `ref.listen` switches on `AuthStatus` enum cases instead of sealed
  class instance-of.
- `app_router.dart` — also missed in the original plan and migrated
  mid-execution. The synchronous token check (which read Hive directly)
  is dropped; the redirect now gates on `roleProvider` alone. The
  `ApiClient`'s 401 handler clears tokens on expiry, so a stale role +
  no-token state recovers itself on the next protected request.

### Deletions

`HiveService` + `HiveKeys` + `hiveServiceProvider`, the entire
`lib/core/network/` directory (`dio_client`, `dio_provider`,
`auth_interceptor`), the round-1 error scaffolding (`Result<T>`,
`AppException`, `AppFailure`), and all the round-1 auth data layer
(`Remote/LocalDataSource`, `AuthRepositoryImpl`, the sealed
`AuthState`, the `Notifier`-based controller).

The three model files (`User`, `AuthResponse`, `RegisterRequest`) and
their 8 tests are preserved unchanged.

### Out of scope

- Login API call — `LoginScreen` keeps its `kDebugMode` shortcut.
- `/api/auth/refresh` rotation.
- `/api/auth/me` rehydration on app start.
- Logout API call (server endpoint).
- Hive migration of pre-existing data (dev env; orphan boxes are harmless).

## Consequences

- The two projects now share a single mental model for the data layer.
  Switching context between them no longer requires re-learning the
  boundaries.
- JWTs are platform-secure (Keychain / EncryptedSharedPrefs) rather than
  living in the Hive `authBox`. Better security posture.
- The repository no longer returns `Result<T>` — failures are thrown via
  `AuthException`. The "failures are values, never thrown" comment that
  lived in the round-1 `app_failure.dart` is gone with the file.
- The router's redirect is now slightly less strict (token-presence check
  dropped) — it gates on role alone. The compensating control is the
  network-layer 401 handler that clears tokens on expiry. For dev this
  trade-off is fine; in a future round, the router could `ref.watch` the
  `AuthState.status` instead of computing it from `roleProvider`.
- The 9 existing tests (8 model + 1 nav) still pass without changes; no
  new automated tests this round (the repo + controller wiring is gated
  on manual verification against the real backend, same as ADR 0029).
- Future rounds (login, refresh, /me, logout) slot in by adding methods
  to `AuthRepository` and `AuthController`. Nothing in this round needs
  re-plumbing.

## Verification

`dart format lib test` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → 9 / 9 pass · `flutter build apk --debug` → built ·
manual signup against `cd ../server && npm run dev` pending (gated on
user starting the backend).
