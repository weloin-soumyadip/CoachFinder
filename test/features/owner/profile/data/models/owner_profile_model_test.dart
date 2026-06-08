/// Tests for [OwnerProfile.fromJson] + the derived initial / firstName getters.
library;

import 'package:coachfinder/features/owner/profile/data/models/owner_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OwnerProfile.fromJson', () {
    test('parses _id, name, email, phone and flags', () {
      final p = OwnerProfile.fromJson(<String, dynamic>{
        '_id': 'o1',
        'name': 'Rajesh Kumar',
        'email': 'rajesh@x.com',
        'phone': '9876543210',
        'isActive': true,
        'isEmailVerified': true,
      });

      expect(p.id, 'o1');
      expect(p.name, 'Rajesh Kumar');
      expect(p.email, 'rajesh@x.com');
      expect(p.phone, '9876543210');
      expect(p.isActive, isTrue);
      expect(p.isEmailVerified, isTrue);
      expect(p.firstName, 'Rajesh');
      expect(p.initial, 'R');
    });

    test('tolerates missing optional fields', () {
      final p = OwnerProfile.fromJson(<String, dynamic>{
        '_id': 'o1',
        'name': '',
        'email': 'x@y.com',
      });

      expect(p.phone, isNull);
      expect(p.profileImage, '');
      expect(p.isActive, isFalse);
      expect(p.firstName, '');
      expect(p.initial, '?');
    });
  });
}
