/// Tests for [OwnerCenter.fromJson] — it parses the full `/api/centers/me`
/// document tolerantly (populated subjects, nested fees/classRange/timings).
library;

import 'package:coachfinder/features/owner/manage_center/data/models/owner_center.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OwnerCenter.fromJson', () {
    test('parses the core fields, populated subjects, and nested objects', () {
      final center = OwnerCenter.fromJson(<String, dynamic>{
        '_id': 'c1',
        'name': 'Apex',
        'description': 'Best',
        'address': '12 MG Road',
        'area': 'Salt Lake',
        'city': 'Kolkata',
        'state': 'WB',
        'pincode': '700064',
        'phone': '9876543210',
        'subjectsOffered': <dynamic>[
          <String, dynamic>{'_id': 's1', 'name': 'Physics', 'slug': 'physics'},
          <String, dynamic>{'_id': 's2', 'name': 'Maths'},
        ],
        'boards': <dynamic>['CBSE', 'ICSE'],
        'classRange': <String, dynamic>{'from': 6, 'to': 12},
        'fees': <String, dynamic>{'min': 1000, 'max': 5000, 'currency': 'INR'},
        'timings': <dynamic>[
          <String, dynamic>{
            'day': 'Mon',
            'openTime': '16:00',
            'closeTime': '19:00',
            'closed': false,
          },
        ],
        'averageRating': 4.5,
        'totalReviews': 12,
      });

      expect(center.id, 'c1');
      expect(center.name, 'Apex');
      expect(center.area, 'Salt Lake');
      expect(center.subjects.length, 2);
      expect(center.subjects.first.id, 's1');
      expect(center.subjects.first.name, 'Physics');
      expect(center.boards, <String>['CBSE', 'ICSE']);
      expect(center.classRange?.from, 6);
      expect(center.classRange?.to, 12);
      expect(center.fees?.min, 1000);
      expect(center.fees?.max, 5000);
      expect(center.fees?.currency, 'INR');
      expect(center.timings.single.day, 'Mon');
      expect(center.timings.single.openTime, '16:00');
      expect(center.timings.single.closed, isFalse);
      expect(center.averageRating, 4.5);
      expect(center.totalReviews, 12);
    });

    test('tolerates bare-string subject ids and missing optional blocks', () {
      final center = OwnerCenter.fromJson(<String, dynamic>{
        '_id': 'c1',
        'name': 'Apex',
        'address': 'A',
        'city': 'K',
        'state': 'WB',
        'pincode': '7',
        'phone': '9',
        'subjectsOffered': <dynamic>['rawId'],
      });

      expect(center.subjects.single.id, 'rawId');
      expect(center.subjects.single.name, '');
      expect(center.classRange, isNull);
      expect(center.fees, isNull);
      expect(center.timings, isEmpty);
      expect(center.boards, isEmpty);
      expect(center.description, isNull);
    });

    test('exposes the backend board enum values', () {
      expect(
        OwnerCenter.boardOptions,
        <String>['CBSE', 'ICSE', 'State', 'IB', 'IGCSE', 'Other'],
      );
    });
  });
}
