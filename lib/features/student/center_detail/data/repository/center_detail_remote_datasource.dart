/// Dio calls for the public center-detail, reviews, view, and enquiry
/// endpoints. Each issues one call via [ApiClient]; the repository owns parsing
/// and error translation.
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';

/// Thin remote datasource for the student center-detail feature.
class CenterDetailRemoteDataSource {
  /// Wraps the shared [ApiClient].
  CenterDetailRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/centers/:id` — the public centre profile. Returns the top-level
  /// `center` document (`{center: <doc>}`). Throws `ApiError` (404 when the
  /// centre is missing / inactive).
  Future<Map<String, dynamic>> fetchById(String id) async {
    final response = await _apiClient.rawGet(ApiConfig.centerById(id));
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    return (body['center'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  /// `GET /api/centers/:id/reviews` — the public review list (first page; large
  /// limit). Returns the raw `data` array of review docs.
  Future<List<Map<String, dynamic>>> fetchReviews(String id) async {
    final response = await _apiClient.rawGet(
      ApiConfig.centerReviews(id),
      queryParameters: <String, dynamic>{'limit': 50},
    );
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    final List<dynamic> data = (body['data'] as List<dynamic>?) ?? <dynamic>[];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  /// `POST /api/centers/:id/views` — record a profile view (fire-and-forget).
  Future<void> recordView(String id) async {
    await _apiClient.rawPost(ApiConfig.centerViews(id));
  }

  /// `POST /api/centers/:id/enquiries` — student-authored enquiry. Body is
  /// `{message, subject?}`. Throws `ApiError` on failure.
  Future<void> createEnquiry(
    String id, {
    required String message,
    String? subjectId,
  }) async {
    await _apiClient.rawPost(
      ApiConfig.centerEnquiries(id),
      data: <String, dynamic>{
        'message': message,
        if (subjectId != null && subjectId.isNotEmpty) 'subject': subjectId,
      },
    );
  }
}
