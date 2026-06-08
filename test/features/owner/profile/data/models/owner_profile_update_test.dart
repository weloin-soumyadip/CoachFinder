/// Tests for [OwnerProfileUpdate.toJson] — it must emit ONLY the non-null keys
/// so `PATCH /api/owners/me` stays a true partial.
library;

import 'package:coachfinder/features/owner/profile/data/models/owner_profile_update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OwnerProfileUpdate.toJson', () {
    test('emits only the supplied (non-null) keys', () {
      const update = OwnerProfileUpdate(name: 'Asha', phone: '9876543210');
      expect(update.toJson(), <String, dynamic>{
        'name': 'Asha',
        'phone': '9876543210',
      });
    });

    test('an all-null update serialises to an empty map and isEmpty', () {
      const update = OwnerProfileUpdate();
      expect(update.isEmpty, isTrue);
      expect(update.toJson(), isEmpty);
    });

    test('includes profileImage when set', () {
      const update = OwnerProfileUpdate(profileImage: 'https://x/y.png');
      expect(update.toJson(), <String, dynamic>{
        'profileImage': 'https://x/y.png',
      });
      expect(update.isEmpty, isFalse);
    });
  });
}
