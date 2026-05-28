# Auth Login API Wiring — Design Spec

**Date:** 2026-05-28
**Phase:** Round 3 — login wiring on top of round 2's maxinvoice-pattern data layer
**Status:** Approved (3 scoping choices confirmed)

This spec wires `POST /api/auth/login` into the Flutter app, mirroring round 1/2's signup wiring on top of round 2's `AuthRepository` / `AuthController` / `ApiClient` / `TokenStorage` infrastructure. Behaviour-wise: the user types an email + password on `LoginScreen` → the backend verifies → success persists access + refresh tokens to `TokenStorage` (and user id + role to `LocalStorage`) and routes into the role's shell; failure shows the backend's verbatim message in a `SnackBar`.

The user picked three scoping choices via brainstorming:
1. **Remove** the existing `kDebugMode` test-credential shortcut entirely. Real login is the only path.
2. **Match backend register's password validator** — drop from ≥8 to ≥6 chars so a user who registered with a 6-char password can log in.
3. **Remove** the "Remember for 30 days" checkbox. The refresh-token cookie already gives persistent sessions; the toggle was UI fluff that did nothing.

## 1. Intent

Replace `LoginScreen`'s `kDebugMode` JWT-shortcut block with a real Riverpod-driven call to `POST /api/auth/login`. Reuse 100% of the round-2 scaffolding: a new `login` method on `AuthRepository`, a new `signIn` method on `AuthController`, and the existing `ref.listen<AuthState>` pattern from `RegisterScreen`.

## 2. Backend contract (frozen)

`POST /api/auth/login` — see `server/api.md`. Salient facts:

- **Request body**: `{userType: "student"|"owner"|"teacher"|"admin", email: string, password: string}`. We never send `admin` from the app — `userType` comes from `roleProvider` (which only takes the three app-facing role values).
- **Response 200**: `{success: true, accessToken: string, refreshToken: string, user: {...}}`. Identical envelope to register, so `AuthResponse.fromJson` is reused unchanged.
- **Errors**:
  - `400` `email and password are required` — won't happen if the form validates first.
  - `400` `userType must be one of: …` — won't happen, we always send a real role.
  - `401` `Invalid credentials` — wrong email + role pair, or wrong password. Same message deliberately, to avoid email enumeration.
  - `401` `Account is deactivated` — user exists but `isActive=false`. We surface the message as-is.
- Same `{status: 'error', message: …}` error envelope as register. The existing `ApiClient._mapDioError` + `AuthRepository`'s `on ApiError catch (e) → throw AuthException(e.message, …)` pipeline already handles all of these.

## 3. Out of scope

- `/api/auth/refresh` rotation. The `ApiClient` still clears tokens on 401 (Phase-1 behaviour).
- `/api/auth/me` rehydration on app start.
- `POST /api/auth/logout` server call. Local sign-out clears `TokenStorage` only (already implemented).
- Social login (Google / Facebook). The buttons stay as `stub` SnackBars.
- "Remember for 30 days" persistence behaviour. The toggle goes away entirely.
- `kDebugMode` escape hatch for offline UI dev. If the backend isn't running, login simply shows the network SnackBar.

## 4. Architecture

### 4.1 New model: `LoginRequest`

`lib/features/auth/data/models/login_request_model.dart`:

```dart
/// Request body for `POST /api/auth/login`.
library;

/// Serialises the login form's fields into the JSON shape the backend expects.
/// `userType` is one of `'student'`, `'owner'`, `'teacher'` (matches the
/// project's role constants in `core/providers/role_provider.dart`).
class LoginRequest {
  const LoginRequest({
    required this.userType,
    required this.email,
    required this.password,
  });

  /// One of `'student'` / `'owner'` / `'teacher'`. The app never sends
  /// `'admin'`; admins log in through a separate flow not yet implemented.
  final String userType;

  /// Lower-cased email. Caller trims + lowercases before constructing.
  final String email;

  /// Plaintext password — the backend bcrypt-compares against the stored hash.
  final String password;

  /// Backend-shaped JSON body.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'userType': userType,
        'email': email,
        'password': password,
      };
}
```

