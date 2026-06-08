/// Repository owning the student center-detail operations (fetch detail / list
/// reviews / record view / create enquiry). Translates [ApiError] into a
/// feature-specific [CenterDetailException].
library;

import '../../../../../core/api/api_error.dart';
import '../models/center_detail_model.dart';
import '../models/center_review_model.dart';
import 'center_detail_remote_datasource.dart';

/// Feature-specific exception thrown by [CenterDetailRepository] on failure.
class CenterDetailException implements Exception {
  /// Creates the exception.
  CenterDetailException(this.message, {this.code});

  /// User-safe failure message (backend `message` where available).
  final String message;

  /// Optional sentinel (HTTP status code as string).
  final String? code;

  @override
  String toString() => message;
}

/// Concrete repository owning the center-detail calls.
class CenterDetailRepository {
  /// Wraps the [CenterDetailRemoteDataSource].
  CenterDetailRepository(this._remote);

  final CenterDetailRemoteDataSource _remote;

  /// Fetches the public centre profile via `GET /api/centers/:id`. Surfaces the
  /// backend's `message` (e.g. the 404 "Coaching center not found") verbatim.
  Future<CenterDetail> getById(String id) {
    return _guard(
      () async => CenterDetail.fromJson(await _remote.fetchById(id)),
      'Something went wrong while loading this center',
    );
  }

  /// Lists the centre's reviews. Surfaced as a [CenterDetailException] on
  /// failure (the screen treats reviews as non-fatal and shows an empty state).
  Future<List<CenterReview>> getReviews(String id) {
    return _guard(
      () async {
        final List<Map<String, dynamic>> rows = await _remote.fetchReviews(id);
        return rows.map(CenterReview.fromJson).toList();
      },
      'Could not load reviews',
    );
  }

  /// Records a profile view — fire-and-forget; never throws (analytics only).
  Future<void> recordView(String id) async {
    try {
      await _remote.recordView(id);
    } catch (_) {
      // Best-effort analytics; ignore failures.
    }
  }

  /// Sends a student enquiry via `POST /api/centers/:id/enquiries`.
  Future<void> submitEnquiry(
    String id, {
    required String message,
    String? subjectId,
  }) {
    return _guard(
      () => _remote.createEnquiry(id, message: message, subjectId: subjectId),
      'Something went wrong while sending your enquiry',
    );
  }

  /// Runs [task], translating [ApiError] (and unexpected throwables) into a
  /// [CenterDetailException] with a user-safe [fallback] message.
  Future<T> _guard<T>(Future<T> Function() task, String fallback) async {
    try {
      return await task();
    } on ApiError catch (e) {
      throw CenterDetailException(e.message, code: e.statusCode?.toString());
    } on CenterDetailException {
      rethrow;
    } catch (_) {
      throw CenterDetailException(fallback);
    }
  }
}
