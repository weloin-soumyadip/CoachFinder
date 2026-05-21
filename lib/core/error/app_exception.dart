/// Exception types thrown by data sources.
library;

/// Base class for exceptions thrown by data sources. Repositories catch these
/// and map them to [AppFailure] subclasses for the controller layer.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Human-readable message safe to surface (or to log).
  final String message;

  /// Optional underlying cause (the original exception or status object).
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// HTTP error response from the backend (status >= 400).
class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode, super.cause});

  /// HTTP status code, when known.
  final int? statusCode;
}

/// Network-level failure (no connectivity, timeout, DNS).
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// Local Hive read/write or decoding failure.
class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

/// Authentication-specific failure (missing token, refresh failed, 401).
class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}
