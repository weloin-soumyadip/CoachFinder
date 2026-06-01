/// AuthState, AuthController (StateNotifier), and Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/login_request_model.dart';
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
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final request = RegisterRequest(
        userType: role,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        phone: phone.trim(),
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

  /// Launch-time rehydration. Validates the cached access token against
  /// `GET /api/auth/me`:
  ///
  ///   - **no cached `currentUserId`** → flip to `unauthenticated`. The
  ///     router keeps the user on onboarding / login as appropriate.
  ///   - **`/me` succeeds with a registerable role** → flip to
  ///     `authenticated` with the fresh [User] and mirror the server's
  ///     authoritative `userType` into [LocalStorage] + [roleProvider].
  ///     The user lands in the shell matching the role the server reports,
  ///     overriding any locally cached role if the two disagree.
  ///   - **`/me` returns `userType: 'admin'`** → the app has no admin
  ///     surface; treat as unauthenticated (clear session, drop to login).
  ///   - **`/me` returns 401** → token expired / revoked. The [ApiClient]
  ///     interceptor has already cleared the secure-storage tokens and
  ///     `currentUserId`; we then flip to `unauthenticated` so the next
  ///     navigation bounces to login.
  ///   - **any other failure (network, timeout)** → keep the cached
  ///     session intact (offline mode). Status drops back to `initial`
  ///     but the in-memory `user` / `role` (if any) are preserved via
  ///     `copyWith`. The next authenticated user action will surface the
  ///     real error.
  ///
  /// Fired once when [authControllerProvider] is first read; no callers
  /// need to invoke this directly.
  Future<void> bootstrap() async {
    final cachedUserId = LocalStorage.get<String>(StorageKeys.currentUserId);
    if (cachedUserId == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final me = await _repository.getCurrentUser();
      const Set<String> registerableRoles = <String>{
        roleStudent,
        roleOwner,
        roleTeacher,
      };
      if (!registerableRoles.contains(me.userType)) {
        // No app surface exists for admin / unknown roles. Drop the session.
        await _repository.logout();
        await LocalStorage.remove(StorageKeys.currentUserId);
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      await LocalStorage.set(StorageKeys.userRole, me.userType);
      await LocalStorage.set(StorageKeys.currentUserId, me.user.id);
      _ref.read(roleProvider.notifier).state = me.userType;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: me.user,
        role: me.userType,
      );
    } on AuthException catch (e) {
      if (e.code == '401') {
        await _repository.logout();
        await LocalStorage.remove(StorageKeys.currentUserId);
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        state = state.copyWith(status: AuthStatus.initial);
      }
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
/// and the router. The controller's [AuthController.bootstrap] fires once on
/// creation, so the first read of this provider kicks off the launch-time
/// `/me` rehydration in the background.
final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final controller = AuthController(repository, ref);
  // Fire-and-forget: validates the cached access token + refreshes the User
  // from /api/auth/me. Errors are handled inside `bootstrap` itself.
  controller.bootstrap();
  return controller;
});
