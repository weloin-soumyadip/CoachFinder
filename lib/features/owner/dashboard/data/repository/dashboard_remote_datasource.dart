/// Dio call for the owner-dashboard endpoint. Reads the `data` block off the
/// raw envelope (the standard [ApiResponse] would drop nothing here, but the
/// payload is nested under `data`, so we read it explicitly like the bookmarks
/// list datasource).
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';
import '../models/dashboard_stats_model.dart';

/// Thin remote datasource for the owner dashboard. Issues exactly one call via
/// [ApiClient]; no business logic — the repository owns error translation. The
/// interceptor attaches the owner's bearer token.
class OwnerDashboardRemoteDataSource {
  OwnerDashboardRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/owners/dashboard` — the calling owner's center dashboard. Reads
  /// the `data` block off the raw envelope and parses it into
  /// [OwnerDashboardData].
  Future<OwnerDashboardData> fetch() async {
    final response = await _apiClient.rawGet(ApiConfig.ownersDashboard);
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    final Map<String, dynamic> data =
        (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return OwnerDashboardData.fromJson(data);
  }
}
