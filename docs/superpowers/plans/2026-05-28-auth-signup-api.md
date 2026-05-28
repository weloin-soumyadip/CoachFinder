# Auth Signup API Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `RegisterScreen`'s `kDebugMode` JWT shortcut with a real Riverpod-driven call to `POST /api/auth/register`, persist the access token + refresh token + user + role to Hive, and route the user into the role's landing screen on success.

**Architecture:** Fill in the empty `// TODO: implement` files under `lib/features/auth/data/`. Models / data sources / repository / controller designed to host login / refresh / `/me` later — only `register()` is wired this round. A new generic `Result<T>` lives in `lib/core/error/` so any future feature repo can use the same Ok / Err pattern. Errors map `AppException` (thrown in data sources) → `AppFailure` (returned as `Err` from the repo) → `AuthError` state → SnackBar in the screen.

**Tech Stack:** Flutter + Dart 3 sealed classes, `dio: ^5.4.3+1`, `hooks_riverpod`, `Hive` via existing `HiveService`. `Notifier<AuthState>` from Riverpod 2.

**Source spec:** `docs/superpowers/specs/2026-05-28-auth-signup-api-design.md`
**Backend contract:** `/home/weloin/Projects/practice/Claude-practice/coaching-app/server/api.md` § `POST /api/auth/register`

---

## File structure

**New files:**
- `lib/core/error/result.dart` — generic `Result<T>` (`Ok<T>` / `Err<T>`)
- `lib/features/auth/data/models/register_request_model.dart` — `RegisterRequest.toJson`
- `lib/features/auth/data/models/auth_state.dart` — sealed `AuthState`
- `test/features/auth/data/models/user_model_test.dart` — `User.fromJson` / `toJson`
- `test/features/auth/data/models/auth_response_model_test.dart` — `AuthResponse.fromJson`
- `test/features/auth/data/models/register_request_model_test.dart` — `RegisterRequest.toJson`
- `decisions/0029-auth-data-layer-and-signup-wiring.md` — ADR

**Filled in (currently `// TODO: implement` stubs):**
- `lib/features/auth/data/models/user_model.dart`
- `lib/features/auth/data/models/auth_response_model.dart`
- `lib/features/auth/data/repository/auth_remote_datasource.dart`
- `lib/features/auth/data/repository/auth_local_datasource.dart`
- `lib/features/auth/data/repository/auth_repository.dart`
- `lib/features/auth/data/repository/auth_repository_impl.dart`
- `lib/features/auth/data/controllers/auth_provider.dart`

**Modified:**
- `lib/core/constants/hive_keys.dart` — add `keyRefreshToken`
- `lib/features/auth/presentation/widgets/auth_widgets.dart` — `AuthPrimaryButton` gains `isLoading`
- `lib/features/auth/presentation/screens/register_screen.dart` — wire `authProvider`

**Conventions reminder:**
- Every class + public method gets a `///` doc comment.
- No hardcoded values — strings → `AppStrings`; colors → `context.palette.*` / `AppColors.*`; sizes → `AppSpacing.*`; durations / numerics → `AppEffects.*`.
- Each task ends with `flutter analyze` clean + a commit.

---

## Task 1: Add `Result<T>` to `lib/core/error/`

**Files:**
- Create: `lib/core/error/result.dart`

- [ ] **Step 1: Create the file**

```dart
/// Sealed result type carrying either a success value or an [AppFailure].
library;

import 'app_failure.dart';

/// Either an [Ok] success value of type [T] or an [Err] wrapping an
/// [AppFailure]. Used by repository methods so failures stay values (the
/// project convention — see `app_failure.dart`) instead of being thrown.
///
/// Pattern-match at call sites:
///
/// ```dart
/// switch (result) {
///   case Ok<MyType>(value: final v): ...
///   case Err<MyType>(failure: final f): ...
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Success variant of [Result] carrying the produced [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// The successful result value.
  final T value;
}

/// Failure variant of [Result] carrying the [AppFailure] the repository
/// produced when mapping a data-source exception.
final class Err<T> extends Result<T> {
  const Err(this.failure);

  /// The structured failure value safe to surface in the UI.
  final AppFailure failure;
}
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/core/error/result.dart && flutter analyze lib/core/error
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/core/error/result.dart
git commit -m "feat(core): add generic Result<T> for repository returns

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Add `keyRefreshToken` to `HiveKeys`

**Files:**
- Modify: `lib/core/constants/hive_keys.dart`

- [ ] **Step 1: Add the new key**

Edit `lib/core/constants/hive_keys.dart` — append inside the `boxAuth` section so the section reads:

