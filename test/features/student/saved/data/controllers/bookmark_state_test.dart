import 'package:coachfinder/features/student/saved/data/controllers/bookmarks_provider.dart';
import 'package:coachfinder/features/student/saved/data/models/bookmark_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Bookmark bookmark(String id, BookmarkTargetType type, String targetId) {
    return Bookmark.fromJson(<String, dynamic>{
      '_id': id,
      'targetType': type.wireValue,
      'target': targetId,
    });
  }

  group('BookmarkState membership', () {
    final BookmarkState state = const BookmarkState().copyWith(
      status: BookmarkStatus.data,
      bookmarks: <Bookmark>[
        bookmark('bm1', BookmarkTargetType.teacher, 't1'),
        bookmark('bm2', BookmarkTargetType.coachingCenter, 'c9'),
      ],
      savedKeys: <String>{'Teacher:t1', 'CoachingCenter:c9'},
    );

    test('isSavedKey reports membership', () {
      expect(state.isSavedKey('Teacher:t1'), isTrue);
      expect(state.isSavedKey('Webinar:w1'), isFalse);
    });

    test('bookmarkIdForKey returns the matching bookmark id', () {
      expect(state.bookmarkIdForKey('Teacher:t1'), 'bm1');
      expect(state.bookmarkIdForKey('CoachingCenter:c9'), 'bm2');
    });

    test('bookmarkIdForKey is null when absent', () {
      expect(state.bookmarkIdForKey('Webinar:w1'), isNull);
    });

    test('hasData / isLoading reflect status', () {
      expect(state.hasData, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('copyWith replaces errorMessage (clearable to null)', () {
      final BookmarkState withError = state.copyWith(errorMessage: 'boom');
      expect(withError.errorMessage, 'boom');
      expect(withError.copyWith(errorMessage: null).errorMessage, isNull);
    });
  });
}
