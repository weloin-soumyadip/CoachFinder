/// Dio calls for the student bookmarks endpoints. Reads the `data` + sibling
/// `pagination` blocks (list) and the top-level `bookmark` (create) that the
/// standard [ApiResponse] envelope would drop.
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';
import '../../../search/data/models/search_result_model.dart'
    show SearchPagination;
import '../models/bookmark_model.dart';

/// One page of bookmarks plus its pagination metadata. Reuses the search
/// feature's [SearchPagination] since the envelope shape is identical.
class BookmarkPage {
  const BookmarkPage({required this.items, required this.pagination});

  /// The parsed `data[]` bookmarks for this page (newest first).
  final List<Bookmark> items;

  /// The `pagination` sibling block (`{page, limit, total, pages}`).
  final SearchPagination pagination;
}

/// Thin remote datasource for the student bookmarks feature. Each method issues
/// exactly one call via [ApiClient]; no business logic — the repository owns
/// that. The interceptor attaches the bearer token (bookmarks are student-only).
class BookmarksRemoteDataSource {
  BookmarksRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/students/bookmarks` — one page of the caller's bookmarks,
  /// optionally filtered to a single [targetType]. Reads `data` + `pagination`
  /// off the raw envelope.
  Future<BookmarkPage> list({
    required int page,
    required int limit,
    BookmarkTargetType? targetType,
  }) async {
    final response = await _apiClient.rawGet(
      ApiConfig.studentsBookmarks,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        if (targetType != null) 'targetType': targetType.wireValue,
      },
    );
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    final dynamic rawData = body['data'];
    final List<Bookmark> items = rawData is List
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(Bookmark.fromJson)
            .toList()
        : <Bookmark>[];
    return BookmarkPage(
      items: items,
      pagination: SearchPagination.fromJson(
        body['pagination'] as Map<String, dynamic>?,
      ),
    );
  }

  /// `POST /api/students/bookmarks` — saves [targetId] of [targetType]. Reads
  /// the TOP-LEVEL `bookmark` (the create response does not nest under `data`,
  /// and `target` comes back as a bare id string).
  Future<Bookmark> create(
      BookmarkTargetType targetType, String targetId) async {
    final response = await _apiClient.rawPost(
      ApiConfig.studentsBookmarks,
      data: <String, dynamic>{
        'targetType': targetType.wireValue,
        'targetId': targetId,
      },
    );
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    final Map<String, dynamic> bookmarkJson =
        (body['bookmark'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return Bookmark.fromJson(bookmarkJson);
  }

  /// `DELETE /api/students/bookmarks/:id` — removes the bookmark with id
  /// [bookmarkId]. Replies `204`; a thrown `ApiError` is the only failure
  /// signal, so a normal return means success.
  Future<void> remove(String bookmarkId) async {
    await _apiClient.delete('${ApiConfig.studentsBookmarks}/$bookmarkId');
  }
}
