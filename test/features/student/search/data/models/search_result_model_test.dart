import 'package:coachfinder/features/student/search/data/models/search_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeacherSearchResult.fromJson', () {
    test('maps _id -> id and parses every field', () {
      final result = TeacherSearchResult.fromJson(<String, dynamic>{
        '_id': 't1',
        'name': 'Marcus Chen',
        'profileImage': 'https://cdn/x.png',
        'subjects': <Map<String, dynamic>>[
          <String, dynamic>{'_id': 's1', 'name': 'Physics', 'slug': 'physics'},
          <String, dynamic>{'_id': 's2', 'name': 'Maths', 'slug': 'maths'},
        ],
        'experienceYears': 8,
        'feesRange': <String, dynamic>{'min': 500, 'max': 2000},
        'boards': <String>['CBSE', 'ICSE'],
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'averageRating': 4.8,
        'totalReviews': 120,
        'isVerified': true,
      });
      expect(result.id, 't1');
      expect(result.name, 'Marcus Chen');
      expect(result.profileImage, 'https://cdn/x.png');
      expect(result.subjects, <String>['Physics', 'Maths']);
      expect(result.experienceYears, 8);
      expect(result.feesRange.min, 500);
      expect(result.feesRange.max, 2000);
      expect(result.boards, <String>['CBSE', 'ICSE']);
      expect(result.city, 'Bengaluru');
      expect(result.state, 'Karnataka');
      expect(result.averageRating, 4.8);
      expect(result.totalReviews, 120);
      expect(result.isVerified, true);
    });

    test('applies defaults for absent optional fields', () {
      final result = TeacherSearchResult.fromJson(<String, dynamic>{
        '_id': 't2',
        'name': 'Nameless',
      });
      expect(result.profileImage, '');
      expect(result.subjects, isEmpty);
      expect(result.experienceYears, 0);
      expect(result.feesRange.min, 0);
      expect(result.feesRange.max, 0);
      expect(result.boards, isEmpty);
      expect(result.city, '');
      expect(result.state, '');
      expect(result.averageRating, 0);
      expect(result.totalReviews, 0);
      expect(result.isVerified, false);
    });

    test('coerces an int averageRating to double', () {
      final result = TeacherSearchResult.fromJson(<String, dynamic>{
        '_id': 't3',
        'name': 'IntRating',
        'averageRating': 5,
      });
      expect(result.averageRating, 5.0);
    });
  });

  group('CenterSearchResult.fromJson', () {
    test('maps _id -> id and parses every field', () {
      final result = CenterSearchResult.fromJson(<String, dynamic>{
        '_id': 'c1',
        'name': 'BrightPath Academy',
        'area': 'Koramangala',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'subjectsOffered': <Map<String, dynamic>>[
          <String, dynamic>{'_id': 's1', 'name': 'Maths', 'slug': 'maths'},
          <String, dynamic>{'_id': 's2', 'name': 'Science', 'slug': 'science'},
        ],
        'boards': <String>['CBSE'],
        'fees': <String, dynamic>{'min': 1000, 'max': 5000},
        'profileImage': 'https://cdn/c.png',
        'averageRating': 4.7,
        'totalReviews': 80,
        'isVerified': true,
      });
      expect(result.id, 'c1');
      expect(result.name, 'BrightPath Academy');
      expect(result.area, 'Koramangala');
      expect(result.city, 'Bengaluru');
      expect(result.state, 'Karnataka');
      expect(result.subjectsOffered, <String>['Maths', 'Science']);
      expect(result.boards, <String>['CBSE']);
      expect(result.fees.min, 1000);
      expect(result.fees.max, 5000);
      expect(result.profileImage, 'https://cdn/c.png');
      expect(result.averageRating, 4.7);
      expect(result.totalReviews, 80);
      expect(result.isVerified, true);
    });

    test('applies defaults for absent optional fields', () {
      final result = CenterSearchResult.fromJson(<String, dynamic>{
        '_id': 'c2',
        'name': 'Empty Center',
      });
      expect(result.area, '');
      expect(result.city, '');
      expect(result.state, '');
      expect(result.subjectsOffered, isEmpty);
      expect(result.boards, isEmpty);
      expect(result.fees.min, 0);
      expect(result.fees.max, 0);
      expect(result.profileImage, '');
      expect(result.averageRating, 0);
      expect(result.totalReviews, 0);
      expect(result.isVerified, false);
    });
  });

  group('WebinarSearchResult.fromJson', () {
    test('maps _id -> id, parses populated teacher and dates', () {
      final result = WebinarSearchResult.fromJson(<String, dynamic>{
        '_id': 'w1',
        'title': 'Intro to Calculus',
        'teacher': <String, dynamic>{
          '_id': 't1',
          'name': 'Marcus Chen',
          'profileImage': 'https://cdn/x.png',
        },
        'scheduledAt': '2026-07-01T10:00:00.000Z',
        'durationMinutes': 60,
        'thumbnail': 'https://cdn/thumb.png',
        'joinUrl': 'https://meet/abc',
        'status': 'scheduled',
      });
      expect(result.id, 'w1');
      expect(result.title, 'Intro to Calculus');
      expect(result.teacherName, 'Marcus Chen');
      expect(result.teacherProfileImage, 'https://cdn/x.png');
      expect(result.scheduledAt, DateTime.parse('2026-07-01T10:00:00.000Z'));
      expect(result.durationMinutes, 60);
      expect(result.thumbnail, 'https://cdn/thumb.png');
      expect(result.joinUrl, 'https://meet/abc');
      expect(result.status, 'scheduled');
    });

    test('tolerates absent teacher and optional fields', () {
      final result = WebinarSearchResult.fromJson(<String, dynamic>{
        '_id': 'w2',
        'title': 'No Teacher',
        'scheduledAt': '2026-07-01T10:00:00.000Z',
      });
      expect(result.teacherName, '');
      expect(result.teacherProfileImage, '');
      expect(result.durationMinutes, 0);
      expect(result.thumbnail, '');
      expect(result.joinUrl, '');
      expect(result.status, '');
    });
  });

  group('SearchPagination.fromJson', () {
    test('parses fields and computes hasMore', () {
      final p = SearchPagination.fromJson(<String, dynamic>{
        'page': 1,
        'limit': 20,
        'total': 45,
        'pages': 3,
      });
      expect(p.page, 1);
      expect(p.limit, 20);
      expect(p.total, 45);
      expect(p.pages, 3);
      expect(p.hasMore, true);
    });

    test('hasMore is false on the last page', () {
      final p = SearchPagination.fromJson(<String, dynamic>{
        'page': 3,
        'limit': 20,
        'total': 45,
        'pages': 3,
      });
      expect(p.hasMore, false);
    });

    test('coerces string-encoded numbers (bookmarks echoes query params)', () {
      // The bookmarks endpoint returns page/limit/total as the raw query-param
      // strings ('1', '50', '0') beside a numeric pages. A hard `as num` cast
      // would throw here; fromJson must coerce.
      final p = SearchPagination.fromJson(<String, dynamic>{
        'page': '1',
        'limit': '50',
        'total': '0',
        'pages': 0,
      });
      expect(p.page, 1);
      expect(p.limit, 50);
      expect(p.total, 0);
      expect(p.pages, 0);
      expect(p.hasMore, false);
    });
  });
}
