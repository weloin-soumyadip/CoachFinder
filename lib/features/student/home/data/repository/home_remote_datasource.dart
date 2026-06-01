/// Dio calls for student home content.
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';
import '../../../../../core/api/api_response.dart';
import '../models/student_dashboard_model.dart';

/// Thin remote datasource for the student home/dashboard feature. Each method
/// issues exactly one [ApiClient] call and returns the parsed [ApiResponse].
/// No business logic, no storage — the repository owns that.
class HomeRemoteDataSource {
  HomeRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/students/dashboard`. The [ApiClient] interceptor attaches the
  /// cached bearer token automatically (the endpoint is protected + student
  /// only). The backend nests the payload under a top-level `dashboard` key,
  /// which [StudentDashboard.fromJson] reads off the full envelope handed to
  /// it by [ApiResponse.fromJson].
  Future<ApiResponse<StudentDashboard>> fetchDashboard() {
    return _apiClient.get<StudentDashboard>(
      ApiConfig.studentsDashboard,
      fromJson: (json) => StudentDashboard.fromJson(json),
    );
  }
}
