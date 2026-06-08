/// Tests for [TeacherDetail.fromJson] — parses the public `/api/teachers/:id`
/// document tolerantly (feesRange, education, batches; subjects come as ids).
library;

import 'package:coachfinder/features/student/teacher_detail/data/models/teacher_detail_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeacherDetail.fromJson', () {
    test('parses core fields, fees, education, batches', () {
      final t = TeacherDetail.fromJson(<String, dynamic>{
        '_id': 't1',
        'name': 'Anita Rao',
        'bio': 'Physics tutor',
        'experienceYears': 8,
        'feesRange': <String, dynamic>{'min': 500, 'max': 1200},
        'boards': <dynamic>['CBSE', 'ICSE'],
        'classRange': <String, dynamic>{'from': 9, 'to': 12},
        'languages': <dynamic>['English', 'Hindi'],
        'education': <dynamic>[
          <String, dynamic>{
            'degree': 'M.Sc Physics',
            'institution': 'IIT',
            'year': 2014,
          },
        ],
        'batches': <dynamic>[
          <String, dynamic>{
            'name': 'Evening',
            'days': <dynamic>['Mon', 'Wed'],
            'startTime': '17:00',
            'endTime': '19:00',
          },
        ],
        'subjects': <dynamic>['idA', 'idB'], // bare ids → no names
        'city': 'Pune',
        'state': 'MH',
        'averageRating': 4.7,
        'totalReviews': 23,
        'isVerified': true,
      });

      expect(t.id, 't1');
      expect(t.name, 'Anita Rao');
      expect(t.experienceYears, 8);
      expect(t.fees?.min, 500);
      expect(t.boards, <String>['CBSE', 'ICSE']);
      expect(t.classRange?.to, 12);
      expect(t.languages, <String>['English', 'Hindi']);
      expect(t.education.single.degree, 'M.Sc Physics');
      expect(t.education.single.summary, contains('IIT'));
      expect(t.batches.single.name, 'Evening');
      expect(t.batches.single.days, <String>['Mon', 'Wed']);
      expect(t.subjectNames, isEmpty); // bare ids yield no names
      expect(t.locationLabel, 'Pune, MH');
      expect(t.averageRating, 4.7);
      expect(t.isVerified, isTrue);
    });

    test('keeps subject names when populated as objects', () {
      final t = TeacherDetail.fromJson(<String, dynamic>{
        '_id': 't1',
        'name': 'X',
        'subjects': <dynamic>[
          <String, dynamic>{'_id': 's1', 'name': 'Maths'},
        ],
      });
      expect(t.subjectNames, <String>['Maths']);
    });

    test('tolerates missing optional blocks', () {
      final t = TeacherDetail.fromJson(<String, dynamic>{
        '_id': 't1',
        'name': 'X',
      });
      expect(t.fees, isNull);
      expect(t.classRange, isNull);
      expect(t.education, isEmpty);
      expect(t.batches, isEmpty);
      expect(t.boards, isEmpty);
      expect(t.experienceYears, 0);
      expect(t.initial, 'X');
    });
  });
}