(`name` and `phone` from register are deliberately absent — login is identity-only.)

### 4.2 Tests for `LoginRequest`

`test/features/auth/data/models/login_request_model_test.dart` — three tests matching the register-request pattern:

```dart
import 'package:coachfinder/features/auth/data/models/login_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginRequest.toJson', () {
    test('serialises all three required fields', () {
      const request = LoginRequest(
        userType: 'owner',
        email: 'alice@x.com',
        password: 'secret123',
      );
      expect(request.toJson(), <String, dynamic>{
        'userType': 'owner',
        'email': 'alice@x.com',
        'password': 'secret123',
      });
    });

    test('uses the userType verbatim — no admin filtering at the model layer', () {
      const request = LoginRequest(
        userType: 'student',
        email: 's@x.com',
        password: 'p1234567',
      );
      expect(request.toJson()['userType'], 'student');
    });

    test('does not include name or phone keys', () {
      const request = LoginRequest(
        userType: 'teacher',
        email: 't@x.com',
        password: 'p1234567',
      );
      final json = request.toJson();
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('phone'), isFalse);
    });
  });
}
```

### 4.3 `AuthRepository.login` method

Added to `lib/features/auth/data/repositories/auth_repository.dart`:

```dart
/// Calls `POST /api/auth/login` and persists the returned tokens.
/// Returns the parsed [AuthResponse] (including the [User]).
Future<AuthResponse> login(LoginRequest request) async {
  try {
    final dioResponse = await _apiClient.rawPost(
      ApiConfig.authLogin,
      data: request.toJson(),
    );
    final apiResponse = ApiResponse<AuthResponse>.fromJson(
      dioResponse.data ?? <String, dynamic>{},
      (json) => AuthResponse.fromJson(json),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw AuthException(apiResponse.message ?? 'Failed to sign in');
    }
    final authResponse = apiResponse.data!;
    await _tokenStorage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    return authResponse;
  } on ApiError catch (e) {
    throw AuthException(e.message, code: e.statusCode?.toString());
  } on AuthException {
    rethrow;
  } catch (_) {
    throw AuthException('Something went wrong while signing in');
  }
}
```

Add `import '../models/login_request_model.dart';` to the file. No interface change to the rest of the repository.

### 4.4 `AuthController.signIn` method

Added to `lib/features/auth/data/providers/auth_providers.dart`:

```dart
/// Calls `POST /api/auth/login` via the repository, persists
/// `currentUserId` + `userRole` to [LocalStorage], updates [roleProvider],
/// and flips state through Loading → Authenticated. On failure flips to
/// Error with the backend's verbatim message.
Future<void> signIn({
  required String email,
  required String password,
  required String role,
}) async {
  state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
  try {
    final request = LoginRequest(
      userType: role,
      email: email.trim().toLowerCase(),
      password: password,
    );
    final response = await _repository.login(request);
    await LocalStorage.set(StorageKeys.userRole, role);
    await LocalStorage.set(StorageKeys.currentUserId, response.user.id);
    _ref.read(roleProvider.notifier).state = role;
    state = AuthState(
      status: AuthStatus.authenticated,
      user: response.user,
      role: role,
    );
  } on AuthException catch (e) {
    state = AuthState(status: AuthStatus.error, errorMessage: e.message);
  }
}
```

Add `import '../models/login_request_model.dart';` to the file.

### 4.5 Validator change

`lib/features/auth/presentation/auth_validators.dart` — `AuthValidators.password`:

```dart
static String? password(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}
```

(Was `< 8` / "at least 8 characters". Aligns with the backend register validator.)

This affects both login and register. For users who registered in round 1 / 2 with ≥8-char passwords, nothing changes. For users who registered with 6-7 chars, login no longer false-rejects.

