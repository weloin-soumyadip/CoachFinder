/// Repository owning the owner-dashboard fetch. Translates transport failures
/// into a feature-specific [OwnerDashboardException] the controller catches.
library;

import '../../../../../core/api/api_error.dart';
import '../models/dashboard_stats_model.dart';
import 'dashboard_remote_datasource.dart';

/// Feature-specific exception thrown by [OwnerDashboardRepository] on failure.
/// Mirrors `BookmarksException` / `StudentProfileException`. The controller
/// catches this and surfaces [message] (the backend's verbatim `message` where
/// available — e.g. the 404 "No coaching center found for this owner").
class OwnerDashboardException implements Exception {
  OwnerDashboardException(this.message, {this.code});

  /// User-safe failure message — the backend's `message` where available, else
  /// a plain fallback.
  final String message;

  /// Optional sentinel (HTTP status code as string, or `'NETWORK_ERROR'` /
  /// `'TIMEOUT'` / `'UNKNOWN'`).
  final String? code;

  @override
  String toString() => message;
}

/// Concrete repository owning the single dashboard call. Throws an
/// [OwnerDashboardException] on any failure.
class OwnerDashboardRepository {
  OwnerDashboardRepository(this._remote);

  final OwnerDashboardRemoteDataSource _remote;

  /// Fetches the owner's dashboard payload. Surfaces the backend's `message`
  /// (e.g. the 404 when the owner has no center) verbatim.
  Future<OwnerDashboardData> fetch() {
    return _guard(
      _remote.fetch,
      'Something went wrong while loading your dashboard',
    );
  }

  /// Runs [task], translating [ApiError] (and unexpected throwables) into an
  /// [OwnerDashboardException] with a user-safe [fallback] message.
  Future<T> _guard<T>(Future<T> Function() task, String fallback) async {
    try {
      return await task();
    } on ApiError catch (e) {
      throw OwnerDashboardException(
        e.message,
        code: e.statusCode?.toString(),
      );
    } on OwnerDashboardException {
      rethrow;
    } catch (_) {
      throw OwnerDashboardException(fallback);
    }
  }
}
