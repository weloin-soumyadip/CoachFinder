/// Server response envelope for the login and register endpoints.
library;

import 'user_model.dart';

/// The `{success, accessToken, refreshToken, user}` envelope returned by
/// `POST /api/auth/register` and `POST /api/auth/login` (status 201 / 200).
/// Parse-only: the client never serialises this back to the server. The
/// `success` flag is informational — we read the tokens / user directly.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  /// Short-lived access JWT (default 15-min lifetime on the backend).
  /// Sent on subsequent requests as `Authorization: Bearer <accessToken>`.
  final String accessToken;

  /// Long-lived refresh JWT (default 7-day lifetime). Persisted for the
  /// mobile client; the same value is also set as an `HttpOnly` cookie for
  /// browser clients (we don't rely on the cookie path).
  final String refreshToken;

  /// The newly created (or just-authenticated) user.
  final User user;

  /// Parses the backend response body.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
