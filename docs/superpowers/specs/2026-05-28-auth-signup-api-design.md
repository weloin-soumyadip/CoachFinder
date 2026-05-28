# Auth API Layer — Signup Wiring (round 1) Design Spec

**Date:** 2026-05-28
**Phase:** First real-backend wiring in the Flutter app (the auth data layer scaffolds were stubbed `// TODO: implement` from project setup; this fills them in)
**Scope this round:** Wire the **signup** call to `POST /api/auth/register`. Models, repository, data sources, and the controller are designed to host login / refresh / me later, but only signup is exercised end-to-end.

---

## 1. Intent

Replace the `kDebugMode` JWT shortcut in `RegisterScreen` with a real Riverpod-driven call against the backend documented at `/home/weloin/Projects/practice/Claude-practice/coaching-app/server/api.md`. On success, persist the access token, refresh token, user, and role to Hive, set in-memory auth state to authenticated, and route the user into the role's landing screen.

Architecture decisions are made now (Result<T>, sealed AuthState, AsyncException → AppFailure mapping, `Notifier<AuthState>`) so that login, `/me`, and refresh slot in cleanly in later rounds without re-plumbing.

## 2. Backend contract (frozen)

`POST /api/auth/register` — see `server/api.md`. Salient facts the Flutter side depends on:

- **Request body**: `{userType: "owner"|"teacher"|"student", name: string, email: string, password: string, phone?: string}`.
- **Response 201**: `{token: string, refreshToken: string, user: {_id, name, email, phone, profileImage, isActive, isEmailVerified, createdAt, updatedAt, ...role-specific extras}}`.
- **`userType` matches our role constants** in `lib/core/providers/role_provider.dart` (`'student'`, `'owner'`, `'teacher'`). No translation layer needed.
- **`name` is a single string** — the form's `firstNameCtrl.text` + `lastNameCtrl.text` are concatenated `'${first.trim()} ${last.trim()}'.trim()`.
- **`phone` is optional** — the form doesn't collect phone, so we omit the key entirely.
- **Refresh token returned in the body** for mobile clients (the cookie is for browsers). We capture and persist it.
- **Common 4xx responses**:
  - `400` — malformed body / missing required field / unknown `userType`. `message` is user-actionable verbatim ("name, email, and password are required").
  - `409` — `Email already registered as <role>`. Surface verbatim — already user-friendly.
  - Mongoose validation surfaces as a 400 with the validator's message (e.g. "Password must be at least 6 characters") — also surfaced verbatim.
- **Error envelope**: `{status: "error", message: string, stack?: string}`. We read `message`.