### 4.6 `LoginScreen` rewrite

`lib/features/auth/presentation/screens/login_screen.dart` — full rewrite:

- **Imports dropped**: `flutter/foundation.dart` (kDebugMode), `dev_credentials.dart`, `local_storage.dart` (the inline writes go via the controller), `tokenStorageProvider`'s import path stays via `auth_providers.dart`.
- **Imports kept / added**: existing palette / spacing / widgets / auth_role_accents / auth_validators / app_strings / role_provider / app_routes; **add** `data/providers/auth_providers.dart` (for `authControllerProvider` + `AuthState` + `AuthStatus`).
- **Drop the `_RememberToggle` widget class entirely**. Drop the `rememberMe` `useState`. The row that used to be `[_RememberToggle, ForgotPasswordLink]` becomes just the right-aligned forgot-password link.
- **Drop the `_DebugCredentialHint` widget class entirely**. Drop the `if (kDebugMode) [const SizedBox, const _DebugCredentialHint()]` block.
- **`handleSignIn` becomes**:
  ```dart
  Future<void> handleSignIn() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final String resolvedRole =
        ref.read(roleProvider) ?? initialRole ?? roleStudent;
    await ref.read(authControllerProvider.notifier).signIn(
          email: emailCtrl.text,
          password: passwordCtrl.text,
          role: resolvedRole,
        );
  }
  ```
- **Add `ref.listen<AuthState>(authControllerProvider, ...)`** with the same shape as `RegisterScreen`:
  - `AuthStatus.authenticated` → `context.goNamed(landingRouteForRole(next.role!))`.
  - `AuthStatus.error` → `SnackBar(content: Text(next.errorMessage!))`.
- **`AuthPrimaryButton`** gets `isLoading: authState.isLoading`.

### 4.7 Cleanup

- **Delete** `lib/core/constants/dev_credentials.dart`. After the kDebugMode block is removed, nothing imports it. (Pre-check via grep before deletion.)
- **Delete unused `AppStrings`** in `lib/core/constants/app_strings.dart`:
  - `loginInvalidCredentials` (was used in the kDebugMode error path).
  - `stubAuthNotImplemented` (was the "real auth not wired yet" message).
  - `loginTestAccountLabel` (was used by `_DebugCredentialHint`).
  - `authRememberMe` (was used by `_RememberToggle`).
- Grep across the codebase for each before deletion to confirm zero consumers.

### 4.8 No new infrastructure

No new providers, no new core utilities, no changes to `TokenStorage` / `ApiClient` / `ApiResponse` / `LocalStorage`. The whole round is additive on top of round 2.

## 5. Data flow (login, happy path)

```
LoginScreen.handleSignIn
  └─ form valid?
       └─ ref.read(authControllerProvider.notifier).signIn(email, password, role)
            └─ state = AuthLoading                  ──► spinner + disabled button
            └─ AuthRepository.login(LoginRequest{userType, email, password})
                 └─ ApiClient.rawPost('/auth/login', body)
                      ├─ Authorization header injected (was empty pre-login)
                      └─ returns Response{success: true, accessToken, refreshToken, user}
                 └─ ApiResponse.fromJson → AuthResponse
                 └─ TokenStorage.saveTokens(accessToken, refreshToken)
                      └─ FlutterSecureStorage.write × 2
            └─ LocalStorage.set(StorageKeys.userRole, role)
            └─ LocalStorage.set(StorageKeys.currentUserId, user.id)
            └─ ref.read(roleProvider.notifier).state = role
            └─ state = AuthState(authenticated, user, role)
LoginScreen.ref.listen
  └─ AuthStatus.authenticated detected
       └─ context.goNamed(landingRouteForRole(role))
```

## 6. Error mapping

Identical to register (the same `ApiClient` + `AuthRepository.catch` pipeline). Specifically for login:

