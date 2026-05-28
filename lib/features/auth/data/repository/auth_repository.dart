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
