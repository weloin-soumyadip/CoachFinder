# Auth data-layer pivot to maxinvoice architecture — Design Spec

**Date:** 2026-05-28
**Phase:** Round 2 of auth wiring — re-architecture
**Status:** Approved (scope question + design proposal both confirmed)

This spec replaces round 1's `HiveService` + `Notifier<sealed AuthState>` + `Result<T>` + `Remote/LocalDataSource` split with the pattern used in the user's other Flutter project (`/home/weloin/Projects/maxinvoice-app/`): `LocalStorage` (static Hive wrapper) + `TokenStorage` (secure storage) + `ApiClient` (Dio wrapper) + `AuthRepository` (single concrete class, throws `AuthException`) + `AuthController extends StateNotifier<AuthState>` with an `AuthStatus` enum. Behaviour stays identical (signup against the real backend, role-driven SnackBar errors, JWT persists across restart) — only the architecture changes.

The trigger was the user pointing at `lib/core/storage/display_options_storage.dart` in the reference project; on inspection the differences extend across 8 architectural axes. The user chose **full pivot** so the two projects share a single mental model.

## 1. Intent

Re-align the coaching-app's data layer with the maxinvoice-app's so the user can context-switch between projects without re-learning the boundaries. Concretely:

- A single `Box` keyed by string in `LocalStorage` replaces the per-feature `authBox` / `settingsBox` / `cacheBox` getters on `HiveService`.
- Tokens move out of Hive into `flutter_secure_storage` via `TokenStorage` (better security posture — JWTs go in Keychain / EncryptedSharedPreferences).
- A `Dio` wrapper (`ApiClient`) consolidates auth header injection, error mapping, and the response envelope into one place. The freestanding `AuthInterceptor` + `dioProvider` is deleted.
- The repository throws `AuthException` instead of returning `Result<Err<AppFailure>>`. The `Remote/LocalDataSource` split is collapsed into the repository itself.
- The controller is a `StateNotifier<AuthState>` with an `AuthStatus` enum and a regular `AuthState` class (not a sealed hierarchy).
- Folder layout: `data/{models, providers, repositories}/` (renamed from `data/{models, controllers, repository}/`).

## 2. Out of scope

- Login API call. `LoginScreen` keeps its `kDebugMode` shortcut, just adapted to write to `LocalStorage` + `TokenStorage` instead of Hive directly. Wiring real login is the next round.
- `/api/auth/refresh` token rotation. Captured + persisted but not yet used; `ApiClient`'s 401 handler clears the session for now.
- `/api/auth/me` server-side rehydration. `AuthController.build`-equivalent (a manual hydrate method called from `main` or onboarding redirect logic) reads cached `userRole` + `userId` from `LocalStorage` and trusts them; freshness is gated on the next protected call's 401.
- Logout API call. `signOut()` just clears `TokenStorage` + the cached user fields.
- Per-domain storage wrappers (e.g. `DisplayOptionsStorage`). We don't have feature settings yet that warrant them.
- Hive migration from the old `auth` / `settings` / `cache` boxes. Dev environment — orphan boxes are harmless; users re-pick role on next onboarding.

## 3. Architecture

### 3.1 Packages

Add to `pubspec.yaml`:

```yaml
flutter_secure_storage: ^9.2.2
```

(Dio + Hive remain; `path_provider` and `flutter_secure_storage`'s transitive deps come in automatically.)

### 3.2 Core storage (`lib/core/storage/`)

**`local_storage.dart`** — Hive-backed static wrapper:

```dart
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const String _boxName = 'coachfinder_settings';
  static Box? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static T? get<T>(String key, {T? defaultValue}) {
    return _box?.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> set<T>(String key, T value) async {
    await _box?.put(key, value);
  }

  static Future<void> remove(String key) async {
    await _box?.delete(key);
  }

  static Future<void> clear() async {
    await _box?.clear();
  }

  static bool containsKey(String key) => _box?.containsKey(key) ?? false;
}

class StorageKeys {
  static const String themeMode = 'theme_mode';
  static const String userRole = 'user_role';
  static const String currentUserId = 'current_user_id';
}
```

**`token_storage.dart`** — `flutter_secure_storage` wrapper, mirrors maxinvoice's class (trimmed: we don't track expiry separately this round):

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<void> saveAccessToken(String token) async => _storage.write(key: _accessTokenKey, value: token);
  Future<String?> getAccessToken() async => _storage.read(key: _accessTokenKey);
  Future<void> saveRefreshToken(String token) async => _storage.write(key: _refreshTokenKey, value: token);
  Future<String?> getRefreshToken() async => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) await saveRefreshToken(refreshToken);
  }

  Future<void> clearTokens() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  /// Best-effort "is logged in" check. Returns true iff an access token is
  /// present; doesn't verify against the server. A subsequent protected call
  /// will 401-and-clear if the token has actually expired.
  Future<bool> isTokenValid() async {
    final t = await getAccessToken();
    return t != null && t.isNotEmpty;
  }

  Future<bool> hasToken() async {
    final t = await getAccessToken();
    return t != null;
  }
}
```

### 3.3 Core API (`lib/core/api/`)

Replaces `lib/core/network/` entirely (which contained `dio_client.dart`, `dio_provider.dart`, `auth_interceptor.dart`).

**`api_config.dart`**:

```dart
class ApiConfig {
  ApiConfig._();
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Endpoint paths (added as features wire up)
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
}
```

**`api_error.dart`**:

```dart
class ApiError implements Exception {
  final int? statusCode;
  final String message;
  final String? errorCode;

