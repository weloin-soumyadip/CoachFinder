import 'package:coachfinder/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.fromJson', () {
    test('maps backend _id to id', () {
      final user = User.fromJson(<String, dynamic>{
        '_id': '67234c0e7e1c0a4d5f6a7b8c',
        'name': 'Alice',
        'email': 'alice@example.com',
        'phone': '+919999999999',
        'profileImage': '',
        'isActive': true,
        'isEmailVerified': false,
        'createdAt': '2026-05-28T10:00:00.000Z',
        'updatedAt': '2026-05-28T10:00:00.000Z',
      });
      expect(user.id, '67234c0e7e1c0a4d5f6a7b8c');
      expect(user.name, 'Alice');
      expect(user.email, 'alice@example.com');
      expect(user.phone, '+919999999999');
      expect(user.profileImage, '');
      expect(user.isActive, true);
      expect(user.isEmailVerified, false);
      expect(
          user.createdAt.toUtc().toIso8601String(), '2026-05-28T10:00:00.000Z');
    });

    test('treats missing phone as null and missing profileImage as empty', () {
      final user = User.fromJson(<String, dynamic>{
        '_id': 'x',
        'name': 'Bob',
        'email': 'b@x.com',
        'isActive': true,
        'isEmailVerified': false,
        'createdAt': '2026-05-28T10:00:00.000Z',
        'updatedAt': '2026-05-28T10:00:00.000Z',
      });
      expect(user.phone, isNull);
      expect(user.profileImage, '');
    });

    test('ignores unknown / role-specific extra fields', () {
      final user = User.fromJson(<String, dynamic>{
        '_id': 'x',
        'name': 'Vikram',
        'email': 'v@x.com',
        'isActive': true,
        'isEmailVerified': false,
        'createdAt': '2026-05-28T10:00:00.000Z',
        'updatedAt': '2026-05-28T10:00:00.000Z',
        'bio': 'Math tutor',
        'subjects': <String>['Maths', 'Physics'],
        'feesRange': <String, dynamic>{'min': 500, 'max': 1000},
      });
      expect(user.id, 'x');
    });
  });

  group('User.toJson', () {
    test('round-trips via fromJson with id (not _id)', () {
      final original = User(
        id: 'abc',
        name: 'Alice',
        email: 'a@x.com',
        phone: '+1',
        profileImage: 'http://img/a.png',
        isActive: true,
        isEmailVerified: true,
        createdAt: DateTime.utc(2026, 5, 28, 10),
        updatedAt: DateTime.utc(2026, 5, 28, 11),
      );
      final json = original.toJson();
      expect(json['id'], 'abc');
      expect(json['name'], 'Alice');
      expect(json['email'], 'a@x.com');
      expect(json['phone'], '+1');
      expect(json['profileImage'], 'http://img/a.png');
      expect(json['isActive'], true);
      expect(json['isEmailVerified'], true);
      expect(json['createdAt'], '2026-05-28T10:00:00.000Z');
      expect(json['updatedAt'], '2026-05-28T11:00:00.000Z');
    });
  });
}