| Backend / network | UI |
|---|---|
| 401 `Invalid credentials` | SnackBar — `"Invalid credentials"` |
| 401 `Account is deactivated` | SnackBar — `"Account is deactivated"` |
| 5xx | SnackBar — `"Something went wrong, please try again."` |
| Timeout | SnackBar — `"Request timed out. Please try again."` |
| Connection / DNS | SnackBar — `"No connection. Check your internet and try again."` |

## 7. Edge cases & decisions

- **Mismatched role.** A student-registered user picking owner on onboarding and trying to log in returns 401 (no user with that email in the owner collection). The backend's deliberate same-message-for-both ("Invalid credentials") prevents email enumeration. We surface it verbatim. Future round could surface a "wrong role?" hint by parsing the email against multiple collections, but that's out of scope.
- **Forgot password link.** Untouched. Still routes to the existing `forgot_password_screen.dart` (which only shows a stub success snackbar — backend `/auth/forgot-password` isn't implemented).
- **Race: form re-submit while loading.** `AuthPrimaryButton.isLoading` → `onPressed: null` so taps are no-ops. Same UX as register.
- **Persisted tokens but stale user.** Round 2's persistence shape stores only `currentUserId` (not the full user blob). After a successful login the in-memory `AuthState.user` is fresh from the backend. Restarts re-hydrate without the user payload, so the auth screens won't show e.g. the user's name pre-fetch — but neither do the shells use it until `/me` lands in a later round.
- **Wrong-role login when token exists.** If a user is already authenticated (cached token + role) and somehow lands on `LoginScreen`, the router's redirect (Round 2) bounces them to their landing. So this path is unreachable in practice; no special handling.

## 8. Persistence shape (post-login)

Identical to post-signup (round 2 § 6):

| Store | Key | Value |
|---|---|---|
| `FlutterSecureStorage` | `access_token` | `AuthResponse.accessToken` |
| `FlutterSecureStorage` | `refresh_token` | `AuthResponse.refreshToken` |
| Hive (`coachfinder_settings`) | `user_role` | `'owner'` etc. |
| Hive (`coachfinder_settings`) | `current_user_id` | `response.user.id` |

## 9. File-level change list (concrete)

**New files:**
- `lib/features/auth/data/models/login_request_model.dart`
- `test/features/auth/data/models/login_request_model_test.dart`
- `decisions/0031-auth-login-wiring.md`

**Modified files:**
- `lib/features/auth/data/repositories/auth_repository.dart` — add `login()` method + import.
- `lib/features/auth/data/providers/auth_providers.dart` — add `signIn()` method + import.
- `lib/features/auth/presentation/auth_validators.dart` — password min 8 → 6.
- `lib/features/auth/presentation/screens/login_screen.dart` — full rewrite (drop kDebugMode + `_RememberToggle` + `_DebugCredentialHint`; wire `authControllerProvider`).
- `lib/core/constants/app_strings.dart` — delete 4 unused constants.

**Deleted:**
- `lib/core/constants/dev_credentials.dart` (after grep-confirmed zero consumers).

## 10. Verification

1. `dart format lib test` clean.
2. `flutter analyze` → *No issues found!*.
3. `flutter test` — 12 tests pass (4 User + 3 RegisterRequest + 3 LoginRequest + 1 AuthResponse + 1 nav).
4. `flutter build apk --debug` — builds.
5. Manual against `cd ../server && npm run dev`:
   - Register a fresh user (round 2 flow).
   - Background / kill the app to drop in-memory session.
   - Re-launch → router lands on role landing (cached token + role).
   - Sign out from Owner Profile → onboarding/login.
   - Pick same role → Login → type the registered credentials → expect role's shell.
   - Repeat with wrong password → expect "Invalid credentials" SnackBar.
   - Kill the backend → try login → expect offline SnackBar.
   - Type a 6-char password (instead of 8) in either form → expect no client-side validator block (backend determines validity).
