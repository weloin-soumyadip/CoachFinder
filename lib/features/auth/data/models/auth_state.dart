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
