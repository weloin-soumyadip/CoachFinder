import 'package:coachfinder/core/api/api_client.dart';
import 'package:coachfinder/features/student/saved/data/controllers/bookmarks_provider.dart';
import 'package:coachfinder/features/student/saved/data/models/bookmark_model.dart';
import 'package:coachfinder/features/student/saved/data/repository/bookmarks_remote_datasource.dart';
import 'package:coachfinder/features/student/saved/data/repository/bookmarks_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repository whose [listAll] can throw an UNEXPECTED (non-
/// [BookmarksException]) error, to prove the controller never gets stuck in the
/// `loading` state — `state.isLoading` must always settle to false.
class _FakeRepository extends BookmarksRepository {
  _FakeRepository() : super(BookmarksRemoteDataSource(ApiClient()));

  List<Bookmark> items = <Bookmark>[];
  Object? listAllError; // when set, listAll throws this instead of returning.

  @override
  Future<List<Bookmark>> listAll() async {
    final Object? err = listAllError;
    if (err != null) throw err;
    return List<Bookmark>.from(items);
  }
}

void main() {
  test(
    'load() always clears isLoading, even when listAll throws an unexpected '
    'error (not a BookmarksException)',
    () async {
      final _FakeRepository repo = _FakeRepository();
      final BookmarkController controller = BookmarkController(repo);
      // Let the constructor's initial load() settle (returns []).
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.isLoading, isFalse);

      // Now make the next load fail with a raw Error that is NOT a
      // BookmarksException (e.g. a parsing/type error that bypassed the guard).
      repo.listAllError = StateError('unexpected boom');
      await controller.load();

      // The spinner must clear: status settles to error, never stuck loading.
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.status, BookmarkStatus.error);
      expect(controller.state.errorMessage, isNotNull);
    },
  );
}
