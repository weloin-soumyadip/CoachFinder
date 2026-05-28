# Auth Login API Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire `POST /api/auth/login` into the Flutter app — mirror the existing signup flow on top of round 2's `AuthRepository` / `AuthController` / `ApiClient` / `TokenStorage` infrastructure. Drop the `kDebugMode` test-credential shortcut, the "Remember for 30 days" toggle, and align the password validator with the backend's min 6.

**Architecture:** Add a `LoginRequest` model + 3 tests, an `AuthRepository.login` method, an `AuthController.signIn` method, a `LoginScreen` rewrite, and a small cleanup pass. Behaviour mirrors signup: form validates → controller calls repo → tokens persisted to `TokenStorage`, role + userId to `LocalStorage` → state flips through Loading → Authenticated / Error → screen reacts via `ref.listen`.

**Tech Stack:** Flutter + Dart 3, Dio (via the existing `ApiClient`), `flutter_secure_storage` (via `TokenStorage`), `flutter_riverpod` (`StateNotifierProvider`). No new dependencies.

**Source spec:** `docs/superpowers/specs/2026-05-28-auth-login-wiring-design.md`
**Backend contract:** `/home/weloin/Projects/practice/Claude-practice/coaching-app/server/api.md` § `POST /api/auth/login`

---

## File structure

**New files:**
- `lib/features/auth/data/models/login_request_model.dart`
- `test/features/auth/data/models/login_request_model_test.dart`
- `decisions/0031-auth-login-wiring.md`

**Modified files:**
- `lib/features/auth/presentation/auth_validators.dart` — password min 8 → 6.
- `lib/core/constants/app_strings.dart` — update `validatorPasswordShort` message; delete four unused constants in the cleanup task.
- `lib/features/auth/data/repositories/auth_repository.dart` — add `login()` method + import.
- `lib/features/auth/data/providers/auth_providers.dart` — add `signIn()` method + import.
- `lib/features/auth/presentation/screens/login_screen.dart` — full rewrite (drop `kDebugMode` block, `_RememberToggle`, `_DebugCredentialHint`; wire `authControllerProvider`).

**Deleted:**
- `lib/core/constants/dev_credentials.dart` (after grep-confirmed zero consumers).

**Conventions reminder:**
- Project package name: `coachfinder`.
- `///` doc comments on every class + public method.
- Every task ends with `flutter analyze` clean + a commit.

---

## Task 1: `LoginRequest` model + tests (TDD)

**Files:**
- Create: `test/features/auth/data/models/login_request_model_test.dart`
- Create: `lib/features/auth/data/models/login_request_model.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/auth/data/models/login_request_model_test.dart`:

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

- [ ] **Step 2: Run the test — confirm it fails**

```bash
flutter test test/features/auth/data/models/login_request_model_test.dart
```

Expected: compile error / `LoginRequest` not defined.

- [ ] **Step 3: Create the model**

Create `lib/features/auth/data/models/login_request_model.dart`:

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

- [ ] **Step 4: Run the test — confirm it passes**

```bash
flutter test test/features/auth/data/models/login_request_model_test.dart
```

Expected: all 3 tests pass.

- [ ] **Step 5: Verify analyze clean + commit**

```bash
dart format lib/features/auth/data/models/login_request_model.dart test/features/auth/data/models/login_request_model_test.dart && flutter analyze
git add lib/features/auth/data/models/login_request_model.dart test/features/auth/data/models/login_request_model_test.dart
git commit -m "feat(auth): LoginRequest with toJson + tests

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

Expected analyze: *No issues found!*

---

## Task 2: Lower password validator min to 6

**Files:**
- Modify: `lib/features/auth/presentation/auth_validators.dart`
- Modify: `lib/core/constants/app_strings.dart` (the message)

- [ ] **Step 1: Update the validator's threshold**

Open `lib/features/auth/presentation/auth_validators.dart`. Find this method:

```dart
  /// Required + minimum length of 8 characters.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.validatorRequired;
    return value.length < 8 ? AppStrings.validatorPasswordShort : null;
  }
```

Replace with:

```dart
  /// Required + minimum length of 6 characters (matches backend register).
  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.validatorRequired;
    return value.length < 6 ? AppStrings.validatorPasswordShort : null;
  }
```

- [ ] **Step 2: Update the AppStrings message**

Open `lib/core/constants/app_strings.dart`. Find:

```dart
  static const String validatorPasswordShort =
      'Password must be at least 8 characters.';
```

Replace with:

```dart
  static const String validatorPasswordShort =
      'Password must be at least 6 characters.';
```

- [ ] **Step 3: Verify analyze clean**

```bash
dart format lib/features/auth/presentation/auth_validators.dart lib/core/constants/app_strings.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/presentation/auth_validators.dart lib/core/constants/app_strings.dart
git commit -m "fix(auth): lower password validator min 8 -> 6 to match backend

