/// Tests for [StudentProfileUpdate.toJson] — it must emit ONLY the non-null
/// keys so `PATCH /api/students/me` stays a true partial.
library;

import 'package:coachfinder/features/student/profile/data/models/student_profile_model.dart';
import 'package:coachfinder/features/student/profile/data/models/student_profile_update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentProfileUpdate.toJson', () {
    test('emits only the supplied (non-null) keys', () {
      const update = StudentProfileUpdate(name: 'Asha', city: 'Pune');

      expect(update.toJson(), <String, dynamic>{
        'name': 'Asha',
        'city': 'Pune',
      });
    });

    test('an all-null update serialises to an empty map', () {
      const update = StudentProfileUpdate();

      expect(update.toJson(), isEmpty);
    });

    test('serialises a local dateOfBirth as a bare date-only YYYY-MM-DD string',
        () {
      // Date-only field: no time/timezone, so a local-midnight pick can't shift
      // a day across the UTC boundary on the round-trip.
      final update = StudentProfileUpdate(
        dateOfBirth: DateTime(2008, 4, 15, 23, 30),
      );

      expect(update.toJson()['dateOfBirth'], '2008-04-15');
    });

    test('serialises a UTC-origin dateOfBirth from its own calendar components',
        () {
      // The backend stores dateOfBirth as UTC-midnight and echoes it back as
      // `...T00:00:00.000Z`, so the seeded value is a UTC DateTime. Serialising
      // must read THAT instant's components (TZ-independent), NOT `.toLocal()`
      // — otherwise the day shifts back one on devices west of UTC. An early-AM
      // UTC time is the case that would expose a wrongful localisation.
      final fromMidnight =
          StudentProfileUpdate(dateOfBirth: DateTime.utc(2008, 4, 15));
      final fromEarlyAm =
          StudentProfileUpdate(dateOfBirth: DateTime.utc(2008, 4, 15, 2));

      expect(fromMidnight.toJson()['dateOfBirth'], '2008-04-15');
      expect(fromEarlyAm.toJson()['dateOfBirth'], '2008-04-15');
    });

    test('zero-pads single-digit month and day', () {
      final update = StudentProfileUpdate(dateOfBirth: DateTime(2010, 1, 5));

      expect(update.toJson()['dateOfBirth'], '2010-01-05');
    });

    test('serialises enums via their wireValue', () {
      const update = StudentProfileUpdate(
        gender: StudentGender.preferNotToSay,
        board: StudentBoard.cbse,
        currentClass: 9,
      );

      final json = update.toJson();
      expect(json['gender'], 'prefer_not_to_say');
      expect(json['board'], 'CBSE');
      expect(json['currentClass'], 9);
    });

    test('isEmpty reflects whether any field is set', () {
      expect(const StudentProfileUpdate().isEmpty, true);
      expect(const StudentProfileUpdate(name: 'x').isEmpty, false);
    });
  });
}
