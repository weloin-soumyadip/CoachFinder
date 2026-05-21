/// Generic `ApiResponse<T>` wrapper around backend JSON envelopes.
library;

/// Generic envelope around the backend's standard response shape:
///
/// ```json
/// { "success": true, "data": <T>, "message": "..." }
/// ```
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  final bool success;
  final T? data;
  final String? message;

  /// Decode a backend envelope. `fromJsonT` decodes the `data` field.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
    );
  }
}
