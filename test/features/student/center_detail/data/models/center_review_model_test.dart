/// Tests for [CenterReview.fromJson] — parses the populated student + rating.
library;

import 'package:coachfinder/features/student/center_detail/data/models/center_review_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CenterReview.fromJson', () {
    test('parses student name/image, rating, comment', () {
      final r = CenterReview.fromJson(<String, dynamic>{
        '_id': 'r1',
        'student': <String, dynamic>{
          'name': 'Asha',
          'profileImage': 'https://x/a.png',
        },
        'rating': 5,
        'comment': '  Great!  ',
        'createdAt': '2026-01-15T10:30:00.000Z',
      });

      expect(r.id, 'r1');
      expect(r.studentName, 'Asha');
      expect(r.studentImage, 'https://x/a.png');
      expect(r.rating, 5);
      expect(r.comment, 'Great!');
      expect(r.createdAt, isNotNull);
    });

    test('falls back to "Student" when name is missing', () {
      final r = CenterReview.fromJson(<String, dynamic>{
        '_id': 'r1',
        'rating': 3,
      });

      expect(r.studentName, 'Student');
      expect(r.studentImage, '');
      expect(r.comment, isNull);
    });
  });
}
