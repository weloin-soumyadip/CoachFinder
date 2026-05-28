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
