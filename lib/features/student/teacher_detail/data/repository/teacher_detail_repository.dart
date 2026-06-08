/// Repository owning the student teacher-detail operations (fetch detail / list
/// reviews). Translates [ApiError] into a [TeacherDetailException].
library;

import '../../../../../core/api/api_error.dart';
import '../models/teacher_detail_model.dart';
import '../models/teacher_review_model.dart';
import 'teacher_detail_remote_datasource.dart';

/// Feature-specific exception thrown by [TeacherDetailRepository] on failure.
class TeacherDetailException implements Exception {
  /// Creates the exception.
  TeacherDetailException(this.message, {this.code});

  /// User-safe failure message (backend `message` where available).
  final String message;

  /// Optional sentinel (HTTP status code as string).
  final String? code;

  @override
  String toString() => message;
}

/// Concrete repository owning the teacher-detail calls.
class TeacherDetailRepository {
  /// Wraps the [TeacherDetailRemoteDataSource].
  TeacherDetailRepository(this._remote);

  final TeacherDetailRemoteDataSource _remote;

  /// Fetches the public teacher profile via `GET /api/teachers/:id`.
  Future<TeacherDetail> getById(String id) {
    return _guard(
      () async => TeacherDetail.fromJson(await _remote.fetchById(id)),
      'Something went wrong while loading this teacher',
    );
  }

  /// Lists the teacher's reviews (non-fatal — the screen shows an empty state
  /// on failure).
  Future<List<TeacherReview>> getReviews(String id) {
    return _guard(
      () async {
        final List<Map<String, dynamic>> rows = await _remote.fetchReviews(id);
        return rows.map(TeacherReview.fromJson).toList();
      },
      'Could not load reviews',
    );
  }

  /// Runs [task], translating [ApiError] (and unexpected throwables) into a
  /// [TeacherDetailException] with a user-safe [fallback].
  Future<T> _guard<T>(Future<T> Function() task, String fallback) async {
    try {
      return await task();
    } on ApiError catch (e) {
      throw TeacherDetailException(e.message, code: e.statusCode?.toString());
    } on TeacherDetailException {
      rethrow;
    } catch (_) {
      throw TeacherDetailException(fallback);
    }
  }
}
