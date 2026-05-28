# Auth Data-Layer Pivot to Maxinvoice Architecture — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the round-1 `HiveService` + `Notifier<sealed AuthState>` + `Result<T>` + `Remote/LocalDataSource` data layer with the maxinvoice-app pattern: `LocalStorage` (static Hive wrapper) + `TokenStorage` (secure storage) + `ApiClient` (Dio wrapper) + single concrete `AuthRepository` throwing `AuthException` + `StateNotifier<AuthState>` with `AuthStatus` enum, organised under `data/{models, providers, repositories}/`.

**Architecture:** Build new infrastructure first (Tasks 1-9), then migrate each `HiveService` consumer one at a time (Tasks 10-14) while keeping the codebase runnable, then delete obsolete files in one cleanup task (Task 15). Every task ends with `flutter analyze` clean + a commit.

**Tech Stack:** Flutter + Dart 3, `dio: ^5.4.3+1`, `hive_flutter`, **new** `flutter_secure_storage: ^9.2.2`, `flutter_riverpod` (legacy `StateNotifier` + `StateNotifierProvider`).

**Source spec:** `docs/superpowers/specs/2026-05-28-auth-maxinvoice-pivot-design.md`

---

## File structure

**New files:**
- `lib/core/storage/local_storage.dart`
- `lib/core/storage/token_storage.dart`
- `lib/core/api/api_config.dart`
- `lib/core/api/api_error.dart`
- `lib/core/api/api_response.dart`
- `lib/core/api/api_client.dart`
- `lib/features/auth/data/repositories/auth_repository.dart`
- `lib/features/auth/data/providers/auth_providers.dart`
- `decisions/0030-auth-data-layer-pivot-to-maxinvoice.md`

**Modified files:**
- `pubspec.yaml` — add `flutter_secure_storage`
- `lib/main.dart` — `LocalStorage.init()`, read role + theme from `LocalStorage`
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` — write role via `LocalStorage`
- `lib/features/owner/profile/presentation/screens/owner_profile_screen.dart` — theme + sign-out via new APIs
- `lib/features/auth/presentation/screens/login_screen.dart` — `kDebugMode` shortcut adapted to new storage
- `lib/features/auth/presentation/screens/register_screen.dart` — wired to `authControllerProvider`

**Deleted (in Task 15):**
- `lib/core/error/result.dart`
- `lib/core/error/app_exception.dart`
- `lib/core/error/app_failure.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/network/dio_client.dart`
- `lib/core/network/dio_provider.dart`
- `lib/core/storage/hive_service.dart`
- `lib/core/storage/hive_service_provider.dart`
- `lib/core/constants/hive_keys.dart`
- `lib/features/auth/data/repository/auth_remote_datasource.dart`
- `lib/features/auth/data/repository/auth_local_datasource.dart`
- `lib/features/auth/data/repository/auth_repository.dart` (old interface)
- `lib/features/auth/data/repository/auth_repository_impl.dart`
- `lib/features/auth/data/controllers/auth_provider.dart`
- `lib/features/auth/data/models/auth_state.dart` (sealed version)

**Conventions reminder:**
- Project package name: `coachfinder`.
- `///` doc comments on every class + public method.
- No hardcoded magic strings — `StorageKeys` + `ApiConfig` hold them.
- Existing model tests (`user_model_test.dart`, `auth_response_model_test.dart`, `register_request_model_test.dart`) must keep passing — the models themselves don't change.
- Every task ends with `flutter analyze` clean + a commit. (`pubspec` changes also need `flutter pub get`.)

---

## Task 1: Add `flutter_secure_storage` package

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Read pubspec.yaml** to locate the `dependencies:` block and the line where `dio:` sits.

- [ ] **Step 2: Add the dependency**

Insert `flutter_secure_storage: ^9.2.2` directly below the existing `dio:` line in the `dependencies:` section.

- [ ] **Step 3: Resolve dependencies**

```bash
flutter pub get
```

Expected: `Resolving dependencies...` then `Got dependencies!` (or `Changed N dependencies!`). No errors.

- [ ] **Step 4: Verify analyze still clean**

```bash
flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build(deps): add flutter_secure_storage ^9.2.2 for TokenStorage

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: `LocalStorage` static wrapper + `StorageKeys`

**Files:**
- Create: `lib/core/storage/local_storage.dart`

- [ ] **Step 1: Create the file**

```dart
/// Static Hive-backed key-value store and the constants for its keys.
library;

import 'package:hive_flutter/hive_flutter.dart';

/// App-wide settings store backed by a single Hive box. Mirrors the
/// `LocalStorage` pattern used in the user's other Flutter project so the two
/// codebases share a single mental model.
///
/// Call [init] once from `main` before any reads or writes.
class LocalStorage {
  static const String _boxName = 'coachfinder_settings';
  static Box? _box;

  /// Opens the single backing Hive box. Idempotent — safe to call multiple
  /// times.
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Reads the value stored under [key], or [defaultValue] when absent.
  /// Returns null when the store hasn't been initialised yet.
  static T? get<T>(String key, {T? defaultValue}) {
    return _box?.get(key, defaultValue: defaultValue) as T?;
  }

  /// Writes [value] under [key]. No-op when [init] hasn't been called.
  static Future<void> set<T>(String key, T value) async {
    await _box?.put(key, value);
  }

  /// Deletes the entry under [key], if any.
  static Future<void> remove(String key) async {
    await _box?.delete(key);
  }

