/// Tests for [TeacherReview.fromJson].
library;

import 'package:coachfinder/features/student/teacher_detail/data/models/teacher_review_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeacherReview.fromJson', () {
    test('parses student name/image, rating, comment', () {
      final r = TeacherReview.fromJson(<String, dynamic>{
        '_id': 'r1',
        'student': <String, dynamic>{'name': 'Asha', 'profileImage': 'u'},
        'rating': 4,
        'comment': '  Helpful  ',
        'createdAt': '2026-01-15T10:30:00.000Z',
      });
      expect(r.studentName, 'Asha');
      expect(r.studentImage, 'u');
      expect(r.rating, 4);
      expect(r.comment, 'Helpful');
      expect(r.createdAt, isNotNull);
    });

    test('falls back to "Student" when name missing', () {
      final r =
          TeacherReview.fromJson(<String, dynamic>{'_id': 'r1', 'rating': 5});
      expect(r.studentName, 'Student');
      expect(r.comment, isNull);
    });
  });
}