Backend /auth/register requires >= 6 chars; the client-side >= 8 was
rejecting otherwise-valid backend passwords on login. Aligns the two
endpoints' constraints.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: `AuthRepository.login` method

**Files:**
- Modify: `lib/features/auth/data/repositories/auth_repository.dart`

- [ ] **Step 1: Read the current file**

```bash
cat lib/features/auth/data/repositories/auth_repository.dart
```

Note the import block at the top and the existing `register()` method's exact shape — `login()` mirrors it.

- [ ] **Step 2: Add the LoginRequest import**

In the import block, add this line right after the existing `register_request_model` import (keep alphabetical):

Find:
```dart
import '../models/register_request_model.dart';
```

Insert directly above it:
```dart
import '../models/login_request_model.dart';
```

So the order becomes `login_request_model.dart` then `register_request_model.dart`.

- [ ] **Step 3: Add the `login` method**

Inside the `AuthRepository` class, directly after the existing `register` method's closing brace, insert this method:

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

Placement: between `register()` and the existing `isAuthenticated()`. The class continues with `isAuthenticated`, `getAccessToken`, `logout` unchanged.

- [ ] **Step 4: Verify analyze clean**

```bash
dart format lib/features/auth/data/repositories/auth_repository.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/repositories/auth_repository.dart
git commit -m "feat(auth): add AuthRepository.login

Calls POST /api/auth/login via ApiClient.rawPost, parses ApiResponse,
persists access + refresh tokens on success, throws AuthException on
failure. Mirror of the existing register method.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: `AuthController.signIn` method

**Files:**
- Modify: `lib/features/auth/data/providers/auth_providers.dart`

- [ ] **Step 1: Add the LoginRequest import**

In the import block, find:
```dart
import '../models/register_request_model.dart';
```

Insert directly above it:
```dart
import '../models/login_request_model.dart';
```

- [ ] **Step 2: Add the `signIn` method**

Inside the `AuthController` class, directly after the closing brace of the existing `register()` method (and before `logout()`), insert:

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

- [ ] **Step 3: Verify analyze clean**

```bash
dart format lib/features/auth/data/providers/auth_providers.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/data/providers/auth_providers.dart
git commit -m "feat(auth): add AuthController.signIn

Loading -> Authenticated|Error pipeline via repository.login, persists
role + currentUserId to LocalStorage, updates roleProvider. Mirror of the
existing register method.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: `LoginScreen` rewrite

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`

- [ ] **Step 1: Replace the file contents entirely**

```dart
/// Sign In screen — calls authController.signIn and reacts to AuthState.
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

