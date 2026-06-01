/// Server response envelope for `GET /api/auth/me`.
library;

import 'user_model.dart';

/// The `{success, userType, user}` envelope returned by `GET /api/auth/me`
/// (status 200). Used by the auth controller's launch-time rehydration to
/// validate the cached access token and refresh the in-memory [User] +
/// `roleProvider` from the server.
///
/// Parse-only: never serialised back to the server.
class MeResponse {
  const MeResponse({required this.userType, required this.user});

  /// One of `'owner'`, `'teacher'`, `'student'`, or `'admin'` — the
  /// authoritative role for this session. The client mirrors this into
  /// `roleProvider` so the router lands the user in the right shell.
  final String userType;

  /// The currently authenticated user as returned by `/auth/me`. Same
  /// `sanitize`d shape as the user returned from login / register.
  final User user;

  /// Parses the backend response body.
  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      userType: json['userType'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
