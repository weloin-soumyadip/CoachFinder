/// Tests for [CenterUpdate.toJson] — it must emit ONLY the changed keys so the
/// `PATCH /api/centers/:id` body stays a strict partial, mapping `subjectIds` →
/// `subjectsOffered` and serialising the nested objects.
library;

import 'package:coachfinder/features/owner/manage_center/data/models/center_update.dart';
import 'package:coachfinder/features/owner/manage_center/data/models/owner_center.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CenterUpdate.toJson', () {
    test('an all-null update is empty', () {
      const update = CenterUpdate();
      expect(update.isEmpty, isTrue);
      expect(update.toJson(), isEmpty);
    });

    test('emits only the supplied keys', () {
      const update = CenterUpdate(name: 'New', city: 'Pune');
      expect(update.toJson(), <String, dynamic>{'name': 'New', 'city': 'Pune'});
    });

    test('maps subjectIds to subjectsOffered', () {
      const update = CenterUpdate(subjectIds: <String>['s1', 's2']);
      expect(update.toJson(), <String, dynamic>{
        'subjectsOffered': <String>['s1', 's2'],
      });
    });

    test('serialises nested classRange / fees / timings', () {
      const update = CenterUpdate(
        classRange: CenterClassRange(from: 6, to: 10),
        fees: CenterFees(min: 1000, max: 5000),
        timings: <CenterTiming>[
          CenterTiming(day: 'Mon', openTime: '09:00', closeTime: '17:00'),
          CenterTiming(day: 'Sun', closed: true),
        ],
      );

      final json = update.toJson();
      expect(json['classRange'], <String, dynamic>{'from': 6, 'to': 10});
      expect(json['fees'], <String, dynamic>{
        'min': 1000,
        'max': 5000,
        'currency': 'INR',
      });
      expect((json['timings'] as List<dynamic>).length, 2);
      expect((json['timings'] as List<dynamic>).first, <String, dynamic>{
        'day': 'Mon',
        'openTime': '09:00',
        'closeTime': '17:00',
        'closed': false,
      });
      expect((json['timings'] as List<dynamic>).last, <String, dynamic>{
        'day': 'Sun',
        'closed': true,
      });
    });
  });
}
