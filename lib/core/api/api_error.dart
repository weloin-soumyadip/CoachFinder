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
