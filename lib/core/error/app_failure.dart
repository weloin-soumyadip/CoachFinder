/// Failure types surfaced to controllers.
library;

/// Failure surfaced from the repository layer up to controllers.
///
/// Distinct from [AppException]: failures are values (never thrown) and carry
/// only the information the UI layer needs.
sealed class AppFailure {
  const AppFailure(this.message);

  /// Human-readable message safe to surface in the UI.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// HTTP response from the backend indicating server-side rejection.
class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {this.statusCode});

  /// HTTP status code, when known.
  final int? statusCode;
}

/// Connectivity, timeout, or DNS issue - typically retryable.
class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

/// Authentication failure - typically forces a sign-out / re-login flow.
class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

/// Local cache read/write failure - usually safe to continue without the cache.
class CacheFailure extends AppFailure {
  const CacheFailure(super.message);
}
