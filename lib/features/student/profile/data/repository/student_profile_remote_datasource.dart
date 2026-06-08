/// Dio calls for the student profile read / update / password endpoints. Reads
/// the top-level `user` off the raw envelope (which the standard [ApiResponse]
/// helper would drop) — exactly like the bookmarks datasource reads `bookmark`.
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';
import '../models/student_profile_model.dart';
import '../models/student_profile_update.dart';

/// The fresh access / refresh token pair the backend re-issues after a
/// successful password change. Either may be null if the backend omits it, in
/// which case the repository skips persistence. A thin transport-level value;
/// not a domain model, so it stays beside the datasource that produces it.
class PasswordChangeTokens {
  /// Constructs the pair off the raw `{accessToken, refreshToken}` body.
  const PasswordChangeTokens({this.accessToken, this.refreshToken});

  /// The re-issued access token, or null when the body omitted it.
  final String? accessToken;

  /// The re-issued refresh token, or null when the body omitted it.
  final String? refreshToken;
}

/// Thin remote datasource for the student profile feature. Each method issues
/// exactly one call via [ApiClient]; no business logic — the repository owns
/// that. The interceptor attaches the bearer token (these are self endpoints).
class StudentProfileRemoteDataSource {
  StudentProfileRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/auth/me` — the prefill / read source. Replies
  /// `{success, userType, user}`; we read the top-level `user` (the full
  /// sanitized student doc).
  Future<StudentProfile> fetch() async {
    final response = await _apiClient.rawGet(ApiConfig.authMe);
    return _parseUser(response.data);
  }

  /// `PATCH /api/students/me` — strict partial update. Sends only the non-null
  /// keys from [update]; replies `{user: <full doc>}` at the top level.
  Future<StudentProfile> update(StudentProfileUpdate update) async {
    final response = await _apiClient.rawPatch(
      ApiConfig.studentsMe,
      data: update.toJson(),
    );
    return _parseUser(response.data);
  }

  /// `POST /api/students/me/password` — body `{currentPassword, newPassword}`.
  /// The backend revokes ALL of the user's refresh tokens server-side and
  /// re-issues a fresh pair, replying `{success, accessToken, refreshToken}` at
  /// the top level. Returns the new token pair (read off the raw body) so the
  /// repository can persist it and keep the session alive — the old tokens are
  /// now dead. A wrong current password surfaces as a thrown `ApiError`.
  Future<PasswordChangeTokens> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.rawPost(
      ApiConfig.studentsMePassword,
      data: <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    return PasswordChangeTokens(
      accessToken: body['accessToken'] as String?,
      refreshToken: body['refreshToken'] as String?,
    );
  }

  /// Extracts and parses the top-level `user` object from a raw response body.
  StudentProfile _parseUser(Map<String, dynamic>? body) {
    final Map<String, dynamic> map = body ?? <String, dynamic>{};
    final Map<String, dynamic> user =
        (map['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return StudentProfile.fromJson(user);
  }
}