  /// Wipes every entry in the box (used by test setup; rarely in app code).
  static Future<void> clear() async {
    await _box?.clear();
  }

  /// True iff [key] is present in the box.
  static bool containsKey(String key) => _box?.containsKey(key) ?? false;
}

/// String constants for every key written through [LocalStorage]. Centralised
/// so refactors don't drift through hard-coded strings.
class StorageKeys {
  StorageKeys._();

  /// Persisted ThemeMode (one of `'light'`, `'dark'`, `'system'`).
  static const String themeMode = 'theme_mode';

  /// Active user role (one of `'student'`, `'owner'`, `'teacher'`).
  static const String userRole = 'user_role';

  /// Mongo ObjectId of the currently authenticated user, captured from the
  /// last `/auth/register` (or `/auth/login`, future round) response.
  static const String currentUserId = 'current_user_id';
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/core/storage/local_storage.dart && flutter analyze lib/core/storage
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/core/storage/local_storage.dart
git commit -m "feat(storage): add LocalStorage static wrapper + StorageKeys

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: `TokenStorage`

**Files:**
- Create: `lib/core/storage/token_storage.dart`

- [ ] **Step 1: Create the file**

```dart
/// Secure-storage wrapper for the access and refresh JWTs.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the auth tokens in platform secure storage (Keychain on iOS,
/// EncryptedSharedPreferences on Android, `libsecret` on Linux). Mirrors the
/// pattern used in the user's other Flutter project.
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Writes the access token.
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  /// Returns the cached access token, or null when none is present.
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  /// Writes the refresh token.
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  /// Returns the cached refresh token, or null when none is present.
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// Persists both tokens in one call. Refresh token is optional — when null
  /// the existing refresh value is left untouched.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  /// Deletes both tokens. Called on logout or 401 reuse.
  Future<void> clearTokens() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  /// Best-effort "is logged in" check. Returns true iff an access token is
  /// present and non-empty. Does not verify against the server; the next
  /// protected call will 401-and-clear if the token has actually expired.
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// True iff an access token is present (may be empty / invalid).
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null;
  }
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/core/storage/token_storage.dart && flutter analyze lib/core/storage
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/core/storage/token_storage.dart
git commit -m "feat(storage): add TokenStorage (flutter_secure_storage wrapper)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: `ApiConfig`

**Files:**
- Create: `lib/core/api/api_config.dart`

- [ ] **Step 1: Create the file**

```dart
/// HTTP base URL, timeouts, and backend endpoint path constants.
library;

/// Backend connection configuration. Single source of truth for the base URL
/// the [ApiClient] dials and the path constants every repository quotes.
class ApiConfig {
  ApiConfig._();

  /// Base URL for the local dev backend (Android emulator host loopback).
  /// iOS simulator + physical-device URL switching is out of scope per ADR 0002.
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  /// Dio connection timeout.
  static const Duration connectionTimeout = Duration(seconds: 15);

  /// Dio receive timeout.
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth endpoint paths (added as the corresponding features wire up).
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/core/api/api_config.dart && flutter analyze lib/core/api
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/core/api/api_config.dart
git commit -m "feat(api): add ApiConfig (base URL + timeouts + endpoint paths)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: `ApiError`

**Files:**
- Create: `lib/core/api/api_error.dart`

- [ ] **Step 1: Create the file**

```dart
/// Structured exception type the ApiClient throws on HTTP / network failure.
library;

/// The single exception type the [ApiClient] throws. Repositories catch
/// `ApiError`, optionally translate to a feature-specific exception (e.g.
/// `AuthException`), and let it bubble up to the controller layer.
class ApiError implements Exception {
  const ApiError({
    this.statusCode,
    required this.message,
    this.errorCode,
  });

  /// HTTP status code, when the failure came from a server response.
  final int? statusCode;

  /// User-safe failure message. Prefer the backend's `message` field when
  /// available (the project's backend already returns user-friendly strings).
  final String message;

  /// Optional sentinel — set to `'NETWORK_ERROR'`, `'TIMEOUT'`, or
  /// `'UNKNOWN'` for the factory variants below; null when the error came
  /// from a structured server response.
  final String? errorCode;

  /// Parses a backend error envelope (`{status: 'error', message: ...}`)
  /// into an [ApiError]. Falls back to a generic message when `message`
  /// is absent or non-string.
  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiError(
      statusCode: statusCode,
      message: (json['message'] as String?) ?? 'An error occurred',
      errorCode: json['errorCode'] as String?,
    );
  }

  /// Connectivity / DNS failure — no response reached the client.
  factory ApiError.network({String? message}) => ApiError(
        message: message ?? 'No connection. Check your internet and try again.',
        errorCode: 'NETWORK_ERROR',
      );

  /// Connection or receive timeout.
  factory ApiError.timeout() => const ApiError(
        message: 'Request timed out. Please try again.',
        errorCode: 'TIMEOUT',
      );

  /// Catch-all for genuinely unexpected failures.
  factory ApiError.unknown() => const ApiError(
        message: 'Something went wrong, please try again.',
        errorCode: 'UNKNOWN',
      );

  /// True for HTTP 401.
  bool get isUnauthorized => statusCode == 401;

  /// True for any 5xx response.
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiError: $message (code: $statusCode)';
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/core/api/api_error.dart && flutter analyze lib/core/api
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/core/api/api_error.dart
git commit -m "feat(api): add ApiError exception with factories + classifiers

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: `ApiResponse<T>`

**Files:**
- Create: `lib/core/api/api_response.dart`

- [ ] **Step 1: Create the file**

```dart
/// Generic envelope wrapper for backend responses.
library;

/// Generic wrapper around `{success, data, message}` response envelopes.
///
/// When [fromJson] returns a non-null payload extractor:
///   1. If the response has a `data` field (standard envelope), the
///      extractor parses that field.
///   2. Otherwise the extractor parses the top-level JSON map (auth
///      endpoints — `{success, accessToken, refreshToken, user}` — return
///      the payload at the top level rather than nested).
///
/// This dual-mode keeps every repository call site identical regardless of
/// which envelope variant the backend used.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  /// Backend's `success` flag. Defaults to `true` if absent (older endpoints).
  final bool success;