  const ApiError({this.statusCode, required this.message, this.errorCode});

  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiError(
      statusCode: statusCode,
      message: (json['message'] as String?) ?? 'An error occurred',
      errorCode: json['errorCode'] as String?,
    );
  }

  factory ApiError.network({String? message}) => ApiError(
        message: message ?? 'No connection. Check your internet and try again.',
        errorCode: 'NETWORK_ERROR',
      );

  factory ApiError.timeout() => const ApiError(
        message: 'Request timed out. Please try again.',
        errorCode: 'TIMEOUT',
      );

  factory ApiError.unknown() => const ApiError(
        message: 'Something went wrong, please try again.',
        errorCode: 'UNKNOWN',
      );

  bool get isUnauthorized => statusCode == 401;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiError: $message (code: $statusCode)';
}
```

**`api_response.dart`**:

```dart
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  const ApiResponse({required this.success, this.data, this.message});

  /// Parses the project's standard envelope: `{success, data, message}`.
  /// When the server top-levels the payload (e.g. the auth endpoints'
  /// `{success, accessToken, refreshToken, user}`), pass the whole map as
  /// the second argument's input via [fromJsonT].
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json)? fromJsonT,
  ) {
    final bool success = (json['success'] as bool?) ?? true;
    T? data;
    if (fromJsonT != null) {
      final dynamic payload = json['data'] ?? json;
      if (payload is Map<String, dynamic>) {
        data = fromJsonT(payload);
      }
    }
    return ApiResponse<T>(
      success: success,
      data: data,
      message: json['message'] as String?,
    );
  }

  bool get hasData => data != null;
  bool get hasError => !success;
}
```

(We do not implement `ApiListResponse<T>` / `PaginationMeta` this round — YAGNI for auth.)

**`api_client.dart`** — trimmed Dio wrapper (~150 lines):

```dart
import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_error.dart';
import 'token_storage.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient({TokenStorage? tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = dio ?? _createDio();
    _setupInterceptors();
  }

  Dio _createDio() => Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectionTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          await _tokenStorage.clearTokens();
        }
        handler.next(e);
      },
    ));
  }

  /// Generic POST returning the parsed [ApiResponse<T>].
  Future<ApiResponse<T>> post<T>(String path, {dynamic data, T Function(Map<String, dynamic>)? fromJson}) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(path, data: data);
      return ApiResponse<T>.fromJson(response.data ?? <String, dynamic>{}, fromJson);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// GET with the same envelope handling.
  Future<ApiResponse<T>> get<T>(String path, {T Function(Map<String, dynamic>)? fromJson}) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(path);
      return ApiResponse<T>.fromJson(response.data ?? <String, dynamic>{}, fromJson);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Raw POST that returns Dio's [Response] verbatim. Use when the response
  /// envelope shape is non-standard and you want to do `ApiResponse.fromJson`
  /// yourself with a custom payload extractor.
  Future<Response<Map<String, dynamic>>> rawPost(String path, {dynamic data}) async {
    try {
      return await _dio.post<Map<String, dynamic>>(path, data: data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiError _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError.timeout();
      case DioExceptionType.connectionError:
        return ApiError.network();
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        final int? status = e.response?.statusCode;
        final dynamic body = e.response?.data;
        if (body is Map<String, dynamic>) {
          return ApiError.fromJson(body, statusCode: status);
        }
        if (status != null && status >= 500) {
          return ApiError(statusCode: status, message: 'Something went wrong, please try again.');
        }
        return ApiError.unknown();
    }
  }
}
```

### 3.4 Auth feature data layer

**Folder renames:**

```
lib/features/auth/data/
├── models/                            (unchanged folder)
│   ├── user_model.dart                (kept; 4 tests still pass)
│   ├── auth_response_model.dart       (kept; 1 test still passes)
│   ├── register_request_model.dart    (kept; 3 tests still pass)
│   └── auth_state.dart                (DELETED — replaced)
├── providers/                         (renamed from controllers/)
│   └── auth_providers.dart            (renamed + rewritten)
└── repositories/                      (renamed from repository/)
    └── auth_repository.dart           (rewritten as single concrete class)
