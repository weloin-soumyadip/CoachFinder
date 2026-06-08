/// Repository owning the student search operations across all three entity
/// types (teacher / coaching center / webinar).
library;

import '../../../../../core/api/api_error.dart';
import '../models/filter_model.dart';
import '../models/search_result_model.dart';
import 'search_remote_datasource.dart';

/// Feature-specific exception thrown by [SearchRepository] on failure.
/// Controllers catch this and translate to an error state. Mirrors
/// `AuthException` / `HomeException`.
class SearchException implements Exception {
  SearchException(this.message, {this.code});

  /// User-safe failure message — already the backend's `message` field where
  /// available.
  final String message;

  /// Optional sentinel (HTTP status code as string, or `'NETWORK_ERROR'` /
  /// `'TIMEOUT'` / `'UNKNOWN'`).
  final String? code;

  @override
  String toString() => message;
}

/// Concrete repository owning the three search calls. Each returns a typed
/// [SearchPage] (items + pagination) or throws [SearchException].
class SearchRepository {
  SearchRepository(this._remote);

  final SearchRemoteDataSource _remote;

  /// Searches teachers (`searchType=teacher`).
  Future<SearchPage<TeacherSearchResult>> searchTeachers(
    SearchFilters filters, {
    int page = 1,
    int limit = 20,
  }) {
    return _guard(
      () => _remote.searchTeachers(filters, page: page, limit: limit),
      'Something went wrong while searching for teachers',
    );
  }

  /// Searches coaching centers (`searchType=coaching`).
  Future<SearchPage<CenterSearchResult>> searchCenters(
    SearchFilters filters, {
    int page = 1,
    int limit = 20,
  }) {
    return _guard(
      () => _remote.searchCenters(filters, page: page, limit: limit),
      'Something went wrong while searching for centers',
    );
  }

  /// Searches webinars (`searchType=webinar`).
  Future<SearchPage<WebinarSearchResult>> searchWebinars(
    SearchFilters filters, {
    int page = 1,
    int limit = 20,
  }) {
    return _guard(
      () => _remote.searchWebinars(filters, page: page, limit: limit),
      'Something went wrong while searching for webinars',
    );
  }

  /// Runs [task], translating [ApiError] (and unexpected throwables) into a
  /// [SearchException] with a user-safe [fallback] message.
  Future<T> _guard<T>(Future<T> Function() task, String fallback) async {
    try {
      return await task();
    } on ApiError catch (e) {
      throw SearchException(e.message, code: e.statusCode?.toString());
    } on SearchException {
      rethrow;
    } catch (_) {
      throw SearchException(fallback);
    }
  }
}