  /// Parsed payload, present when [fromJson] is supplied and the body
  /// contained either a `data` field or a top-level payload.
  final T? data;

  /// Backend's `message` field — used for both success notices and error
  /// messages.
  final String? message;

  /// Parses [json] into an [ApiResponse<T>]. See class docs for the
  /// data-vs-top-level fallback logic.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json)? fromJsonT,
  ) {
    final bool success = (json['success'] as bool?) ?? true;
    T? data;
    if (fromJsonT != null) {
      final dynamic raw = json['data'] ?? json;
      if (raw is Map<String, dynamic>) {
        data = fromJsonT(raw);
      }
    }
    return ApiResponse<T>(
      success: success,
      data: data,
      message: json['message'] as String?,
    );
  }

  /// True iff a parsed payload is present.
  bool get hasData => data != null;

  /// True when the backend reported failure.
  bool get hasError => !success;
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/core/api/api_response.dart && flutter analyze lib/core/api
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/core/api/api_response.dart
git commit -m "feat(api): add ApiResponse<T> with envelope/top-level fallback

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: `ApiClient`

**Files:**
- Create: `lib/core/api/api_client.dart`

- [ ] **Step 1: Create the file**

```dart
/// Dio wrapper handling auth-header injection and structured error mapping.
library;

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_config.dart';
import 'api_error.dart';
import 'api_response.dart';

/// The single HTTP entry point repositories use. Wraps Dio with:
///   - an interceptor that injects `Authorization: Bearer <accessToken>` on
///     every outbound request when [TokenStorage] has one;
///   - a 401 handler that clears [TokenStorage] so the next route guard
///     forces re-login (refresh-token rotation is a later round);
///   - error mapping from [DioException] into the structured [ApiError]
///     types — timeouts, network failures, 4xx with backend `message`, and
///     a generic 5xx.
///
/// Inject a [TokenStorage] (or a [Dio]) for tests; the defaults are fine in
/// app code.
class ApiClient {
  ApiClient({TokenStorage? tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = dio ?? _createDio();
    _setupInterceptors();
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio _createDio() {
    return Dio(
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
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
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
      ),
    );
  }

  /// Issues `POST [path]` with [data] as the body, parses the response into
  /// [ApiResponse<T>] using [fromJson] when provided. Throws [ApiError] on
  /// HTTP / network failure.
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(path, data: data);
      return ApiResponse<T>.fromJson(
        response.data ?? <String, dynamic>{},
        fromJson,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Issues `GET [path]`, parses the response into [ApiResponse<T>] using
  /// [fromJson] when provided. Throws [ApiError] on HTTP / network failure.
  Future<ApiResponse<T>> get<T>(
    String path, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(path);
      return ApiResponse<T>.fromJson(
        response.data ?? <String, dynamic>{},
        fromJson,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Issues `POST [path]` with [data] and returns the raw [Response] so
  /// callers can wrap with [ApiResponse.fromJson] using a custom payload
  /// extractor. Used by the auth repository, where the envelope shape is
  /// non-standard (`{success, accessToken, refreshToken, user}` at the top
  /// level rather than under `data`).
  Future<Response<Map<String, dynamic>>> rawPost(
    String path, {
    dynamic data,
  }) async {
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
          return ApiError(
            statusCode: status,
            message: 'Something went wrong, please try again.',
          );
        }
        return ApiError.unknown();
    }
  }
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/core/api/api_client.dart && flutter analyze lib/core/api
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/core/api/api_client.dart
git commit -m "feat(api): add ApiClient (Dio wrapper with auth + error mapping)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: New `AuthRepository` (single concrete class)

**Files:**
- Create: `lib/features/auth/data/repositories/auth_repository.dart`

(This goes in the NEW `repositories/` folder, NOT the old `repository/`. Both folders coexist until Task 15 cleanup.)

- [ ] **Step 1: Create the file**

```dart
/// Concrete AuthRepository talking to the backend via ApiClient.
library;

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/api/api_error.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/auth_response_model.dart';
import '../models/register_request_model.dart';

/// Feature-specific exception thrown by [AuthRepository] on failure.
/// Controllers catch this and translate to [AuthState.error].
class AuthException implements Exception {
  AuthException(this.message, {this.code});

  /// User-safe failure message — already the backend's `message` field where
  /// available.
  final String message;

  /// Optional sentinel (HTTP status code as string, or `'NETWORK_ERROR'` /
  /// `'TIMEOUT'` / `'UNKNOWN'`).
  final String? code;

  @override
  String toString() => message;
}

/// Single concrete repository owning every auth operation. Throws
/// [AuthException] on failure. Persists tokens via [TokenStorage] on success.
class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Calls `POST /api/auth/register` and persists the returned tokens.
  /// Returns the parsed [AuthResponse] (including the new [User]).
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