```

**Deleted:**
- `lib/features/auth/data/repository/auth_remote_datasource.dart`
- `lib/features/auth/data/repository/auth_local_datasource.dart`
- `lib/features/auth/data/repository/auth_repository_impl.dart`
- `lib/features/auth/data/models/auth_state.dart` (the sealed version)

**`repositories/auth_repository.dart`**:

```dart
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/api/api_error.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/auth_response_model.dart';
import '../models/register_request_model.dart';

class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository(this._apiClient, this._tokenStorage);

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final dioResponse = await _apiClient.rawPost(
        ApiConfig.authRegister,
        data: request.toJson(),
      );
      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        dioResponse.data ?? <String, dynamic>{},
        (json) => AuthResponse.fromJson(json),
      );
      if (!apiResponse.success || apiResponse.data == null) {
        throw AuthException(apiResponse.message ?? 'Failed to register');
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
      throw AuthException('Something went wrong while signing up');
    }
  }

  Future<bool> isAuthenticated() => _tokenStorage.isTokenValid();
  Future<String?> getAccessToken() => _tokenStorage.getAccessToken();
  Future<void> logout() => _tokenStorage.clearTokens();
}
```

Note `AuthResponse.fromJson` is reused from round 1 — it reads `accessToken` / `refreshToken` / `user` directly off the top-level map. `ApiResponse.fromJson` falls back to `json` itself when `json['data']` is absent (see the helper above), so the top-level shape parses transparently.

**`providers/auth_providers.dart`**:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepository(ref.read(apiClientProvider), ref.read(tokenStorageProvider)));

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? role;
  final String? errorMessage;
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.role,
    this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, User? user, String? role, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(const AuthState());

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final name = '${firstName.trim()} ${lastName.trim()}'.trim();
      final request = RegisterRequest(
        userType: role,
        name: name,
        email: email.trim().toLowerCase(),
        password: password,
      );
      final response = await _repository.register(request);
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

  Future<void> logout() async {
    await _repository.logout();
    await LocalStorage.remove(StorageKeys.currentUserId);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo, ref);
});
```

`roleProvider` stays a separate `StateProvider<String?>` (existing) because the router reads it; `AuthController.register` writes to both so they stay in sync.

### 3.5 `RegisterScreen` rewire

Swap `authProvider` → `authControllerProvider`. The `ref.listen` block checks `next.status`:

```dart
ref.listen<AuthState>(authControllerProvider, (previous, next) {
  if (!context.mounted) return;
  if (next.status == AuthStatus.authenticated && next.role != null) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    context.goNamed(landingRouteForRole(next.role!));
  } else if (next.status == AuthStatus.error && next.errorMessage != null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
  }
});

final isLoading = ref.watch(authControllerProvider).isLoading;
```

`onCreateAccount` calls `ref.read(authControllerProvider.notifier).register(...)`. Everything else (form fields, validators, GlassPanel, etc.) unchanged.

### 3.6 Migration of remaining HiveService consumers

- **`main.dart`** — initialization becomes:
  ```dart
  await LocalStorage.init();
  final initialRole = LocalStorage.get<String>(StorageKeys.userRole);
  final initialThemeMode = themeModeFromStorage(LocalStorage.get<String>(StorageKeys.themeMode));
  ```

- **`onboarding_screen.dart`** — `handleContinue` becomes:
  ```dart
  await LocalStorage.set(StorageKeys.userRole, role);
  ref.read(roleProvider.notifier).state = role;
  context.goNamed(AppRoutes.login, extra: role);
  ```
  (Drops the `hiveServiceProvider` import.)

