/// Dio calls for center CRUD. Currently implements the create path
/// (`POST /api/centers`); the read / edit screens remain mock-backed until a
/// later pass wires them too.
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';
import '../models/center_create_request.dart';

/// Thin remote datasource for the manage-center feature. Each method issues
/// exactly one call via [ApiClient]; no business logic — the repository owns
/// that. The interceptor attaches the bearer token (these are owner endpoints).
class ManageCenterRemoteDataSource {
  /// Wraps the shared [ApiClient].
  ManageCenterRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/centers` — creates the owner's center. Replies `201 {center}`
  /// at the top level; we don't need the echoed doc on success (the dashboard
  /// re-fetches), so we only rely on the absence of a thrown error. A `409`
  /// (owner already has a center) surfaces as a thrown `ApiError`.
  Future<void> createCenter(CenterCreateRequest request) async {
    await _apiClient.rawPost(ApiConfig.centers, data: request.toJson());
  }

  /// `GET /api/centers/me` — the owner's own center. Returns the top-level
  /// `center` document (the envelope is `{center: <doc>}`), or null if the key
  /// is absent. Throws `ApiError` with a `404` status when the owner has no
  /// center yet; the repository turns that into a "no center" answer. Other
  /// statuses propagate as `ApiError`.
  Future<Map<String, dynamic>?> fetchMine() async {
    final response = await _apiClient.rawGet(ApiConfig.centersMe);
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    return body['center'] as Map<String, dynamic>?;
  }

  /// `PATCH /api/centers/:id` — strict-partial update. Sends only the changed
  /// keys; replies `{center: <updated doc>}` at the top level. Returns the
  /// updated centre document (empty map if absent). A `403` (not your centre) /
  /// `400` (validation) surfaces as a thrown `ApiError`.
  Future<Map<String, dynamic>> updateCenter(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _apiClient.rawPatch(ApiConfig.centerById(id), data: body);
    final Map<String, dynamic> data = response.data ?? <String, dynamic>{};
    return (data['center'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  /// `GET /api/subjects` — the public subject list (paginated; we take the
  /// first page, large limit). Returns the raw `data` array of subject docs.
  Future<List<Map<String, dynamic>>> fetchSubjects() async {
    final response = await _apiClient.rawGet(
      ApiConfig.subjects,
      queryParameters: <String, dynamic>{'limit': 100},
    );
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    final List<dynamic> data = (body['data'] as List<dynamic>?) ?? <dynamic>[];
    return data.whereType<Map<String, dynamic>>().toList();
  }
}