  /// True iff a non-empty access token is cached locally. Does not verify
  /// against the server.
  Future<bool> isAuthenticated() => _tokenStorage.isTokenValid();

  /// Returns the cached access token, or null when none is present.
  Future<String?> getAccessToken() => _tokenStorage.getAccessToken();

  /// Local-only sign-out: clears the cached tokens. (The server's `/logout`
  /// is wired in a later round.)
  Future<void> logout() => _tokenStorage.clearTokens();
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/data/repositories/auth_repository.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/repositories/auth_repository.dart
git commit -m "feat(auth): add concrete AuthRepository in repositories/ folder

Throws AuthException; persists tokens via TokenStorage on success. Lives
alongside the old data/repository/ files until Task 15 cleanup.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: New `auth_providers.dart` (`AuthController` + providers)

**Files:**
- Create: `lib/features/auth/data/providers/auth_providers.dart`

(NEW `providers/` folder, NOT the old `controllers/`.)

- [ ] **Step 1: Create the file**

```dart
/// AuthState, AuthController (StateNotifier), and Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Discrete states the auth flow can be in.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Snapshot consumed by [RegisterScreen] / [LoginScreen] and the router.
/// `role` is mirrored to the top-level [roleProvider] inside the controller.
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.role,
    this.errorMessage,
  });

  /// Current step in the auth flow.
  final AuthStatus status;

  /// Authenticated user, when [status] is `authenticated`.
  final User? user;

  /// `'student'` / `'owner'` / `'teacher'` — also mirrored in [roleProvider].
  final String? role;

  /// User-safe error string, when [status] is `error`.
  final String? errorMessage;

  /// Convenience predicates.
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  /// Field-wise copy. `errorMessage` deliberately replaces (not falls back)
  /// so callers can clear it by passing `errorMessage: null`.
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? role,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      errorMessage: errorMessage,
    );
  }
}

/// Composes [ApiClient] (which owns [TokenStorage]) into the [AuthRepository].
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(),
);

/// Direct access to the secure token store — used by [LoginScreen]'s
/// kDebugMode shortcut and future logout paths.
final Provider<TokenStorage> tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(),
);

/// The repository surface controllers consume.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  return AuthRepository(apiClient, tokenStorage);
});

/// Holds the [AuthState] and exposes the signup mutation. Writes through to
/// [LocalStorage] + [roleProvider] on success so the router and other screens
/// stay in sync.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._ref) : super(const AuthState());

  final AuthRepository _repository;
  final Ref _ref;

  /// Calls `POST /api/auth/register` via the repository, persists
  /// `currentUserId` + `userRole` to [LocalStorage], updates [roleProvider],
  /// and flips state through Loading → Authenticated. On failure flips to
  /// Error with the backend's verbatim message.
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

  /// Local-only sign-out: clears tokens + `currentUserId` (preserves the
  /// role so re-login lands on the same shell) + drops the state to
  /// Unauthenticated.
  Future<void> logout() async {
    await _repository.logout();
    await LocalStorage.remove(StorageKeys.currentUserId);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Resets [AuthState.errorMessage] to null without changing status. Used
  /// by screens that want to dismiss an error without re-submitting.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// The active auth state — consumed by RegisterScreen, OwnerProfileScreen,
/// and the router.
final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository, ref);
});
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/data/providers/auth_providers.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/providers/auth_providers.dart
git commit -m "feat(auth): add AuthState/AuthController + providers in providers/

StateNotifier<AuthState> with AuthStatus enum. Wraps the new AuthRepository
+ writes through to LocalStorage and the top-level roleProvider. Lives
alongside the old data/controllers/ until Task 15 cleanup.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Migrate `main.dart` to `LocalStorage.init`

**Files:**
- Modify: `lib/main.dart`

`HiveService.instance.init()` stays for now (until Task 15) so unmigrated screens (owner profile, etc.) keep working. `LocalStorage.init()` is added; reads switch to `LocalStorage`.

- [ ] **Step 1: Replace the file contents entirely**

```dart
/// Application entry point.
///
/// Initialises [LocalStorage] (and the legacy [HiveService] until Task 15),
/// hydrates the role + theme from local storage, then mounts the
/// [CoachFinderApp] inside a Riverpod [ProviderScope].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/hive_keys.dart';
import 'core/providers/role_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/router/router_provider.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // New LocalStorage is the authoritative store; HiveService stays alive
  // for unmigrated consumers until Task 15 cleans it up.
  await LocalStorage.init();
  await HiveService.instance.init();

  final initialRole = LocalStorage.get<String>(StorageKeys.userRole);
  final initialThemeMode = themeModeFromStorage(
    LocalStorage.get<String>(StorageKeys.themeMode),
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        roleProvider.overrideWith((ref) => initialRole),
        themeModeProvider.overrideWith((ref) => initialThemeMode),
      ],
      child: const CoachFinderApp(),
    ),
  );
}