- **`owner_profile_screen.dart`** — theme toggle becomes `LocalStorage.set(StorageKeys.themeMode, ...)`. Sign-out becomes:
  ```dart
  await ref.read(authControllerProvider.notifier).logout();
  await LocalStorage.remove(StorageKeys.userRole);
  ref.read(roleProvider.notifier).state = null;
  if (context.mounted) context.goNamed(AppRoutes.onboarding);
  ```

- **`login_screen.dart`** — the `kDebugMode` JWT shortcut block becomes:
  ```dart
  await ref.read(tokenStorageProvider).saveAccessToken('phase1-dev-token');
  await LocalStorage.set(StorageKeys.userRole, role);
  ref.read(roleProvider.notifier).state = role;
  if (!context.mounted) return;
  context.goNamed(landingRouteForRole(role));
  ```
  (Real login API call is the next round.)

### 3.7 Deletions

- `lib/core/error/result.dart`
- `lib/core/error/app_exception.dart`
- `lib/core/error/app_failure.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/network/dio_client.dart`
- `lib/core/network/dio_provider.dart`
- `lib/core/network/` directory itself (after files removed)
- `lib/core/storage/hive_service.dart`
- `lib/core/storage/hive_service_provider.dart`
- `lib/core/constants/hive_keys.dart`

The `lib/core/error/` directory is left empty for now (could be re-used by future error types).

## 4. Data flow (signup, happy path)

```
RegisterScreen.onCreateAccount
  └─ ref.read(authControllerProvider.notifier).register(...)
       └─ state = AuthState(status: loading)        ──► spinner + disabled button
       └─ AuthRepository.register(request)
            └─ ApiClient.rawPost('/auth/register', body)
                 ├─ Dio adds Authorization header (no token yet — header absent)
                 └─ returns Response<Map<String,dynamic>>
            └─ ApiResponse.fromJson(body, AuthResponse.fromJson)
                 ├─ success: true → ok
                 └─ AuthResponse{accessToken, refreshToken, user}
            └─ TokenStorage.saveTokens(accessToken, refreshToken)
                 └─ FlutterSecureStorage.write(key, value) ×2
       └─ LocalStorage.set(StorageKeys.userRole, role)
       └─ LocalStorage.set(StorageKeys.currentUserId, user.id)
       └─ ref.read(roleProvider.notifier).state = role
       └─ state = AuthState(status: authenticated, user, role)
RegisterScreen.ref.listen
  └─ AuthStatus.authenticated detected
       └─ context.goNamed(landingRouteForRole(role))
```

## 5. Error mapping

| Backend / network | `ApiError` (client) | `AuthException` (repo) | UI |
|---|---|---|---|
| 400 | `ApiError(statusCode: 400, message: backendMsg)` | `AuthException(backendMsg, code: '400')` | SnackBar — backend `message` verbatim |
| 409 | `ApiError(statusCode: 409, message: "Email already registered as <role>")` | `AuthException(msg, code: '409')` | SnackBar — verbatim |
| 5xx | `ApiError(statusCode: 500..., message: "Something went wrong, please try again.")` | `AuthException(msg, code: '5xx')` | SnackBar — generic |
| Timeout | `ApiError.timeout()` → `"Request timed out. Please try again."` | `AuthException(msg, code: 'TIMEOUT')` | SnackBar — timeout |
| Connection / DNS | `ApiError.network()` → `"No connection. Check your internet and try again."` | `AuthException(msg, code: 'NETWORK_ERROR')` | SnackBar — offline |
| Anything else | `ApiError.unknown()` | `AuthException("Something went wrong while signing up")` | SnackBar |

The UI presentation is identical across all cases (SnackBar with `state.errorMessage`). The mapping table exists so messages are consistent in source.

## 6. Persistence shape (post-signup)

| Store | Key | Value | Source |
|---|---|---|---|
| `FlutterSecureStorage` | `access_token` | `'eyJhbGc...'` | `AuthResponse.accessToken` |
| `FlutterSecureStorage` | `refresh_token` | `'eyJhbGc...'` | `AuthResponse.refreshToken` |
| Hive (`coachfinder_settings`) | `user_role` | `'owner'` (etc.) | `RegisterRequest.userType` |
| Hive (`coachfinder_settings`) | `current_user_id` | `'67234c0...'` | `response.user.id` |
| Hive (`coachfinder_settings`) | `theme_mode` | `'light'` / `'dark'` / `'system'` | Owner Profile toggle |

The full user JSON (`name`, `email`, etc.) is **not cached** this round — the next protected call (or `/me` in a later round) fetches a fresh copy. Round 1's `keyCurrentUser` blob is dropped; only `id` is kept so the router can short-circuit redirects.

