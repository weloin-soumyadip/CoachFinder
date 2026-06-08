import 'package:coachfinder/core/api/api_client.dart';
import 'package:coachfinder/features/student/saved/data/controllers/bookmarks_provider.dart';
import 'package:coachfinder/features/student/saved/data/models/bookmark_model.dart';
import 'package:coachfinder/features/student/saved/data/repository/bookmarks_remote_datasource.dart';
import 'package:coachfinder/features/student/saved/data/repository/bookmarks_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repository that overrides the three bookmark calls so the controller's
/// optimistic-mutation logic can be exercised without a backend. [listAllCalls]
/// records how many times a full reload was triggered — the regression guard for
/// "a failed remove must NOT kick off a blocking full-list reload".
class _FakeRepository extends BookmarksRepository {
  _FakeRepository() : super(BookmarksRemoteDataSource(ApiClient()));

  List<Bookmark> items = <Bookmark>[];
  int listAllCalls = 0;
  bool removeShouldThrow = false;

  @override
  Future<List<Bookmark>> listAll() async {
    listAllCalls++;
    return List<Bookmark>.from(items);
  }

  @override
  Future<void> remove(String bookmarkId) async {
    if (removeShouldThrow) {
      throw BookmarksException('Could not remove (timeout)');
    }
    items.removeWhere((Bookmark b) => b.id == bookmarkId);
  }
}

Bookmark _bookmark(String id, BookmarkTargetType type, String targetId) {
  return Bookmark.fromJson(<String, dynamic>{
    '_id': id,
    'targetType': type.wireValue,
    'target': targetId,
  });
}

void main() {
  late _FakeRepository repo;

  Future<BookmarkController> buildLoadedController() async {
    repo = _FakeRepository()
      ..items = <Bookmark>[
        _bookmark('bm1', BookmarkTargetType.teacher, 't1'),
        _bookmark('bm2', BookmarkTargetType.coachingCenter, 'c9'),
      ];
    final BookmarkController controller = BookmarkController(repo);
    // Let the constructor's fire-and-forget load() settle.
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.bookmarks.length, 2);
    expect(repo.listAllCalls, 1);
    return controller;
  }

  test('remove() drops the item optimistically on success', () async {
    final BookmarkController controller = await buildLoadedController();

    await controller.remove('bm1');

    expect(
        controller.state.bookmarks.map((Bookmark b) => b.id), <String>['bm2']);
    expect(controller.state.isSavedKey('Teacher:t1'), isFalse);
    // No full reload on success — the optimistic result stands.
    expect(repo.listAllCalls, 1);
  });

  test(
    'remove() failure reverts the item WITHOUT a blocking full reload',
    () async {
      final BookmarkController controller = await buildLoadedController();
      repo.removeShouldThrow = true;

      await controller.remove('bm1');

      // The item is restored in place and the key comes back …
      expect(
        controller.state.bookmarks.map((Bookmark b) => b.id),
        <String>['bm1', 'bm2'],
      );
      expect(controller.state.isSavedKey('Teacher:t1'), isTrue);
      // … the error is surfaced …
      expect(controller.state.errorMessage, isNotNull);
      // … the list never flips back to a loading spinner …
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.status, BookmarkStatus.data);
      // … and crucially NO second listAll() ran (that reload is the spinner).
      expect(repo.listAllCalls, 1);
    },
  );
}