/// Root [MaterialApp] for CoachFinder. Reads the [GoRouter] from
/// [routerProvider] so any rebuild driven by upstream providers triggers a
/// router refresh.
class CoachFinderApp extends ConsumerWidget {
  const CoachFinderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

**Note:** the `hive_keys.dart` import is preserved for now because other unmigrated screens still rely on it. It's deleted in Task 15.

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/main.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "refactor(main): init LocalStorage and read role/theme from it

HiveService.init still runs alongside until Task 15 cleanup. Role and
theme are now sourced from LocalStorage so onboarding writes flow through
correctly.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Migrate `onboarding_screen.dart` to `LocalStorage`

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`

Only the `handleContinue` function and its imports change. The whole UI tree stays.

- [ ] **Step 1: Read the current file** to confirm line numbers.

```bash
grep -n "hive_service_provider\|hiveServiceProvider\|HiveKeys.keyUserRole\|handleContinue" lib/features/onboarding/presentation/screens/onboarding_screen.dart
```

- [ ] **Step 2: Replace the two import lines**

In the import block at the top of the file, swap:

```dart
import '../../../../core/constants/hive_keys.dart';
import '../../../../core/storage/hive_service_provider.dart';
```

with:

```dart
import '../../../../core/storage/local_storage.dart';
```

- [ ] **Step 3: Rewrite the `handleContinue` function**

Find the current `handleContinue` function:

```dart
Future<void> handleContinue() async {
  final role = selectedRole.value;
  if (role == null) return;
  final hive = ref.read(hiveServiceProvider);
  await hive.settingsBox.put(HiveKeys.keyUserRole, role);
  ref.read(roleProvider.notifier).state = role;
  if (!context.mounted) return;
  context.goNamed(AppRoutes.login, extra: role);
}
```

Replace with:

```dart
Future<void> handleContinue() async {
  final role = selectedRole.value;
  if (role == null) return;
  await LocalStorage.set(StorageKeys.userRole, role);
  ref.read(roleProvider.notifier).state = role;
  if (!context.mounted) return;
  context.goNamed(AppRoutes.login, extra: role);
}
```

- [ ] **Step 4: Verify analyze clean**

```bash
dart format lib/features/onboarding/presentation/screens/onboarding_screen.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/screens/onboarding_screen.dart
git commit -m "refactor(onboarding): write role via LocalStorage instead of HiveService

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: Migrate `owner_profile_screen.dart`

**Files:**
- Modify: `lib/features/owner/profile/presentation/screens/owner_profile_screen.dart`

Two changes: theme toggle now writes through `LocalStorage`; sign-out now goes through `authControllerProvider.logout()`.

- [ ] **Step 1: Read the current file** to identify the two touched blocks.

```bash
grep -n "hive_service_provider\|HiveKeys\|hiveServiceProvider" lib/features/owner/profile/presentation/screens/owner_profile_screen.dart
```

Expected lines (from a prior `grep`): 14, 41-42, 76-79.

- [ ] **Step 2: Replace imports**

Swap:

```dart
import '../../../../../core/constants/hive_keys.dart';
import '../../../../../core/storage/hive_service_provider.dart';
```

(or whichever subset is present — `hive_keys.dart` should be removed; `hive_service_provider.dart` should be removed) with:

```dart
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../auth/data/providers/auth_providers.dart';
```

(`app_routes.dart` may already be imported; merge into the existing block alphabetically.)

- [ ] **Step 3: Rewrite the theme toggle write**

Find:

```dart
ref.read(hiveServiceProvider).settingsBox.put(
      HiveKeys.keyThemeMode,
      ...
    );
```

Replace with:

```dart
LocalStorage.set(StorageKeys.themeMode, ...);
```

(Where `...` is the exact ThemeMode string the existing code passes — preserve it verbatim.)

- [ ] **Step 4: Rewrite the sign-out block**

Find the block (around lines 76–79):

```dart
final hive = ref.read(hiveServiceProvider);
await hive.authBox.delete(HiveKeys.keyJwtToken);
await hive.authBox.delete(HiveKeys.keyCurrentUser);
await hive.settingsBox.delete(HiveKeys.keyUserRole);
```

Replace with:

```dart
await ref.read(authControllerProvider.notifier).logout();
await LocalStorage.remove(StorageKeys.userRole);
ref.read(roleProvider.notifier).state = null;
```

If the surrounding context navigates (e.g. `context.goNamed(AppRoutes.onboarding)`), preserve that line as-is — don't drop it. If the surrounding code doesn't navigate, that's a pre-existing UX gap and is out of scope.

- [ ] **Step 5: Verify analyze clean**

```bash
dart format lib/features/owner/profile/presentation/screens/owner_profile_screen.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 6: Commit**

```bash
git add lib/features/owner/profile/presentation/screens/owner_profile_screen.dart
git commit -m "refactor(owner-profile): theme + sign-out via new storage/auth APIs

Theme writes go through LocalStorage; sign-out goes through
authControllerProvider.logout (which clears secure tokens) + removes the
role from LocalStorage + clears roleProvider.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 13: Migrate `login_screen.dart` (`kDebugMode` shortcut on new storage)

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`

The screen still uses the `kDebugMode` test-credential shortcut (real login API is out of scope this round). Only the persistence side changes.

- [ ] **Step 1: Read the current file**

```bash
grep -n "hive_service_provider\|hiveServiceProvider\|HiveKeys" lib/features/auth/presentation/screens/login_screen.dart
```

- [ ] **Step 2: Replace imports**

Swap:

```dart
import '../../../../core/constants/hive_keys.dart';
import '../../../../core/storage/hive_service_provider.dart';
```

with:

```dart
import '../../../../core/storage/local_storage.dart';
import '../../data/providers/auth_providers.dart';
```

- [ ] **Step 3: Rewrite the kDebugMode block**

Find this block inside `handleSignIn`:

```dart
final hive = ref.read(hiveServiceProvider);
await hive.authBox.put(HiveKeys.keyJwtToken, 'phase1-dev-token');
final role = ref.read(roleProvider) ?? initialRole ?? roleStudent;
if (!context.mounted) return;
context.goNamed(landingRouteForRole(role));
```

Replace with:

```dart
final role = ref.read(roleProvider) ?? initialRole ?? roleStudent;
await ref.read(tokenStorageProvider).saveAccessToken('phase1-dev-token');
await LocalStorage.set(StorageKeys.userRole, role);
ref.read(roleProvider.notifier).state = role;
if (!context.mounted) return;
context.goNamed(landingRouteForRole(role));
```

- [ ] **Step 4: Verify analyze clean**

```bash
dart format lib/features/auth/presentation/screens/login_screen.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/screens/login_screen.dart
git commit -m "refactor(auth/login): kDebugMode shortcut now writes new storage

Token goes to TokenStorage (secure), role goes to LocalStorage. Real
login API call is a later round.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 14: Rewire `register_screen.dart` to `authControllerProvider`

**Files:**
- Modify: `lib/features/auth/presentation/screens/register_screen.dart`

- [ ] **Step 1: Replace the file contents entirely**

```dart
/// Sign Up screen — calls authController.register and reacts to AuthState.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_backdrop.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../data/providers/auth_providers.dart';
import '../auth_role_accents.dart';
import '../auth_validators.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Sign Up screen.
///
/// The form validates on submit. On valid submit, it calls
/// `ref.read(authControllerProvider.notifier).register(...)` and reacts to
/// [AuthState] transitions via `ref.listen`:
///
///  - `AuthStatus.authenticated` → route to the role's landing screen.
///  - `AuthStatus.error` → SnackBar with the failure message verbatim.
///
/// `AuthStatus.loading` greys out the Sign Up button and swaps its label for
/// a spinner. The CTA, focused input ring, and footer link all adopt the
/// active role's accent.
class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstNameCtrl = useTextEditingController();
    final lastNameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final passwordVisible = useState(false);
    final confirmVisible = useState(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final String? role = ref.watch(roleProvider) ?? initialRole;
    final Color accent = authAccent(role);
    final List<Color> orbs = authBackdropOrbs(role);
    final AuthState authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.isLoading;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!context.mounted) return;
      if (next.status == AuthStatus.authenticated && next.role != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.goNamed(landingRouteForRole(next.role!));
      } else if (next.status == AuthStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    Future<void> onCreateAccount() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final String resolvedRole =
          ref.read(roleProvider) ?? initialRole ?? roleStudent;
      await ref.read(authControllerProvider.notifier).register(
            firstName: firstNameCtrl.text,
            lastName: lastNameCtrl.text,
            email: emailCtrl.text,
            password: passwordCtrl.text,
            role: resolvedRole,
          );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: orbs,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp16,
                  AppSpacing.sp24,
                  AppSpacing.sp16,
                  AppSpacing.sp24,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        AppStrings.registerTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp4),
                      Text(
                        AppStrings.registerSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      GlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.sp16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: AuthFieldWidget(
                                    label: AppStrings.fieldFirstName,
                                    hint: AppStrings.hintFirstName,
                                    icon: Icons.person_outline,
                                    controller: firstNameCtrl,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    validator: AuthValidators.notEmpty,
                                    accent: accent,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sp8),
                                Expanded(
                                  child: AuthFieldWidget(
                                    label: AppStrings.fieldLastName,
                                    hint: AppStrings.hintLastName,
                                    icon: Icons.person_outline,
                                    controller: lastNameCtrl,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    validator: AuthValidators.notEmpty,
                                    accent: accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            AuthFieldWidget(
                              label: AppStrings.fieldEmail,
                              hint: AppStrings.hintEmail,
                              icon: Icons.mail_outline,
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.email,
                              accent: accent,
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            AuthFieldWidget(
                              label: AppStrings.fieldPassword,
                              icon: Icons.lock_outline,
                              controller: passwordCtrl,
                              obscureText: !passwordVisible.value,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.password,
                              accent: accent,
                              trailing: IconButton(
                                icon: Icon(
                                  passwordVisible.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: palette.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => passwordVisible.value =
                                    !passwordVisible.value,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            AuthFieldWidget(
                              label: AppStrings.fieldConfirmPassword,
                              icon: Icons.shield_outlined,
                              controller: confirmCtrl,
                              obscureText: !confirmVisible.value,
                              textInputAction: TextInputAction.done,
                              validator: (String? v) =>
                                  AuthValidators.confirmPassword(
                                v,
                                passwordCtrl.text,
                              ),
                              accent: accent,
                              trailing: IconButton(
                                icon: Icon(
                                  confirmVisible.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: palette.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => confirmVisible.value =
                                    !confirmVisible.value,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthPrimaryButton(
                              label: AppStrings.signUp,
                              accent: accent,
                              isLoading: isLoading,
                              onPressed: onCreateAccount,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      const AuthOrDivider(text: AppStrings.authOr),
                      const SizedBox(height: AppSpacing.sp12),
                      GlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.sp12),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: AuthOAuthButton(
                                label: AppStrings.socialGoogle,
                                icon: Icons.g_mobiledata,
                                onPressed: () =>
                                    stub(AppStrings.stubGoogleSignIn),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sp8),
                            Expanded(
                              child: AuthOAuthButton(
                                label: AppStrings.socialFacebook,
                                icon: Icons.facebook,
                                onPressed: () =>
                                    stub(AppStrings.stubAppleSignIn),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      AuthBottomLink(
                        prefix: AppStrings.alreadyHaveAccount,
                        actionLabel: AppStrings.signIn,
                        accent: accent,
                        onAction: () => context.goNamed(
                          AppRoutes.login,
                          extra: initialRole,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/presentation/screens/register_screen.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/register_screen.dart
git commit -m "refactor(auth/register): wire to new authControllerProvider

Swaps NotifierProvider<AuthNotifier, AuthState> for
StateNotifierProvider<AuthController, AuthState>. ref.listen now checks
next.status (AuthStatus enum) instead of sealed class instance-of. The
form, validators, GlassPanel, and AuthPrimaryButton.isLoading are
unchanged.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 15: Delete obsolete files + drop `HiveService.init` from `main.dart`

**Files (delete):**
- `lib/core/error/result.dart`
- `lib/core/error/app_exception.dart`
- `lib/core/error/app_failure.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/network/dio_client.dart`
- `lib/core/network/dio_provider.dart`
- `lib/core/storage/hive_service.dart`
- `lib/core/storage/hive_service_provider.dart`
- `lib/core/constants/hive_keys.dart`
- `lib/features/auth/data/repository/auth_remote_datasource.dart`
- `lib/features/auth/data/repository/auth_local_datasource.dart`
- `lib/features/auth/data/repository/auth_repository.dart`
- `lib/features/auth/data/repository/auth_repository_impl.dart`
- `lib/features/auth/data/controllers/auth_provider.dart`
- `lib/features/auth/data/models/auth_state.dart`

**Files (modify):**
- `lib/main.dart`

- [ ] **Step 1: Sanity check — confirm no remaining consumers**

```bash
grep -rn "HiveService\|HiveKeys\|hiveServiceProvider\|hive_service\|dioProvider\|AuthInterceptor\|dio_provider\|dio_client\|AppException\|AppFailure\|Result<\|auth_remote_datasource\|auth_local_datasource\|auth_repository_impl\|features/auth/data/controllers\|features/auth/data/repository\|features/auth/data/models/auth_state" lib/ test/ --include="*.dart" | grep -v ":\s*//"
```

Expected: empty output. If any line shows up, it's an unmigrated reference — fix it before deleting.

- [ ] **Step 2: Modify `lib/main.dart` — drop `HiveService.init` + its import**

Replace the file contents with:

```dart
/// Application entry point.
///
/// Initialises [LocalStorage], hydrates the role + theme from local storage,
/// then mounts the [CoachFinderApp] inside a Riverpod [ProviderScope].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/providers/role_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/router/router_provider.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorage.init();

