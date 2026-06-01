/// Repository owning the student home/dashboard operations.
library;

import '../../../../../core/api/api_error.dart';
import '../models/student_dashboard_model.dart';
import 'home_remote_datasource.dart';

/// Feature-specific exception thrown by [HomeRepository] on failure.
/// Controllers catch this and translate to an error state. Mirrors
/// `AuthException`.
class HomeException implements Exception {
  HomeException(this.message, {this.code});

  /// User-safe failure message — already the backend's `message` field where
  /// available.
  final String message;

  /// Optional sentinel (HTTP status code as string, or `'NETWORK_ERROR'` /
  /// `'TIMEOUT'` / `'UNKNOWN'`).
  final String? code;

  @override
  String toString() => message;
}

/// Single concrete repository owning the student dashboard fetch. Throws
/// [HomeException] on failure.
class HomeRepository {
  HomeRepository(this._remote);

  final HomeRemoteDataSource _remote;

  /// Fetches the aggregated student dashboard. Returns the parsed
  /// [StudentDashboard] or throws [HomeException].
  Future<StudentDashboard> fetchDashboard() async {
    try {
      final apiResponse = await _remote.fetchDashboard();
      if (!apiResponse.success || apiResponse.data == null) {
        throw HomeException(
          apiResponse.message ?? 'Failed to load your dashboard',
        );
      }
      return apiResponse.data!;
    } on ApiError catch (e) {
      throw HomeException(e.message, code: e.statusCode?.toString());
    } on HomeException {
      rethrow;
    } catch (_) {
      throw HomeException('Something went wrong while loading your dashboard');
    }
  }
}
