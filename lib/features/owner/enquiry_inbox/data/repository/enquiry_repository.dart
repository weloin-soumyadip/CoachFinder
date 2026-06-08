/// Repository owning the owner enquiry operations (list / search / detail /
/// update). Translates [ApiError] into a feature-specific [EnquiryException].
library;

import '../../../../../core/api/api_error.dart';
import '../models/enquiry_model.dart';
import 'enquiry_remote_datasource.dart';

/// Feature-specific exception thrown by [EnquiryRepository] on failure.
class EnquiryException implements Exception {
  /// Creates the exception.
  EnquiryException(this.message, {this.code});

  /// User-safe failure message (backend `message` where available).
  final String message;

  /// Optional sentinel (HTTP status code as string).
  final String? code;

  @override
  String toString() => message;
}

/// One parsed page of enquiries.
class EnquiryPage {
  /// Creates a page.
  const EnquiryPage({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
  });

  /// The enquiries on this page.
  final List<Enquiry> items;

  /// 1-based page number.
  final int page;

  /// Total page count.
  final int pages;

  /// Total matching enquiries.
  final int total;

  /// Whether a further page exists.
  bool get hasMore => page < pages;
}

/// Concrete repository owning the enquiry calls.
class EnquiryRepository {
  /// Wraps the [EnquiryRemoteDataSource].
  EnquiryRepository(this._remote);

  final EnquiryRemoteDataSource _remote;

  /// Lists enquiries — uses the search endpoint when [query] is non-empty,
  /// otherwise the plain list endpoint. Both support the [status] filter.
  Future<EnquiryPage> list({
    required int page,
    required int limit,
    EnquiryStatus? status,
    String query = '',
  }) {
    return _guard(
      () async {
        final String q = query.trim();
        final EnquiryRawPage raw = q.isEmpty
            ? await _remote.list(page: page, limit: limit, status: status)
            : await _remote.search(
                page: page,
                limit: limit,
                query: q,
                status: status,
              );
        return EnquiryPage(
          items: raw.rows.map(Enquiry.fromJson).toList(),
          page: raw.page,
          pages: raw.pages,
          total: raw.total,
        );
      },
      'Could not load enquiries',
    );
  }

  /// Fetches one enquiry via `GET /api/owners/enquiries/:id`.
  Future<Enquiry> getById(String id) {
    return _guard(
      () async => Enquiry.fromJson(await _remote.fetchById(id)),
      'Could not load this enquiry',
    );
  }

  /// Updates status and/or owner notes via `PATCH /api/owners/enquiries/:id`,
  /// returning the updated enquiry.
  Future<Enquiry> update(
    String id, {
    EnquiryStatus? status,
    String? ownerNotes,
  }) {
    return _guard(
      () async {
        final Map<String, dynamic> body = <String, dynamic>{
          if (status != null) 'status': status.wireValue,
          if (ownerNotes != null) 'ownerNotes': ownerNotes,
        };
        return Enquiry.fromJson(await _remote.update(id, body));
      },
      'Could not update this enquiry',
    );
  }

  /// Runs [task], translating [ApiError] (and unexpected throwables) into an
  /// [EnquiryException] with a user-safe [fallback] message.
  Future<T> _guard<T>(Future<T> Function() task, String fallback) async {
    try {
      return await task();
    } on ApiError catch (e) {
      throw EnquiryException(e.message, code: e.statusCode?.toString());
    } on EnquiryException {
      rethrow;
    } catch (_) {
      throw EnquiryException(fallback);
    }
  }
}