  final initialRole = LocalStorage.get<String>(StorageKeys.userRole);
  final initialThemeMode = themeModeFromStorage(
    LocalStorage.get<String>(StorageKeys.themeMode),
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        roleProvider.overrideWith((ref) => initialRole),
        themeModeProvider.overrideWith((ref) => initialThemeMode),
      ],
      child: const CoachFinderApp(),
    ),
  );
}

/// Root [MaterialApp] for CoachFinder. Reads the [GoRouter] from
/// [routerProvider] so any rebuild driven by upstream providers triggers a
/// router refresh.
class CoachFinderApp extends ConsumerWidget {
  const CoachFinderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

(Drops the `hive_keys.dart` + `hive_service.dart` imports and the `HiveService.instance.init()` call.)

- [ ] **Step 3: Delete the obsolete files**

```bash
git rm lib/core/error/result.dart \
       lib/core/error/app_exception.dart \
       lib/core/error/app_failure.dart \
       lib/core/network/auth_interceptor.dart \
       lib/core/network/dio_client.dart \
       lib/core/network/dio_provider.dart \
       lib/core/storage/hive_service.dart \
       lib/core/storage/hive_service_provider.dart \
       lib/core/constants/hive_keys.dart \
       lib/features/auth/data/repository/auth_remote_datasource.dart \
       lib/features/auth/data/repository/auth_local_datasource.dart \
       lib/features/auth/data/repository/auth_repository.dart \
       lib/features/auth/data/repository/auth_repository_impl.dart \
       lib/features/auth/data/controllers/auth_provider.dart \
       lib/features/auth/data/models/auth_state.dart
```

- [ ] **Step 4: Remove the now-empty directories**

```bash
rmdir lib/core/network lib/features/auth/data/repository lib/features/auth/data/controllers 2>/dev/null || true
```

(`rmdir` only removes empty dirs; `|| true` keeps the script from failing if a directory already disappeared.)

- [ ] **Step 5: Verify analyze clean across the whole project**

```bash
dart format lib && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 6: Verify tests still pass**

```bash
flutter test
```

Expected: 9 tests pass (4 User + 3 RegisterRequest + 1 AuthResponse + 1 nav). All model imports continue to resolve because the model files themselves were untouched.

- [ ] **Step 7: Commit**

```bash
git add lib/main.dart
git commit -m "refactor: drop legacy data layer (HiveService, dio_*, sealed AuthState)

Removes:
  - lib/core/error/{result, app_exception, app_failure}.dart
  - lib/core/network/{auth_interceptor, dio_client, dio_provider}.dart
  - lib/core/storage/{hive_service, hive_service_provider}.dart
  - lib/core/constants/hive_keys.dart
  - lib/features/auth/data/repository/* (old interface + impl + datasources)
  - lib/features/auth/data/controllers/auth_provider.dart
  - lib/features/auth/data/models/auth_state.dart (sealed)
  - the now-empty core/network/, auth/data/repository/, auth/data/controllers/ dirs

main.dart drops the HiveService.init call. All consumers were migrated in
Tasks 10-14.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 16: ADR 0030

**Files:**
- Create: `decisions/0030-auth-data-layer-pivot-to-maxinvoice.md`

- [ ] **Step 1: Create the file**

```markdown
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
- `owner_profile_screen.dart` toggles theme through `LocalStorage` and
  signs out through `authControllerProvider.logout()` (which clears the
  secure-storage tokens).
- `login_screen.dart` keeps its `kDebugMode` test-credential shortcut but
  now writes the placeholder token to `TokenStorage` and the role to
  `LocalStorage`.
- `register_screen.dart` is wired to `authControllerProvider` —
  `ref.listen` switches on `AuthStatus` enum cases instead of sealed
  class instance-of.

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
- The 9 existing tests (8 model + 1 nav) still pass without changes; no
  new automated tests this round (the repo + controller wiring is gated
  on manual verification against the real backend, same as ADR 0029).
- Future rounds (login, refresh, /me, logout) slot in by adding methods
  to `AuthRepository` and `AuthController`. Nothing in this round needs
  re-plumbing.
```

- [ ] **Step 2: Commit**

```bash
git add decisions/0030-auth-data-layer-pivot-to-maxinvoice.md
git commit -m "docs(adr): record 0030 — auth data layer pivot to maxinvoice

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 17: Final verification

**Files:** None modified — verification only.

- [ ] **Step 1: Format clean**

```bash
dart format lib test
```

Expected: no files changed.

- [ ] **Step 2: Analyze clean**

```bash
flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: All tests pass**

```bash
flutter test
```

Expected: 9 tests pass — 4 `user_model_test.dart` + 3 `register_request_model_test.dart` + 1 `auth_response_model_test.dart` + 1 `adaptive_navigation_tooltip_test.dart`.

- [ ] **Step 4: Debug APK builds**

```bash
flutter build apk --debug
```

Expected: build completes without errors.

- [ ] **Step 5: Verify commit chain**

```bash
git log --oneline 06d2afc..HEAD
```

`06d2afc` was the spec commit; this should list the implementation commits (Tasks 1-16 = ~16 commits since).

- [ ] **Step 6: Manual signup walkthrough**

The user starts the backend separately (`cd ../server && npm run dev` per its README — must be reachable at `http://10.0.2.2:5000/api` from the Android emulator).

1. Launch the app on the Android emulator.
2. Pick a role on onboarding (try **Coaching Owner** — orange accent).
3. Tap "Sign up" from login → fill the register form with a fresh email + password ≥ 6 chars → tap "Sign Up".
4. Expect: button shows a white spinner, then routes to the owner dashboard.
5. Verify persistence via `adb shell run-as ... ls -la app_flutter/`:
   - Hive box `coachfinder_settings` exists.
   - SecureStorage (Keychain alternative on Android: encrypted shared prefs) contains `access_token` + `refresh_token` keys.
6. Re-attempt the same email → expect SnackBar **"Email already registered as owner"**, no navigation.
7. Kill the backend → try a third signup → expect SnackBar **"No connection. Check your internet and try again."**.
8. Restart the app → lands directly on the owner dashboard (cached role + tokens).
9. Owner Profile → Sign out → tokens cleared, lands on onboarding (or login, depending on whether role is also cleared — the spec preserves the role, so route is to login).

If any step fails, capture which step + the SnackBar text + the AuthController's state value if visible.

- [ ] **Step 7: No final commit needed** — bookkeeping commits in Tasks 1–16 already cover the round.

---

## Self-review notes (post-write)

**Spec coverage:** §3.1 (packages) → Task 1; §3.2 (LocalStorage / TokenStorage) → Tasks 2 + 3; §3.3 (Api*) → Tasks 4 + 5 + 6 + 7; §3.4 (auth layer) → Tasks 8 + 9; §3.5 (RegisterScreen) → Task 14; §3.6 (consumer migrations) → Tasks 10 + 11 + 12 + 13; §3.7 (deletions) → Task 15; §4 (data flow) covered by Tasks 8 + 9; §5 (error mapping) covered by Tasks 5 + 7 + 8; §6 (persistence shape) covered by Tasks 2 + 3 + 9; §7 (edge cases) covered transitively; §8 (file-level list) matches; §9 (verification) → Task 17.

**Placeholder scan:** No `TODO` / `TBD` / "implement later" / "add appropriate error handling" / "similar to Task N" in any step. Every code-changing step shows the exact code; every command step shows the exact command + expected output.

**Type consistency:** `AuthResponse.accessToken` (round-1 rename verified earlier this session); `AuthRepository.register(RegisterRequest)`; `ApiClient.rawPost(path, {data})`; `AuthController.register({firstName, lastName, email, password, role})`; `AuthStatus` enum cases (`initial`, `loading`, `authenticated`, `unauthenticated`, `error`); `StorageKeys.themeMode` / `.userRole` / `.currentUserId`. All consistent across Tasks 2-15.

**Sequencing fragility:** Task 15's deletions are blocked on Task 10 (main.dart no longer depends on HiveService.init) + Tasks 11-14 (consumers migrated). Each migration task leaves the codebase analyze-clean by keeping the old files alongside the new during Tasks 8-14. The grep in Task 15 Step 1 is a hard sanity check before any file removals.