/// Sign In screen.
///
/// The form validates on submit (email format + min 6-char password). On
/// valid submit, it calls
/// `ref.read(authControllerProvider.notifier).signIn(...)` and reacts to
/// [AuthState] transitions via `ref.listen`:
///
///  - `AuthStatus.authenticated` → route to the role's landing screen.
///  - `AuthStatus.error` → SnackBar with the failure message verbatim.
///
/// `AuthStatus.loading` greys out the Sign In button and swaps its label for
/// a spinner. The CTA, focused input ring, footer link, and "Forgot
/// password?" link all adopt the active role's accent.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final passwordVisible = useState(false);
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
                        AppStrings.loginTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp4),
                      Text(
                        AppStrings.loginSubtitle,
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
                              textInputAction: TextInputAction.done,
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => context
                                    .pushNamed(AppRoutes.forgotPassword),
                                child: Text(
                                  AppStrings.forgotPassword,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            AuthPrimaryButton(
                              label: AppStrings.signIn,
                              accent: accent,
                              isLoading: isLoading,
                              onPressed: handleSignIn,
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
                                icon: Icons.g_mobiledata_outlined,
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
                        prefix: AppStrings.dontHaveAccount,
                        actionLabel: AppStrings.signUp,
                        accent: accent,
                        onAction: () => context.goNamed(
                          AppRoutes.register,
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
dart format lib/features/auth/presentation/screens/login_screen.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/login_screen.dart
git commit -m "feat(auth): wire LoginScreen to authControllerProvider.signIn

Drops the kDebugMode test-credential shortcut + _RememberToggle +
_DebugCredentialHint. Form submit calls signIn; ref.listen drives
SnackBar on AuthError and goNamed on AuthAuthenticated. The Sign In
button shows a spinner during AuthLoading. The right-aligned 'Forgot
password?' link replaces the Remember/Forgot row.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Cleanup unused strings + delete `dev_credentials.dart`

**Files:**
- Modify: `lib/core/constants/app_strings.dart` (delete 4 constants)
- Delete: `lib/core/constants/dev_credentials.dart`

- [ ] **Step 1: Sanity check — confirm no remaining consumers**

```bash
grep -rn "loginInvalidCredentials\|stubAuthNotImplemented\|loginTestAccountLabel\|authRememberMe\|DevCredentials\|dev_credentials" lib/ test/ --include="*.dart" | grep -v "core/constants/dev_credentials\|core/constants/app_strings"
```

Expected: empty output. If any line shows up outside the two doomed files, STOP — there's a missed consumer.

- [ ] **Step 2: Delete the four `AppStrings` constants**

Open `lib/core/constants/app_strings.dart` and delete the line containing each of:
- `static const String loginInvalidCredentials = ...;`
- `static const String stubAuthNotImplemented = ...;` (this one spans two lines — delete both the declaration line and the continuation)
- `static const String loginTestAccountLabel = ...;`
- `static const String authRememberMe = ...;`

Use the exact lines from the file — surrounding context preserved.

- [ ] **Step 3: Delete `dev_credentials.dart`**

```bash
git rm lib/core/constants/dev_credentials.dart
```

- [ ] **Step 4: Verify analyze clean**

```bash
dart format lib/core/constants/app_strings.dart && flutter analyze
```

Expected: *No issues found!*

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/app_strings.dart
git commit -m "chore(auth): drop dev_credentials + 4 unused AppStrings

Now that LoginScreen uses real /auth/login (no kDebugMode shortcut), the
test-credential file + its supporting AppStrings (loginInvalidCredentials,
stubAuthNotImplemented, loginTestAccountLabel, authRememberMe) have no
consumers.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: ADR 0031

**Files:**
- Create: `decisions/0031-auth-login-wiring.md`

- [ ] **Step 1: Create the file**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add decisions/0031-auth-login-wiring.md
git commit -m "docs(adr): record 0031 — auth login wiring

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Final verification

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

Expected: 12 tests pass — 4 `user_model_test.dart` + 3 `register_request_model_test.dart` + **3 `login_request_model_test.dart`** + 1 `auth_response_model_test.dart` + 1 `adaptive_navigation_tooltip_test.dart`.

- [ ] **Step 4: Debug APK builds**

```bash
flutter build apk --debug
```

Expected: build completes without errors.

- [ ] **Step 5: Commit chain**

```bash
git log --oneline 8f4fca2..HEAD
```

`8f4fca2` was the spec commit; this should list the implementation commits (Tasks 1-7 = ~7 commits since).

- [ ] **Step 6: Manual sign-in walkthrough**

The user starts the backend separately (`cd ../server && npm run dev`).

1. Launch the app on the Android emulator (uninstall first if there's a stale session).
2. Pick a role on onboarding (e.g. **Coaching Owner**).
3. Tap "Sign up" → register with fresh email + password ≥ 6 chars → expect role's shell.
4. Owner Profile → Sign out → land on onboarding / login.
5. Pick same role → reach Login → type the just-registered email + password → expect role's shell.
6. Owner Profile → Sign out again → reach Login → type **wrong password** → expect SnackBar **"Invalid credentials"** and no navigation.
7. Kill the backend → try login again → expect SnackBar **"No connection. Check your internet and try again."**.
8. Try password "12345" (5 chars) → expect client-side validator block — "Password must be at least 6 characters.".

If on-device behaviour deviates, capture which step + the SnackBar text + the controller state value.

- [ ] **Step 7: No final commit needed** — bookkeeping commits in Tasks 1–7 already cover the round.

---

## Self-review notes (post-write)

**Spec coverage:** §4.1 (LoginRequest) → Task 1; §4.2 (tests) → Task 1; §4.3 (repository.login) → Task 3; §4.4 (controller.signIn) → Task 4; §4.5 (validator) → Task 2; §4.6 (LoginScreen rewrite) → Task 5; §4.7 (cleanup) → Task 6; §10 (verification) → Task 8; ADR → Task 7.

**Placeholder scan:** no `TODO` / `TBD` / "implement later" / "add appropriate" / "similar to". Every code-changing step shows the exact code; every command step shows the exact command + expected output.

**Type consistency:** `LoginRequest({userType, email, password})` is used the same way across Tasks 1, 3, 4. `AuthRepository.login(LoginRequest)` returns `Future<AuthResponse>` consistently. `AuthController.signIn({email, password, role})` parameter names + types match the call site in `LoginScreen` (Task 5). `AuthStatus.authenticated` / `.error` / `.loading` cases match the round-2 `auth_providers.dart` enum. `AppStrings.validatorPasswordShort` is referenced after its value is updated in Task 2 — Task 5's `AuthValidators.password` consumes the updated string.

**Sequencing fragility:** Task 5 (LoginScreen rewrite) depends on Tasks 3 + 4 (repository.login + controller.signIn) and Task 1 (LoginRequest). Task 6 cleanup runs after Task 5 — once the screen no longer references `loginInvalidCredentials` / `stubAuthNotImplemented` / `_RememberToggle` / `_DebugCredentialHint` / `DevCredentials`, the four AppStrings + the dev_credentials.dart file have zero consumers. The Step-1 grep in Task 6 is a hard sanity check before deletion.
