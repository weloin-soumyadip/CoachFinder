/// Dio calls for the owner profile read / update / password endpoints. Reads
/// the top-level `user` off the raw envelope (which the standard [ApiResponse]
/// helper would drop) — exactly like the student profile datasource.
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';
import '../models/owner_profile_model.dart';
import '../models/owner_profile_update.dart';

/// The fresh access / refresh token pair the backend re-issues after a
/// successful password change. Either may be null if the backend omits it.
class PasswordChangeTokens {
  /// Constructs the pair off the raw `{accessToken, refreshToken}` body.
  const PasswordChangeTokens({this.accessToken, this.refreshToken});

  /// The re-issued access token, or null when the body omitted it.
  final String? accessToken;

  /// The re-issued refresh token, or null when the body omitted it.
  final String? refreshToken;
}

/// Thin remote datasource for the owner profile feature. Each method issues
/// exactly one call via [ApiClient]; the interceptor attaches the bearer token.
class OwnerProfileRemoteDataSource {
  /// Wraps the shared [ApiClient].
  OwnerProfileRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/auth/me` — the prefill / read source. Replies
  /// `{success, userType, user}`; we read the top-level `user` (the sanitized
  /// owner doc).
  Future<OwnerProfile> fetch() async {
    final response = await _apiClient.rawGet(ApiConfig.authMe);
    return _parseUser(response.data);
  }

  /// `PATCH /api/owners/me` — strict partial update. Sends only the non-null
  /// keys from [update]; replies `{user: <full doc>}` at the top level.
  Future<OwnerProfile> update(OwnerProfileUpdate update) async {
    final response = await _apiClient.rawPatch(
      ApiConfig.ownersMe,
      data: update.toJson(),
    );
    return _parseUser(response.data);
  }

  /// `POST /api/owners/me/password` — body `{currentPassword, newPassword}`.
  /// The backend revokes ALL refresh tokens server-side and re-issues a fresh
  /// pair, replying `{success, accessToken, refreshToken}`. Returns the new
  /// token pair so the repository can persist it and keep the session alive.
  Future<PasswordChangeTokens> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.rawPost(
      ApiConfig.ownersMePassword,
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
  OwnerProfile _parseUser(Map<String, dynamic>? body) {
    final Map<String, dynamic> map = body ?? <String, dynamic>{};
    final Map<String, dynamic> user =
        (map['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return OwnerProfile.fromJson(user);
  }
}
