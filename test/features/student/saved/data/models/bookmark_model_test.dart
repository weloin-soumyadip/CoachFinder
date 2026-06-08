import 'package:coachfinder/features/student/saved/data/models/bookmark_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookmarkTargetType', () {
    test('wireValue maps to the exact backend strings', () {
      expect(BookmarkTargetType.teacher.wireValue, 'Teacher');
      expect(BookmarkTargetType.webinar.wireValue, 'Webinar');
      expect(BookmarkTargetType.coachingCenter.wireValue, 'CoachingCenter');
    });

    test('fromWire round-trips every wire value', () {
      for (final BookmarkTargetType type in BookmarkTargetType.values) {
        expect(BookmarkTargetType.fromWire(type.wireValue), type);
      }
    });

    test('fromWire defaults to teacher on an unknown value', () {
      expect(
          BookmarkTargetType.fromWire('Nonsense'), BookmarkTargetType.teacher);
    });
  });

  group('Bookmark.fromJson — list response (populated target map)', () {
    final Bookmark bookmark = Bookmark.fromJson(<String, dynamic>{
      '_id': 'bm1',
      'targetType': 'Teacher',
      'target': <String, dynamic>{
        '_id': 't1',
        'name': 'Marcus Chen',
        'profileImage': 'https://cdn/x.png',
        'averageRating': 4.8,
        'totalReviews': 120,
        'isVerified': true,
        'slug': 'marcus-chen',
        'city': 'Bengaluru',
        'area': 'Indiranagar',
      },
      'createdAt': '2026-05-01T10:00:00.000Z',
      'updatedAt': '2026-05-01T10:00:00.000Z',
    });

    test('maps _id -> id', () => expect(bookmark.id, 'bm1'));
    test('parses targetType via fromWire',
        () => expect(bookmark.targetType, BookmarkTargetType.teacher));
    test('targetId comes from target._id',
        () => expect(bookmark.targetId, 't1'));
    test('retains the populated target map', () {
      expect(bookmark.target['name'], 'Marcus Chen');
      expect(bookmark.target['_id'], 't1');
    });
    test('key is "<wireType>:<targetId>"',
        () => expect(bookmark.key, 'Teacher:t1'));
    test('parses createdAt', () => expect(bookmark.createdAt, isA<DateTime>()));
  });

  group('Bookmark.fromJson — create response (bare-string target)', () {
    final Bookmark bookmark = Bookmark.fromJson(<String, dynamic>{
      '_id': 'bm2',
      'targetType': 'CoachingCenter',
      'target': 'c9',
      'createdAt': '2026-05-02T10:00:00.000Z',
      'updatedAt': '2026-05-02T10:00:00.000Z',
    });

    test('targetId is the bare string', () => expect(bookmark.targetId, 'c9'));
    test('target map is empty', () => expect(bookmark.target, isEmpty));
    test('key uses the string targetId',
        () => expect(bookmark.key, 'CoachingCenter:c9'));
    test('targetType parsed',
        () => expect(bookmark.targetType, BookmarkTargetType.coachingCenter));
  });

  test('Bookmark.fromJson tolerates a missing createdAt', () {
    final Bookmark bookmark = Bookmark.fromJson(<String, dynamic>{
      '_id': 'bm3',
      'targetType': 'Webinar',
      'target': 'w1',
    });
    expect(bookmark.createdAt, isNull);
    expect(bookmark.key, 'Webinar:w1');
  });
}
