/// Tests for [CenterDetail.fromJson] — parses the public `/api/centers/:id`
/// document tolerantly.
library;

import 'package:coachfinder/features/student/center_detail/data/models/center_detail_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CenterDetail.fromJson', () {
    test('parses core fields, populated subjects, and nested objects', () {
      final c = CenterDetail.fromJson(<String, dynamic>{
        '_id': 'c1',
        'name': 'Apex',
        'description': 'Best',
        'address': '12 MG Road',
        'area': 'Salt Lake',
        'city': 'Kolkata',
        'state': 'WB',
        'phone': '9876543210',
        'subjectsOffered': <dynamic>[
          <String, dynamic>{'_id': 's1', 'name': 'Physics'},
        ],
        'boards': <dynamic>['CBSE'],
        'classRange': <String, dynamic>{'from': 6, 'to': 12},
        'fees': <String, dynamic>{'min': 1000, 'max': 5000, 'currency': 'INR'},
        'timings': <dynamic>[
          <String, dynamic>{'day': 'Mon', 'openTime': '16:00', 'closed': false},
        ],
        'averageRating': 4.5,
        'totalReviews': 12,
        'isVerified': true,
      });

      expect(c.id, 'c1');
      expect(c.name, 'Apex');
      expect(c.locationLabel, 'Salt Lake, Kolkata');
      expect(c.initial, 'A');
      expect(c.subjects.single.name, 'Physics');
      expect(c.boards, <String>['CBSE']);
      expect(c.classRange?.from, 6);
      expect(c.fees?.max, 5000);
      expect(c.timings.single.day, 'Mon');
      expect(c.averageRating, 4.5);
      expect(c.totalReviews, 12);
      expect(c.isVerified, isTrue);
    });

    test('tolerates missing optional blocks', () {
      final c = CenterDetail.fromJson(<String, dynamic>{
        '_id': 'c1',
        'name': 'X',
        'address': 'A',
        'city': 'K',
        'state': 'WB',
        'phone': '9',
      });

      expect(c.classRange, isNull);
      expect(c.fees, isNull);
      expect(c.timings, isEmpty);
      expect(c.subjects, isEmpty);
      expect(c.isVerified, isFalse);
      expect(c.locationLabel, 'K');
    });
  });
}