```dart
  // Keys inside [boxAuth]
  static const String keyJwtToken = 'jwt_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyCurrentUser = 'current_user';
```

- [ ] **Step 2: Verify clean analyze**

```bash
dart format lib/core/constants/hive_keys.dart && flutter analyze lib/core
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/hive_keys.dart
git commit -m "feat(core): add keyRefreshToken to HiveKeys

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: `User` model + tests

**Files:**
- Modify: `lib/features/auth/data/models/user_model.dart`
- Create: `test/features/auth/data/models/user_model_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/auth/data/models/user_model_test.dart`:

```dart
import 'package:coaching_app/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.fromJson', () {
    test('maps backend _id to id', () {
      final user = User.fromJson(<String, dynamic>{
        '_id': '67234c0e7e1c0a4d5f6a7b8c',
        'name': 'Alice',
        'email': 'alice@example.com',
        'phone': '+919999999999',
        'profileImage': '',
        'isActive': true,
        'isEmailVerified': false,
        'createdAt': '2026-05-28T10:00:00.000Z',
        'updatedAt': '2026-05-28T10:00:00.000Z',
      });
      expect(user.id, '67234c0e7e1c0a4d5f6a7b8c');
      expect(user.name, 'Alice');
      expect(user.email, 'alice@example.com');
      expect(user.phone, '+919999999999');
      expect(user.profileImage, '');
      expect(user.isActive, true);
      expect(user.isEmailVerified, false);
      expect(user.createdAt.toUtc().toIso8601String(),
          '2026-05-28T10:00:00.000Z');
    });

    test('treats missing phone as null and missing profileImage as empty', () {
      final user = User.fromJson(<String, dynamic>{
        '_id': 'x',
        'name': 'Bob',
        'email': 'b@x.com',
        'isActive': true,
        'isEmailVerified': false,
        'createdAt': '2026-05-28T10:00:00.000Z',
        'updatedAt': '2026-05-28T10:00:00.000Z',
      });
      expect(user.phone, isNull);
      expect(user.profileImage, '');
    });

    test('ignores unknown / role-specific extra fields', () {
      final user = User.fromJson(<String, dynamic>{
        '_id': 'x',
        'name': 'Vikram',
        'email': 'v@x.com',
        'isActive': true,
        'isEmailVerified': false,
        'createdAt': '2026-05-28T10:00:00.000Z',
        'updatedAt': '2026-05-28T10:00:00.000Z',
        // Teacher-specific extras the backend includes — must not blow up.
        'bio': 'Math tutor',
        'subjects': <String>['Maths', 'Physics'],
        'feesRange': <String, dynamic>{'min': 500, 'max': 1000},
      });
      expect(user.id, 'x');
    });
  });

  group('User.toJson', () {
    test('round-trips via fromJson with id (not _id)', () {
      final original = User(
        id: 'abc',
        name: 'Alice',
        email: 'a@x.com',
        phone: '+1',
        profileImage: 'http://img/a.png',
        isActive: true,
        isEmailVerified: true,
        createdAt: DateTime.utc(2026, 5, 28, 10),
        updatedAt: DateTime.utc(2026, 5, 28, 11),
      );
      final json = original.toJson();
      expect(json['id'], 'abc');
      expect(json['name'], 'Alice');
      expect(json['email'], 'a@x.com');
      expect(json['phone'], '+1');
      expect(json['profileImage'], 'http://img/a.png');
      expect(json['isActive'], true);
      expect(json['isEmailVerified'], true);
      expect(json['createdAt'], '2026-05-28T10:00:00.000Z');
      expect(json['updatedAt'], '2026-05-28T11:00:00.000Z');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/data/models/user_model_test.dart`

Expected: compile error (`User` not defined) or test failures — there's no real `User` implementation yet, only the stub.

- [ ] **Step 3: Implement `User`**

Replace `lib/features/auth/data/models/user_model.dart` contents with:

```dart
/// Authenticated user model — backend payload and Hive cache.
library;

/// The common fields the backend always returns on `auth/register` and
/// `auth/login`. Role-specific extras (teacher's `bio`, student's
/// `currentClass`, etc.) live in dedicated profile models loaded via
/// `/api/{role}/me` and are not part of the auth flow.
///
/// `id` corresponds to the backend's MongoDB `_id` string.
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

  /// Mongo ObjectId string — maps from backend `_id`.
  final String id;

  /// Display name (full name, single string).
  final String name;

  /// Lower-cased email address (the backend normalises before storing).
  final String email;

  /// Optional phone number; null when the user didn't provide one.
  final String? phone;

  /// Profile image URL. Empty string when not set.
  final String profileImage;

  /// Account active flag — set false by admin moderation.
  final bool isActive;

  /// Email verification flag — informational only at this phase.
  final bool isEmailVerified;

  /// Timestamp the user record was created on the backend.
  final DateTime createdAt;

  /// Timestamp the user record was last updated on the backend.
  final DateTime updatedAt;

  /// Parses the backend's `user` JSON envelope. Maps `_id` to [id], tolerates
  /// extra (role-specific) fields by ignoring them.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImage: (json['profileImage'] as String?) ?? '',
      isActive: json['isActive'] as bool,
      isEmailVerified: json['isEmailVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Serialises to the shape stored in Hive (under `keyCurrentUser`). Uses
  /// `id` (not `_id`) because the value never round-trips to the backend —
  /// the server is the source of truth and re-sends `_id` on the next
  /// `/auth/me` call.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'profileImage': profileImage,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Parses a Hive-cached `User` JSON map (`id`, not `_id`).
  factory User.fromCache(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImage: (json['profileImage'] as String?) ?? '',
      isActive: json['isActive'] as bool,
      isEmailVerified: json['isEmailVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/auth/data/models/user_model_test.dart`

Expected: all 4 tests pass.

- [ ] **Step 5: Verify analyze clean**

```bash
dart format lib/features/auth/data/models/user_model.dart test/features/auth/data/models/user_model_test.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/data/models/user_model.dart test/features/auth/data/models/user_model_test.dart
git commit -m "feat(auth): User model with fromJson/toJson + tests

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: `AuthResponse` model + tests

**Files:**
- Modify: `lib/features/auth/data/models/auth_response_model.dart`
- Create: `test/features/auth/data/models/auth_response_model_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/auth/data/models/auth_response_model_test.dart`:

```dart
import 'package:coaching_app/features/auth/data/models/auth_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthResponse.fromJson parses token / refreshToken / user', () {
    final response = AuthResponse.fromJson(<String, dynamic>{
      'success': true,
      'accessToken': 'access.jwt.value',
      'refreshToken': 'refresh.jwt.value',
      'user': <String, dynamic>{
        '_id': 'u1',
        'name': 'Alice',
        'email': 'a@x.com',
        'phone': null,
        'profileImage': '',
        'isActive': true,
        'isEmailVerified': false,
        'createdAt': '2026-05-28T10:00:00.000Z',
        'updatedAt': '2026-05-28T10:00:00.000Z',
      },
    });
    expect(response.accessToken, 'access.jwt.value');
    expect(response.refreshToken, 'refresh.jwt.value');
    expect(response.user.id, 'u1');
    expect(response.user.email, 'a@x.com');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/data/models/auth_response_model_test.dart`

Expected: compile error / failure (no real `AuthResponse` yet).

- [ ] **Step 3: Implement `AuthResponse`**

Replace `lib/features/auth/data/models/auth_response_model.dart` contents with:

```dart
/// Server response envelope for the login and register endpoints.
library;

import 'user_model.dart';

/// The `{success, accessToken, refreshToken, user}` envelope returned by
/// `POST /api/auth/register` and `POST /api/auth/login` (status 201 / 200).
/// Parse-only: the client never serialises this back to the server. The
/// `success` flag is informational — we read the tokens / user directly.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  /// Short-lived access JWT (default 15-min lifetime on the backend).
  /// Sent on subsequent requests as `Authorization: Bearer <accessToken>`.
  final String accessToken;

  /// Long-lived refresh JWT (default 7-day lifetime). Persisted for the
  /// mobile client; the same value is also set as an `HttpOnly` cookie for
  /// browser clients (we don't rely on the cookie path).
  final String refreshToken;

  /// The newly created (or just-authenticated) user.
  final User user;

  /// Parses the backend response body.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/auth/data/models/auth_response_model_test.dart`

Expected: test passes.

- [ ] **Step 5: Verify analyze clean**

```bash
dart format lib/features/auth/data/models/auth_response_model.dart test/features/auth/data/models/auth_response_model_test.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/data/models/auth_response_model.dart test/features/auth/data/models/auth_response_model_test.dart
git commit -m "feat(auth): AuthResponse parser + test

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: `RegisterRequest` model + tests

**Files:**
- Create: `lib/features/auth/data/models/register_request_model.dart`
- Create: `test/features/auth/data/models/register_request_model_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/auth/data/models/register_request_model_test.dart`:

```dart
import 'package:coaching_app/features/auth/data/models/register_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegisterRequest.toJson', () {
    test('serialises required fields and omits null phone', () {
      const request = RegisterRequest(
        userType: 'owner',
        name: 'Alice',
        email: 'alice@x.com',
        password: 'secret123',
      );
      expect(request.toJson(), <String, dynamic>{
        'userType': 'owner',
        'name': 'Alice',
        'email': 'alice@x.com',
        'password': 'secret123',
      });
    });

    test('includes phone when non-empty', () {
      const request = RegisterRequest(
        userType: 'student',
        name: 'Bob',
        email: 'b@x.com',
        password: 'p1234567',
        phone: '+1234',
      );
      expect(request.toJson()['phone'], '+1234');
    });

    test('omits phone when empty string', () {
      const request = RegisterRequest(
        userType: 'teacher',
        name: 'Cara',
        email: 'c@x.com',
        password: 'p1234567',
        phone: '',
      );
      expect(request.toJson().containsKey('phone'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/data/models/register_request_model_test.dart`

Expected: compile error (file doesn't exist).

- [ ] **Step 3: Create the file**

Create `lib/features/auth/data/models/register_request_model.dart`:

```dart
/// Request body for `POST /api/auth/register`.
library;

/// Serialises the form's fields into the JSON shape the backend expects.
/// `userType` is one of `'student'`, `'owner'`, `'teacher'` (matches the
/// project's role constants in `core/providers/role_provider.dart`).
class RegisterRequest {
  const RegisterRequest({
    required this.userType,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  /// One of `'student'`, `'owner'`, `'teacher'`. The backend rejects
  /// `'admin'` with a 400.
  final String userType;

  /// Full name (single string). Caller is responsible for trimming /
  /// concatenating first + last name where applicable.
  final String name;

  /// Lower-cased email. Caller trims + lowercases before constructing.
  final String email;

  /// Plaintext password — the backend bcrypt-hashes before storage.
  final String password;

  /// Optional phone. Omitted from JSON entirely when null or empty.
  final String? phone;

  /// Backend-shaped JSON body.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userType': userType,
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
    };
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/auth/data/models/register_request_model_test.dart`

Expected: all 3 tests pass.

- [ ] **Step 5: Verify analyze clean**

```bash
dart format lib/features/auth/data/models/register_request_model.dart test/features/auth/data/models/register_request_model_test.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/data/models/register_request_model.dart test/features/auth/data/models/register_request_model_test.dart
git commit -m "feat(auth): RegisterRequest with phone-omit toJson + tests

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Sealed `AuthState`

**Files:**
- Create: `lib/features/auth/data/models/auth_state.dart`

- [ ] **Step 1: Create the file**

```dart
/// Sealed states the AuthNotifier emits.
library;

import 'user_model.dart';

/// The auth state the [AuthNotifier] holds and the [RegisterScreen] /
/// [LoginScreen] react to. Sealed so call-sites get exhaustive pattern
/// matching.
sealed class AuthState {
  const AuthState();
}

/// No session, no in-flight operation — the form is idle.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A signup (or future login) request is in flight; the form should disable
/// inputs and show a spinner on the primary CTA.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A valid session is in memory: [user] and [role] are present. The shell
/// router should let the user past `/auth/*` redirects.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, required this.role});

  /// The authenticated user (loaded from the auth response or the Hive
  /// cache).
  final User user;

  /// `'student'` / `'owner'` / `'teacher'` — what shell to route into.
  final String role;
}

/// Explicit signed-out state. Distinct from [AuthInitial]: the user has been
/// authenticated before in this session and then signed out, or
/// [AuthInterceptor] cleared the session on 401.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// The most recent auth operation failed. [message] is safe to surface in a
/// SnackBar (it's already the backend's user-friendly `message` field, or a
/// generic network-error string).
class AuthError extends AuthState {
  const AuthError(this.message);

  /// Human-readable failure message.
  final String message;
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/data/models/auth_state.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/models/auth_state.dart
git commit -m "feat(auth): sealed AuthState (Initial/Loading/Authenticated/Unauthenticated/Error)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: `AuthRemoteDataSource` (interface + impl)

**Files:**
- Modify: `lib/features/auth/data/repository/auth_remote_datasource.dart`

- [ ] **Step 1: Replace the stub with the full file**

```dart
/// Dio calls for login, register, and refresh endpoints.
library;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/app_exception.dart';
import '../models/auth_response_model.dart';
import '../models/register_request_model.dart';

/// Contract for the backend-talking layer of the auth feature. Implementations
/// throw [AppException] subclasses; the repository catches and maps to
/// [AppFailure].
abstract interface class AuthRemoteDataSource {
  /// Calls `POST /api/auth/register`. Returns the parsed [AuthResponse] on
  /// 201; throws [ServerException] on a 4xx/5xx response or
  /// [NetworkException] on connectivity / timeout.
  Future<AuthResponse> register(RegisterRequest request);
}

/// Dio-backed implementation.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  /// Wraps the provided [Dio] instance — typically the singleton from
  /// `dioProvider`.
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        data: request.toJson(),
      );
      final Map<String, dynamic>? body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from server');
      }
      return AuthResponse.fromJson(body);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      throw ServerException('Unexpected response shape', cause: e);
    } on TypeError catch (e) {
      throw ServerException('Unexpected response shape', cause: e);
    }
  }
}

/// Translates a [DioException] into the project's [AppException] hierarchy.
///
/// - Connection / timeout / DNS → [NetworkException].
/// - 4xx with a `{message: ...}` body → [ServerException] carrying that
///   message verbatim (the backend's messages are user-actionable).
/// - 5xx → [ServerException] with a generic message (we don't surface raw
///   500s to users — they may leak internals).
/// - Anything else → [ServerException] with a generic message.
AppException _mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkException(
        'No connection. Check your internet and try again.',
        cause: e,
      );
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
    case DioExceptionType.badResponse:
      final int? status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        final String message =
            (e.response?.data is Map<String, dynamic> &&
                    (e.response!.data as Map<String, dynamic>)['message']
                        is String)
                ? (e.response!.data as Map<String, dynamic>)['message']
                    as String
                : 'Request failed';
        return ServerException(message, statusCode: status, cause: e);
      }
      if (status != null && status >= 500) {
        return ServerException(
          'Something went wrong, please try again.',
          statusCode: status,
          cause: e,
        );
      }
      return ServerException('Unexpected error', cause: e);
  }
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/data/repository/auth_remote_datasource.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/repository/auth_remote_datasource.dart
git commit -m "feat(auth): AuthRemoteDataSource with Dio register + error mapping

Translates DioException to AppException subclasses, extracts the backend's
user-friendly message from 4xx responses, generic-izes 5xx.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: `AuthLocalDataSource` (interface + impl)

**Files:**
- Modify: `lib/features/auth/data/repository/auth_local_datasource.dart`

- [ ] **Step 1: Replace the stub with the full file**

```dart
/// Hive reads and writes for the JWT token, refresh token, cached user, and
/// active role.
library;

import 'dart:convert';

import '../../../../core/constants/hive_keys.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/user_model.dart';

/// Tiny value class composing the four pieces of session state that move
/// together: the access JWT, refresh JWT, the user, and the role. Lives next
/// to the local data source because it's the natural unit of persistence.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.role,
  });

  /// Access JWT (sent as `Authorization: Bearer ...`).
  final String accessToken;

  /// Refresh JWT (used by future `/auth/refresh` rotations).
  final String refreshToken;

  /// The authenticated user.
  final User user;

  /// `'student'` / `'owner'` / `'teacher'`.
  final String role;
}

/// Contract for the local persistence layer of the auth feature.
abstract interface class AuthLocalDataSource {
  /// Persists [session] to Hive: token + refresh + user JSON to `boxAuth`,
  /// role to `boxSettings`.
  Future<void> saveSession(AuthSession session);

  /// Clears `keyJwtToken`, `keyRefreshToken`, and `keyCurrentUser` from
  /// `boxAuth`. The role is preserved so re-login lands on the same shell.
  Future<void> clearSession();

  /// Returns the cached session, or null when any of token / refresh / user
  /// / role are missing. Used by [AuthNotifier.build] to hydrate startup
  /// state without a `/me` round-trip.
  AuthSession? readSession();
}

/// `HiveService`-backed implementation.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._hive);

  final HiveService _hive;

  @override
  Future<void> saveSession(AuthSession session) async {
    await _hive.authBox.put(HiveKeys.keyJwtToken, session.accessToken);
    await _hive.authBox.put(HiveKeys.keyRefreshToken, session.refreshToken);
    await _hive.authBox.put(
      HiveKeys.keyCurrentUser,
      jsonEncode(session.user.toJson()),
    );
    await _hive.settingsBox.put(HiveKeys.keyUserRole, session.role);
  }

  @override
  Future<void> clearSession() async {
    await _hive.authBox.delete(HiveKeys.keyJwtToken);
    await _hive.authBox.delete(HiveKeys.keyRefreshToken);
    await _hive.authBox.delete(HiveKeys.keyCurrentUser);
  }

  @override
  AuthSession? readSession() {
    final String? token = _hive.authBox.get(HiveKeys.keyJwtToken) as String?;
    final String? refresh =
        _hive.authBox.get(HiveKeys.keyRefreshToken) as String?;
    final String? userRaw =
        _hive.authBox.get(HiveKeys.keyCurrentUser) as String?;
    final String? role =
        _hive.settingsBox.get(HiveKeys.keyUserRole) as String?;
    if (token == null ||
        refresh == null ||
        userRaw == null ||
        role == null ||
        token.isEmpty ||
        refresh.isEmpty ||
        userRaw.isEmpty ||
        role.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(userRaw) as Map<String, dynamic>;
      return AuthSession(
        accessToken: token,
        refreshToken: refresh,
        user: User.fromCache(decoded),
        role: role,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/data/repository/auth_local_datasource.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/repository/auth_local_datasource.dart
git commit -m "feat(auth): AuthLocalDataSource + AuthSession over HiveService

Persists token + refresh + user JSON + role across boxAuth/boxSettings;
readSession returns null if any field is missing or the user JSON is
malformed; clearSession preserves the role so re-login keeps the shell.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: `AuthRepository` contract

**Files:**
- Modify: `lib/features/auth/data/repository/auth_repository.dart`

- [ ] **Step 1: Replace the stub with the full file**

```dart
/// Abstract contract for auth operations consumed by controllers.
library;

import '../../../../core/error/result.dart';
import 'auth_local_datasource.dart';

/// Auth operations the controller layer consumes. The implementation catches
/// data-source [AppException]s and returns them as
/// `Err(AppFailure)` values via [Result] (per the project convention —
/// failures are values, never thrown).
abstract interface class AuthRepository {
  /// Sends `POST /api/auth/register` and persists the returned session on
  /// success. Returns `Ok(session)` or `Err(failure)` with a user-safe
  /// message.
  Future<Result<AuthSession>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  });

  /// Returns the cached session from Hive, or null when none is present.
  /// Used by [AuthNotifier.build] to hydrate startup state.
  AuthSession? cachedSession();

  /// Clears the local session (token + refresh + user). Role is preserved.
  Future<void> signOut();
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/data/repository/auth_repository.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/repository/auth_repository.dart
git commit -m "feat(auth): AuthRepository contract returning Result<AuthSession>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: `AuthRepositoryImpl`

**Files:**
- Modify: `lib/features/auth/data/repository/auth_repository_impl.dart`

- [ ] **Step 1: Replace the stub with the full file**

```dart
/// Concrete AuthRepository composing remote and local data sources.
library;

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../models/register_request_model.dart';
import 'auth_local_datasource.dart';
import 'auth_remote_datasource.dart';
import 'auth_repository.dart';

/// Coordinates [AuthRemoteDataSource] (network) and [AuthLocalDataSource]
/// (Hive cache). Maps thrown [AppException]s to [AppFailure]s and returns
/// them as `Err`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Result<AuthSession>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  }) async {
    final String trimmedName =
        '${firstName.trim()} ${lastName.trim()}'.trim();
    final RegisterRequest request = RegisterRequest(
      userType: role,
      name: trimmedName,
      email: email.trim().toLowerCase(),
      password: password,
    );
    try {
      final response = await _remote.register(request);
      final session = AuthSession(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        user: response.user,
        role: role,
      );
      await _local.saveSession(session);
      return Ok<AuthSession>(session);
    } on ServerException catch (e) {
      return Err<AuthSession>(
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Err<AuthSession>(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Err<AuthSession>(ServerFailure(e.message));
    }
  }

  @override
  AuthSession? cachedSession() => _local.readSession();

  @override
  Future<void> signOut() => _local.clearSession();
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/data/repository/auth_repository_impl.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/repository/auth_repository_impl.dart
git commit -m "feat(auth): AuthRepositoryImpl maps exceptions to failures, saves session

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: `AuthNotifier` + providers

**Files:**
- Modify: `lib/features/auth/data/controllers/auth_provider.dart`

- [ ] **Step 1: Replace the stub with the full file**

```dart
/// AuthNotifier and authProvider holding the current auth state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/storage/hive_service_provider.dart';
import '../models/auth_state.dart';
import '../repository/auth_local_datasource.dart';
import '../repository/auth_remote_datasource.dart';
import '../repository/auth_repository.dart';
import '../repository/auth_repository_impl.dart';

/// Composes `dioProvider` + `hiveServiceProvider` into the concrete
/// [AuthRepository].
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final hive = ref.watch(hiveServiceProvider);
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSourceImpl(dio),
    local: AuthLocalDataSourceImpl(hive),
  );
});

/// The active auth state — consumed by the auth screens and the router.
final NotifierProvider<AuthNotifier, AuthState> authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Holds the [AuthState] and exposes the signup mutation. `build` hydrates
/// from the Hive cache so a re-launched app skips onboarding/auth when a
/// valid session is on disk; the access token's validity is not checked
/// here — `AuthInterceptor` clears the session on a subsequent 401.
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    final cached = _repo.cachedSession();
    if (cached != null) {
      // Seed the role provider so the router can route past auth without an
      // onboarding hop.
      ref.read(roleProvider.notifier).state = cached.role;
      return AuthAuthenticated(user: cached.user, role: cached.role);
    }
    return const AuthInitial();
  }

  /// Calls the repository and updates [state]:
  ///   - `AuthLoading` while the request is in flight
  ///   - `AuthAuthenticated(user, role)` on success (also seeds [roleProvider])
  ///   - `AuthError(message)` on failure
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AuthLoading();
    final result = await _repo.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      role: role,
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

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/data/controllers/auth_provider.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/controllers/auth_provider.dart
git commit -m "feat(auth): AuthNotifier (build hydrates from cache, register mutation)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: `AuthPrimaryButton` gains `isLoading`

**Files:**
- Modify: `lib/features/auth/presentation/widgets/auth_widgets.dart`

- [ ] **Step 1: Replace the `AuthPrimaryButton` class only** (other classes in the file stay unchanged)

Find this section in `lib/features/auth/presentation/widgets/auth_widgets.dart`:

```dart
/// Full-width filled primary CTA with an optional trailing icon, styled as a
/// neo primary button on the brand fill. [accent] selects the fill color so
/// the CTA inherits the active user role's brand; defaults to the student blue.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.accent,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? trailingIcon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return NeoButton(
      onPressed: onPressed,
      filled: true,
      accent: accent ?? AppColors.studentPrimary,
      height: 52,
      radius: AppSpacing.sp12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.neutralWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailingIcon != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sp8),
            Icon(trailingIcon, size: 18, color: AppColors.neutralWhite),
          ],
        ],
      ),
    );
  }
}
```

Replace with:

```dart
/// Full-width filled primary CTA with an optional trailing icon, styled as a
/// neo primary button on the brand fill. [accent] selects the fill color so
/// the CTA inherits the active user role's brand; defaults to the student
/// blue. When [isLoading] is `true`, [onPressed] is ignored, the label is
/// replaced by a small white spinner, and the button greys out (because
/// `NeoButton` already disables on `onPressed: null`).
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.accent,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? trailingIcon;
  final Color? accent;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return NeoButton(
      onPressed: isLoading ? null : onPressed,
      filled: true,
      accent: accent ?? AppColors.studentPrimary,
      height: 52,
      radius: AppSpacing.sp12,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.neutralWhite,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.neutralWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (trailingIcon != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sp8),
                  Icon(trailingIcon, size: 18, color: AppColors.neutralWhite),
                ],
              ],
            ),
    );
  }
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart format lib/features/auth/presentation/widgets/auth_widgets.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/widgets/auth_widgets.dart
git commit -m "feat(auth): AuthPrimaryButton.isLoading swaps label for white spinner

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 13: Wire `RegisterScreen` to `authProvider`

**Files:**
- Modify: `lib/features/auth/presentation/screens/register_screen.dart`

- [ ] **Step 1: Replace the file contents**

```dart
/// Sign Up screen — calls authProvider.register and reacts to AuthState.
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
import '../../data/controllers/auth_provider.dart';
import '../../data/models/auth_state.dart';
import '../auth_role_accents.dart';
import '../auth_validators.dart';
import '../widgets/auth_field_widget.dart';
import '../widgets/auth_widgets.dart';

/// Sign Up screen.
///
/// The form validates on submit (required names, email format, 8-char password,
/// matching confirmation). On valid submit, it calls
/// `ref.read(authProvider.notifier).register(...)` and reacts to [AuthState]
/// transitions via `ref.listen`:
///
///  - `AuthAuthenticated` → route to the role's landing screen.
///  - `AuthError` → SnackBar with the failure message verbatim.
///
/// `AuthLoading` greys out the Sign Up button and swaps its label for a
/// spinner. The CTA, focused input ring, and footer link all adopt the
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
    final AuthState authState = ref.watch(authProvider);
    final bool isLoading = authState is AuthLoading;

    void stub(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    // React to state transitions for navigation + error UX.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!context.mounted) return;
      if (next is AuthAuthenticated) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.goNamed(landingRouteForRole(next.role));
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    Future<void> onCreateAccount() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final String resolvedRole =
          ref.read(roleProvider) ?? initialRole ?? roleStudent;
      await ref.read(authProvider.notifier).register(
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
git commit -m "feat(auth): wire RegisterScreen to authProvider.register

Drops the kDebugMode JWT shortcut. Submits the form via the controller;
ref.listen flips a SnackBar on AuthError and goNamed on AuthAuthenticated.
The Sign Up button shows a spinner during AuthLoading.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 14: Add ADR 0029

**Files:**
- Create: `decisions/0029-auth-data-layer-and-signup-wiring.md`

- [ ] **Step 1: Create the file**

```markdown
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
exposes `POST /api/auth/register` returning `{token, refreshToken, user}`.

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
  - `AuthResponse` — `{token, refreshToken, user}` parse-only.
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
```

- [ ] **Step 2: Commit**

```bash
git add decisions/0029-auth-data-layer-and-signup-wiring.md
git commit -m "docs(adr): record 0029 — auth data layer + signup wiring

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 15: Final verification

**Files:**
- None modified — verification only.

- [ ] **Step 1: Format clean**

```bash
dart format lib test
```

Expected: no files changed (everything formatted by individual tasks).

- [ ] **Step 2: Analyze clean**

```bash
flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: All tests pass**

```bash
flutter test
```

Expected: all tests pass — existing `test/adaptive_navigation_tooltip_test.dart` plus the three new model tests.

- [ ] **Step 4: Debug APK builds**

```bash
flutter build apk --debug
```

Expected: build completes without errors.

- [ ] **Step 5: Manual signup walkthrough**

The user starts the backend separately (`cd ../server && npm run dev` per its README — must be reachable at `http://10.0.2.2:5000/api` from the Android emulator).

Then:
1. Launch the app on the Android emulator.
2. Pick a role on onboarding (try **Coaching Owner** first to verify the orange accent).
3. Tap "Sign up" link from login → fill the register form with a fresh email + password ≥ 6 chars → tap "Sign Up".
4. Expect: button shows a white spinner for a moment, then the app routes to the owner dashboard.
5. Verify Hive (e.g. via `adb shell` / app inspector): `boxAuth` contains `jwt_token`, `refresh_token`, `current_user`; `boxSettings.user_role = 'owner'`.
6. Sign-out manually (Owner Profile → Sign out, if implemented; otherwise uninstall + reinstall) and re-attempt the same email → expect SnackBar **"Email already registered as owner"** and no navigation.
7. Kill the backend (`Ctrl+C` on the server) and try a third signup → expect SnackBar **"No connection. Check your internet and try again."**.
8. Re-pick role (student / teacher) on onboarding → confirm CTA + focused input ring + footer link all use the role's accent (blue / teal).

If on-device behaviour deviates, capture the SnackBar text + the Dio log (the AuthInterceptor doesn't log; if needed, temporarily wrap the dio call in `print(response.data)` and remove before commit).

- [ ] **Step 6: No final commit needed** — bookkeeping commits in Tasks 1–14 already cover the round.

---

## Self-review notes (post-write)

- **Spec coverage:** §4.1 → Task 1; §4.2 (User) → Task 3; §4.2 (AuthResponse) → Task 4; §4.2 (RegisterRequest) → Task 5; §4.2 (AuthState) → Task 6; §4.3 (AuthSession) → embedded in Task 8 (lives next to the local data source); §4.4 (remote) → Task 7; §4.4 (local) → Task 8; §4.5 → Tasks 9 + 10; §4.6 → Task 11; §4.7 → Tasks 12 + 13; §6 (error mapping) → embedded in Task 7's Dio mapper; §7 (Hive shape) → embedded in Task 8's `saveSession`; bookkeeping → Task 14; verification → Task 15. No gaps.
- **Placeholder scan:** no `TODO` / `TBD` / "implement later" in any step. Every code-changing step shows the exact code; every command step shows the exact command + expected output.
- **Type consistency:** `AuthSession` is referenced before its definition by Task 9's `AuthRepository` contract; the actual definition lands in Task 8 alongside the local data source. Task 8 runs before Task 9, so by the time `auth_repository.dart` is compiled, `AuthSession` already exists. `Result<AuthSession>` / `Ok<AuthSession>` / `Err<AuthSession>` are used consistently in Tasks 9 + 10 + 11. `User.fromCache` (used in Task 8) is defined in Task 3.
- **Known fragility:** Manual verification depends on the backend running on `10.0.2.2:5000` (Android emulator's host-loopback). iOS simulator + physical device URL switching is out of scope per decision 0002.