## 7. Edge cases & decisions

- **Existing Hive data on upgrade.** The old `settings` / `auth` / `cache` boxes are orphaned but never opened — Hive doesn't delete them. Users re-pick role on next onboarding. No migration code.
- **Token expiry mid-session.** `ApiClient.onError` clears `TokenStorage` on a 401 just like the old `AuthInterceptor` did. The next route-guard read of `isAuthenticated()` returns false. UI falls back to login.
- **Existing tests.** The three model tests (`user_model_test.dart`, `auth_response_model_test.dart`, `register_request_model_test.dart`) **must still pass unchanged** — the models are deliberately kept identical.
- **`role` provider duplication.** `AuthState.role` and `roleProvider` (StateProvider) both hold the role. The controller writes both atomically. The router and onboarding read `roleProvider`; the auth screens read `AuthState.role`. This is the same pattern maxinvoice uses (`userHasOrganizationsProvider` mirrored inside `AuthState`).
- **`ApiClient` lifetime.** A single instance per `ProviderScope` (via `apiClientProvider`). Owns its `Dio` + `TokenStorage`. No global singleton; tests can inject a mock.
- **No `flutter_secure_storage` for non-secret data.** Theme mode, role, and user id stay in Hive — they're not sensitive and Hive has cheaper sync reads (`LocalStorage.get<String>(...)`) which the router needs.

## 8. File-level change list (concrete)

**New files:**
- `lib/core/storage/local_storage.dart`
- `lib/core/storage/token_storage.dart`
- `lib/core/api/api_config.dart`
- `lib/core/api/api_error.dart`
- `lib/core/api/api_response.dart`
- `lib/core/api/api_client.dart`
- `lib/features/auth/data/repositories/auth_repository.dart` (in new folder)
- `lib/features/auth/data/providers/auth_providers.dart` (in new folder)
- `decisions/0030-auth-data-layer-pivot-to-maxinvoice.md`

**Modified:**
- `pubspec.yaml` — add `flutter_secure_storage: ^9.2.2`
- `lib/main.dart` — `LocalStorage.init()`, read `userRole` + `themeMode` from `LocalStorage`
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` — write role via `LocalStorage`
- `lib/features/owner/profile/presentation/screens/owner_profile_screen.dart` — theme + sign-out via new APIs
- `lib/features/auth/presentation/screens/login_screen.dart` — kDebugMode shortcut adapted
- `lib/features/auth/presentation/screens/register_screen.dart` — `authControllerProvider` + `AuthStatus`

**Deleted:**
- `lib/core/error/result.dart`
- `lib/core/error/app_exception.dart`
- `lib/core/error/app_failure.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/network/dio_client.dart`
- `lib/core/network/dio_provider.dart`
- `lib/core/storage/hive_service.dart`
- `lib/core/storage/hive_service_provider.dart`
- `lib/core/constants/hive_keys.dart`
- `lib/features/auth/data/repository/auth_remote_datasource.dart` (then `repository/` directory)
- `lib/features/auth/data/repository/auth_local_datasource.dart`
- `lib/features/auth/data/repository/auth_repository.dart` (old interface)
- `lib/features/auth/data/repository/auth_repository_impl.dart`
- `lib/features/auth/data/controllers/auth_provider.dart` (then `controllers/` directory)
- `lib/features/auth/data/models/auth_state.dart` (the sealed version — replaced by the class inside `auth_providers.dart`)

## 9. Verification

1. `flutter pub get` resolves `flutter_secure_storage`.
2. `dart format lib test` — clean.
3. `flutter analyze` → *No issues found!*.
4. `flutter test` — existing 9 tests still pass (4 User + 3 RegisterRequest + 1 AuthResponse + 1 nav).
5. `flutter build apk --debug` — builds.
6. Manual signup against the backend → form submit shows spinner → lands on role's shell → `TokenStorage.hasToken()` returns true (verify via debug print or `adb shell run-as ... grep`-ing the EncryptedSharedPreferences file). Verify Hive's `coachfinder_settings` box has `user_role` + `current_user_id`.
7. Retry same email → SnackBar shows the backend's 409 message verbatim.
8. Kill the backend → SnackBar shows "No connection. Check your internet and try again.".
9. Restart the app — lands on role's shell directly (token + role persist).
10. From Owner Profile → Sign out → tokens cleared, role wiped, lands on onboarding.
