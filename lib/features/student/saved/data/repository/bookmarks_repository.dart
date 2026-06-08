/// Repository owning the student bookmark operations (list / create / remove)
/// across all three target types.
library;

import '../../../../../core/api/api_error.dart';
import '../models/bookmark_model.dart';
import 'bookmarks_remote_datasource.dart';

/// Feature-specific exception thrown by [BookmarksRepository] on failure.
/// Controllers catch this and translate to an error state. Mirrors
/// `SearchException` / `AuthException`.
class BookmarksException implements Exception {
  BookmarksException(this.message, {this.code, this.alreadyExists = false});

  /// User-safe failure message — the backend's `message` field where available.
  final String message;

  /// Optional sentinel (HTTP status code as string, or `'NETWORK_ERROR'` /
  /// `'TIMEOUT'` / `'UNKNOWN'`).
  final String? code;

  /// True when a create failed with `409 Already bookmarked` — the controller
  /// treats this as a benign success (the item is already saved).
  final bool alreadyExists;

  @override
  String toString() => message;
}

/// Highest page size the list endpoint accepts — used to drain all pages.
const int _kListPageSize = 50;

/// Concrete repository owning the three bookmark calls. Each throws a
/// [BookmarksException] on failure.
class BookmarksRepository {
  BookmarksRepository(this._remote);

  final BookmarksRemoteDataSource _remote;

  /// Drains EVERY page of the caller's bookmarks (limit [_kListPageSize] each),
  /// concatenating newest-first, so the controller holds the full set — needed
  /// for the search-card "is this saved?" membership check (there is no
  /// per-item check endpoint).
  Future<List<Bookmark>> listAll() async {
    return _guard(() async {
      final List<Bookmark> all = <Bookmark>[];
      int page = 1;
      while (true) {
        final BookmarkPage result =
            await _remote.list(page: page, limit: _kListPageSize);
        all.addAll(result.items);
        if (page >= result.pagination.pages || result.items.isEmpty) break;
        page += 1;
      }
      return all;
    }, 'Something went wrong while loading your saved items');
  }

  /// Saves [targetId] of [targetType]. Surfaces a `409 Already bookmarked` as a
  /// [BookmarksException] with [BookmarksException.alreadyExists] set.
  Future<Bookmark> create(BookmarkTargetType targetType, String targetId) {
    return _guard(
      () => _remote.create(targetType, targetId),
      'Something went wrong while saving this item',
    );
  }

  /// Removes the bookmark with id [bookmarkId].
  Future<void> remove(String bookmarkId) {
    return _guard(
      () => _remote.remove(bookmarkId),
      'Something went wrong while removing this item',
    );
  }

  /// Runs [task], translating [ApiError] (and unexpected throwables) into a
  /// [BookmarksException] with a user-safe [fallback] message. A `409` becomes
  /// an `alreadyExists` exception so the controller can treat it as success.
  Future<T> _guard<T>(Future<T> Function() task, String fallback) async {
    try {
      return await task();
    } on ApiError catch (e) {
      throw BookmarksException(
        e.message,
        code: e.statusCode?.toString(),
        alreadyExists: e.statusCode == 409,
      );
    } on BookmarksException {
      rethrow;
    } catch (_) {
      throw BookmarksException(fallback);
    }
  }
}
