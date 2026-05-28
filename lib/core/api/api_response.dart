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