Note: the `user.role` field is **not** in the response. The role we use locally is the one we sent in the request — captured from `roleProvider` (or the form's `initialRole`) at submit time. The `GET /api/auth/me` endpoint does return `{userType, user}`, but that's used later when we hydrate from server (out of scope this round).

## 3. Out of scope (this round)

- **Login API** — `RegisterScreen` and `LoginScreen` both currently honour a `kDebugMode` shortcut. Login is left untouched. Wiring it will reuse 100 % of this round's scaffolding (a `login(...)` method on `AuthRepository` + a corresponding controller method).
- **`/me` server-side rehydration on app start** — `AuthNotifier.build()` only reads cached token + role from Hive and decides authenticated vs initial; it does not call `/me` to verify. The cached session is presumed valid; the AuthInterceptor still handles the 401-clear path.
- **Refresh-token rotation** — we capture and persist the refresh token (so the Hive row exists), but `AuthInterceptor.onError` still does the existing Phase-1 behaviour: clear the session on 401. Implementing `/refresh` (and the Cookie-header dance) is a later round.
- **Logout API** — local-only sign-out (clear Hive) is fine for now; the server's `/logout` is unused.
- **Email verification / phone capture / profile image upload** — none in scope.
- **Multi-environment URL switching** — `ApiEndpoints.baseUrl` stays `http://10.0.2.2:5000/api` (Android-emulator loopback). iOS simulator + physical-device URLs are out of scope per decision 0002.

## 4. Architecture

### 4.1 New shared piece: `Result<T>`

`lib/core/error/result.dart`:

```dart
import 'app_failure.dart';

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}
```

Generic, reusable by any future feature repo. Respects the existing convention (`AppException` is thrown by data sources; `AppFailure` is a value returned by repositories). Dart 3 sealed + pattern matching at the call site:

```dart
switch (result) {
  case Ok(value: final session): ...
  case Err(failure: final failure): ...
}
```

### 4.2 Models

**`lib/features/auth/data/models/user_model.dart`** — the common user shape:

```dart
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.profileImage = '',
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String profileImage;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory User.fromJson(Map<String, dynamic> json) {
    // Map _id -> id, parse ISO timestamps, handle nulls.
  }

  Map<String, dynamic> toJson() {
    // ISO-8601 strings for DateTime, '_id' kept under 'id' on the way back
    // (since we never round-trip into the backend — Hive only).
  }
}
```

Role-specific fields (teacher's `bio`, student's `currentClass`, etc.) live in dedicated profile models pulled via `/api/{role}/me` later. They're irrelevant to the signup flow.

**`lib/features/auth/data/models/auth_response_model.dart`** — the parser for the server's `{token, refreshToken, user}` envelope. `fromJson` only:

```dart
class AuthResponse {
  const AuthResponse({required this.token, required this.refreshToken, required this.user});
  final String token;
  final String refreshToken;
  final User user;
  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'] as String,
    refreshToken: json['refreshToken'] as String,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );
}
```

**`lib/features/auth/data/models/register_request_model.dart`** — `toJson` only:

```dart
class RegisterRequest {
  const RegisterRequest({
    required this.userType,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  final String userType;
  final String name;
  final String email;
  final String password;
  final String? phone;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userType': userType,
    'name': name,
    'email': email,
    'password': password,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
  };
}
```

**`lib/features/auth/data/models/auth_state.dart`** — sealed states:

```dart
sealed class AuthState { const AuthState(); }
class AuthInitial extends AuthState { const AuthInitial(); }
class AuthLoading extends AuthState { const AuthLoading(); }
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, required this.role});
  final User user;
  final String role; // 'student' | 'owner' | 'teacher'
}
class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
```

`AuthError` is a state, not an exception. Transient — the controller flips back to `AuthInitial` / `AuthUnauthenticated` when the screen acknowledges or the user retypes. (Concretely: the screen consumes it via `ref.listen` and shows a SnackBar; we don't reset state automatically — the next `register()` call sets state to `AuthLoading` again, replacing the error.)

### 4.3 Session record

The repo returns an `AuthSession` value (defined alongside the repo since it's a tiny composition):

```dart
class AuthSession {
  const AuthSession({required this.token, required this.refreshToken, required this.user, required this.role});
  final String token;
  final String refreshToken;
  final User user;
  final String role;
}
```

(We do not persist `AuthSession` as a single Hive blob — fields are stored individually for granular cache reads / interceptor access.)

### 4.4 Data sources

**`AuthRemoteDataSource`** — interface + `AuthRemoteDataSourceImpl`. One method this round:

```dart
abstract interface class AuthRemoteDataSource {
  Future<AuthResponse> register(RegisterRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioToException(e);
    }
  }
}
```

`_mapDioToException(DioException)` (private helper, top-level in the same file):
- `DioExceptionType.connectionTimeout` / `sendTimeout` / `receiveTimeout` / `connectionError` → `NetworkException("No connection. Check your internet and try again.")`
- Response status `400` | `409` | `4xx` → `ServerException(json['message'] ?? "Request failed", statusCode: status)`. We extract `message` from the response body envelope (`{status: "error", message: "..."}`).
- Response status `5xx` → `ServerException("Something went wrong, please try again.", statusCode: status)` (we do not surface the backend's raw 5xx message; could leak internals).
- Any other / no-response case → `ServerException("Unexpected error")`.

**`AuthLocalDataSource`** — interface + impl over `HiveService`:

```dart
abstract interface class AuthLocalDataSource {
  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();
  AuthSession? readSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._hive);
  final HiveService _hive;
  // saveSession: authBox.put(keyJwtToken, ...), authBox.put(keyRefreshToken, ...),
  //              authBox.put(keyCurrentUser, jsonEncode(user.toJson())),
  //              settingsBox.put(keyUserRole, role).
  // readSession: reverse, returns null if any field is missing.
  // clearSession: delete jwt + refresh + current_user. (Role stays — onboarding
  //               chose it and we keep it across logouts.)
}
```

New Hive key: **`HiveKeys.keyRefreshToken = 'refresh_token'`** added to the `boxAuth` section.

### 4.5 Repository

**`AuthRepository`** interface and **`AuthRepositoryImpl`**:

```dart
abstract interface class AuthRepository {
  Future<Result<AuthSession>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  });

  /// Reads the cached session from Hive, returning null when any of token /
  /// refresh / user / role are missing. Used by [AuthNotifier.build] to
  /// hydrate startup state without an extra `/me` round-trip.
  AuthSession? cachedSession();

  /// Clears the locally-cached session (token + refresh + user). Role is
  /// preserved so re-login lands on the same shell.
  Future<void> signOut();
}
```

`AuthRepositoryImpl`:

```dart
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remote, required AuthLocalDataSource local})
    : _remote = remote, _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Result<AuthSession>> register({...}) async {
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();
    final request = RegisterRequest(userType: role, name: name, email: email.trim().toLowerCase(), password: password);
    try {
      final response = await _remote.register(request);
      final session = AuthSession(
        token: response.token,
        refreshToken: response.refreshToken,
        user: response.user,
        role: role,
      );
      await _local.saveSession(session);
      return Ok(session);
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Err(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Err(ServerFailure(e.message));
    }
  }
}
```

### 4.6 Controller

`lib/features/auth/data/controllers/auth_provider.dart`:

```dart
final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final hive = ref.watch(hiveServiceProvider);
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSourceImpl(dio),
    local: AuthLocalDataSourceImpl(hive),
  );
});

final NotifierProvider<AuthNotifier, AuthState> authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    final cached = _repo.cachedSession();
    if (cached != null) {
      // Best-effort: hydrate the role provider so the router can route
      // immediately without an onboarding hop.
      ref.read(roleProvider.notifier).state = cached.role;
      return AuthAuthenticated(user: cached.user, role: cached.role);
    }
    return const AuthInitial();
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AuthLoading();
    final result = await _repo.register(
      firstName: firstName, lastName: lastName,
      email: email, password: password, role: role,
    );
    switch (result) {
      case Ok<AuthSession>(value: final session):
        ref.read(roleProvider.notifier).state = session.role;
        state = AuthAuthenticated(user: session.user, role: session.role);
      case Err<AuthSession>(failure: final failure):
        state = AuthError(failure.message);
    }
  }
}
```

### 4.7 Wire into `RegisterScreen`

- Remove the `if (!kDebugMode) stub(...); ... goNamed(landingRouteForRole(role));` block.
- `onCreateAccount` now: validate the form → call `ref.read(authProvider.notifier).register(...)`. No SnackBar / no navigation in this method — both are reactions to state.
- Add `ref.listen<AuthState>(authProvider, (previous, next) { ... })`:
  - `AuthAuthenticated` → `ScaffoldMessenger.hideCurrentSnackBar()` + `context.goNamed(landingRouteForRole(next.role))`.
  - `AuthError` → `ScaffoldMessenger.showSnackBar(SnackBar(content: Text(next.message)))`.
- A `isLoading = ref.watch(authProvider) is AuthLoading;` boolean drives:
  - `AuthPrimaryButton.onPressed: isLoading ? null : onCreateAccount` (null → button greys out via `NeoButton`'s `enabled` path).
  - Replace the label text with a 20×20 `CircularProgressIndicator(strokeWidth: 2, color: AppColors.neutralWhite)` when loading. Cleanest: `AuthPrimaryButton` gains an optional `isLoading` param; when true it shows the spinner in place of label + ignores `onPressed`. Defaults preserve existing call sites.

### 4.8 Provider wiring summary

```
hiveServiceProvider (existing) ─┐
                                ├─ authRepositoryProvider ─ authProvider (NotifierProvider<AuthNotifier, AuthState>)
dioProvider (existing) ─────────┘
```

`dioProvider` already composes `hiveServiceProvider` via the AuthInterceptor, so the access token automatically attaches to every future protected request once `saveSession` lands.

## 5. Data flow (signup, happy path)

```
RegisterScreen.onCreateAccount
  └─ form valid?
       └─ ref.read(authProvider.notifier).register(firstName, lastName, email, password, role)
            └─ state = AuthLoading             ──► UI: button disabled + spinner
            └─ AuthRepositoryImpl.register
                 └─ AuthRemoteDataSourceImpl.register
                      └─ dio.post('/auth/register', body)
                      └─ AuthResponse.fromJson
                 └─ AuthLocalDataSourceImpl.saveSession
                      └─ authBox.put(jwt, refresh, currentUser) + settingsBox.put(userRole)
                 └─ return Ok(session)
            └─ ref.read(roleProvider.notifier).state = session.role
            └─ state = AuthAuthenticated(user, role)
RegisterScreen.ref.listen
  └─ AuthAuthenticated detected
       └─ context.goNamed(landingRouteForRole(role))
```

## 6. Data flow (errors)

| Backend / network | `AppException` (data source) | `AppFailure` (repo) | UI |
|---|---|---|---|
| 400 | `ServerException(msg, statusCode: 400)` | `ServerFailure(msg, statusCode: 400)` | SnackBar — backend `message` verbatim |
| 409 | `ServerException("Email already registered as <role>", 409)` | `ServerFailure(msg, 409)` | SnackBar — verbatim |
| 500-class | `ServerException("Something went wrong, please try again.", 500..)` | `ServerFailure(msg, 5xx)` | SnackBar — generic message |
| Timeout / no connection / DNS | `NetworkException("No connection. Check your internet and try again.")` | `NetworkFailure(msg)` | SnackBar — generic offline message |
| Anything else | `ServerException("Unexpected error")` | `ServerFailure(msg)` | SnackBar |

The UI is identical across all cases (a SnackBar with `state.message`). The mapping table exists so the in-code messages are consistent.

## 7. Persistence shape (post-signup Hive)

| Box | Key | Value | Source |
|---|---|---|---|
| `boxAuth` | `keyJwtToken` | `'eyJhbGc...'` | `AuthResponse.token` |
| `boxAuth` | `keyRefreshToken` *(new)* | `'eyJhbGc...'` | `AuthResponse.refreshToken` |
| `boxAuth` | `keyCurrentUser` | `'{"id":"67...","name":"Alice",...}'` (json string) | `jsonEncode(user.toJson())` |
| `boxSettings` | `keyUserRole` | `'owner'` (or `'student'` / `'teacher'`) | `RegisterRequest.userType` |

JWT is automatically picked up by `AuthInterceptor.onRequest` on the next API call.

## 8. Edge cases & decisions

- **Stale form on rebuild.** `useTextEditingController` survives `ref.watch` rebuilds, so changing `authProvider` state during a submit doesn't blow away typed input.
- **Re-tap submit while loading.** `isLoading` driven by `state is AuthLoading` makes the button non-interactive; double-tap is a no-op.
- **Network error during submit.** Snack-Bar fires; `state = AuthError` is **not** auto-cleared; the next `register()` call replaces it with `AuthLoading` so the button reactivates.
- **App relaunch with token present.** `AuthNotifier.build` reads Hive, returns `AuthAuthenticated` immediately, and seeds `roleProvider` so the existing GoRouter redirect logic routes the user past auth without flicker. (Token *validity* is not checked — the next protected call will 401 if expired, and `AuthInterceptor` will clear the session, falling the user back to onboarding/login on the navigation tick after.)
- **Role mismatch on backend.** Not possible — the server's `userType` enum matches our role constants exactly. We send what we have; the server accepts it.
- **`name` empty after trim** (e.g. user types only spaces in both name fields). The form validators (`AuthValidators.notEmpty`) already block submit. Backend would also 400; we never reach there.
- **Server returns an unexpected user shape.** `User.fromJson` will throw a `TypeError` / `FormatException`. Bubbles up as a generic `ServerException("Unexpected error")` via a top-level `catch` in the remote source — added explicitly so a backend regression doesn't crash the app.

## 9. File-level change list (concrete)

**New files:**
- `lib/core/error/result.dart`
- `lib/features/auth/data/models/register_request_model.dart`
- `lib/features/auth/data/models/auth_state.dart`

**Filled in (currently `// TODO: implement` stubs):**
- `lib/features/auth/data/models/user_model.dart`
- `lib/features/auth/data/models/auth_response_model.dart`
- `lib/features/auth/data/repository/auth_remote_datasource.dart`
- `lib/features/auth/data/repository/auth_local_datasource.dart`
- `lib/features/auth/data/repository/auth_repository.dart`
- `lib/features/auth/data/repository/auth_repository_impl.dart`
- `lib/features/auth/data/controllers/auth_provider.dart`

**Modified:**
- `lib/core/constants/hive_keys.dart` — add `keyRefreshToken`.
- `lib/features/auth/presentation/widgets/auth_widgets.dart` — `AuthPrimaryButton` gains `isLoading` param.
- `lib/features/auth/presentation/screens/register_screen.dart` — drop kDebugMode shortcut, wire `authProvider`, `ref.listen` for navigation + error SnackBar, drive `AuthPrimaryButton.isLoading`.

**Bookkeeping:**
- New ADR: `decisions/0029-auth-data-layer-and-signup-wiring.md`.

## 10. Verification

1. `dart format lib` clean.
2. `flutter analyze` → *No issues found!*
3. Start the local backend (`cd ../server && npm run dev` or per its README) — user runs this separately.
4. From the Flutter app: pick a role on onboarding → register with a fresh email + password ≥ 6 chars → expect:
   - Button shows spinner, then dismisses.
   - Lands on the role's shell (student feed / owner dashboard / teacher home).
   - Hive auth box has `jwt_token`, `refresh_token`, `current_user` populated; `settings.user_role` matches the picked role.
5. Re-attempt the same email → expect the SnackBar **"Email already registered as &lt;role&gt;"** and no navigation.
6. Kill the backend and try again → expect the SnackBar **"No connection. Check your internet and try again."**.
7. Existing test still passes — `flutter test test/adaptive_navigation_tooltip_test.dart`.
8. ADR 0029 committed alongside the implementation.
