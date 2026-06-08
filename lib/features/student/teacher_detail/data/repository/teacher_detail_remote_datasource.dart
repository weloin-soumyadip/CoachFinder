/// Dio calls for the public teacher-detail + reviews endpoints.
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';

/// Thin remote datasource for the student teacher-detail feature.
class TeacherDetailRemoteDataSource {
  /// Wraps the shared [ApiClient].
  TeacherDetailRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/teachers/:id` — public profile. Returns the top-level `teacher`
  /// document. Throws `ApiError` (404 when missing / inactive).
  Future<Map<String, dynamic>> fetchById(String id) async {
    final response = await _apiClient.rawGet(ApiConfig.teacherById(id));
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    return (body['teacher'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  /// `GET /api/teachers/:id/reviews` — public review list (first page).
  Future<List<Map<String, dynamic>>> fetchReviews(String id) async {
    final response = await _apiClient.rawGet(
      ApiConfig.teacherReviews(id),
      queryParameters: <String, dynamic>{'limit': 50},
    );
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    final List<dynamic> data = (body['data'] as List<dynamic>?) ?? <dynamic>[];
    return data.whereType<Map<String, dynamic>>().toList();
  }
}
