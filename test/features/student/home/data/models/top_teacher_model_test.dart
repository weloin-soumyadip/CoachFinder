import 'package:coachfinder/features/student/home/data/models/top_teacher_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TopTeacher.fromJson', () {
    test('maps _id -> id and parses every field', () {
      final teacher = TopTeacher.fromJson(<String, dynamic>{
        '_id': 't1',
        'name': 'Marcus Chen',
        'profileImage': 'https://cdn/x.png',
        'subjects': <String>['Physics', 'Maths'],
        'averageRating': 4.8,
        'totalReviews': 120,
      });
      expect(teacher.id, 't1');
      expect(teacher.name, 'Marcus Chen');
      expect(teacher.profileImage, 'https://cdn/x.png');
      expect(teacher.subjects, <String>['Physics', 'Maths']);
      expect(teacher.averageRating, 4.8);
      expect(teacher.totalReviews, 120);
    });

    test('applies controller defaults for absent optional fields', () {
      final teacher = TopTeacher.fromJson(<String, dynamic>{
        '_id': 't2',
        'name': 'Nameless',
      });
      expect(teacher.profileImage, '');
      expect(teacher.subjects, isEmpty);
      expect(teacher.averageRating, 0);
      expect(teacher.totalReviews, 0);
    });

    test('coerces an int averageRating to double', () {
      final teacher = TopTeacher.fromJson(<String, dynamic>{
        '_id': 't3',
        'name': 'IntRating',
        'averageRating': 5,
      });
      expect(teacher.averageRating, 5.0);
    });
  });
}
