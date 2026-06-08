/// Tests for [StudentProfile] parsing + the [StudentGender] / [StudentBoard]
/// wire enums. Mirrors the shape of `GET /api/auth/me`'s sanitized student doc.
library;

import 'package:coachfinder/features/student/profile/data/models/student_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentProfile.fromJson', () {
    test('parses a full /auth/me user doc, mapping _id to id', () {
      final json = <String, dynamic>{
        '_id': 'stu_123',
        'name': 'Asha Rao',
        'email': 'asha@example.com',
        'phone': '+91 90000 00000',
        'profileImage': 'https://cdn/img.png',
        'dateOfBirth': '2008-04-15T00:00:00.000Z',
        'gender': 'female',
        'currentClass': 10,
        'board': 'CBSE',
        'city': 'Pune',
        'isActive': true,
        'isEmailVerified': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-02-01T00:00:00.000Z',
      };

      final profile = StudentProfile.fromJson(json);

      expect(profile.id, 'stu_123');
      expect(profile.name, 'Asha Rao');
      expect(profile.email, 'asha@example.com');
      expect(profile.phone, '+91 90000 00000');
      expect(profile.profileImage, 'https://cdn/img.png');
      expect(profile.dateOfBirth, DateTime.parse('2008-04-15T00:00:00.000Z'));
      expect(profile.gender, StudentGender.female);
      expect(profile.currentClass, 10);
      expect(profile.board, StudentBoard.cbse);
      expect(profile.city, 'Pune');
      expect(profile.isActive, true);
      expect(profile.isEmailVerified, true);
      expect(profile.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(profile.updatedAt, DateTime.parse('2024-02-01T00:00:00.000Z'));
    });

    test('is null-tolerant when every optional field is absent', () {
      final json = <String, dynamic>{
        '_id': 'stu_min',
        'name': 'Min User',
        'email': 'min@example.com',
      };

      final profile = StudentProfile.fromJson(json);

      expect(profile.id, 'stu_min');
      expect(profile.name, 'Min User');
      expect(profile.email, 'min@example.com');
      expect(profile.phone, isNull);
      expect(profile.profileImage, ''); // defaults to empty string
      expect(profile.dateOfBirth, isNull);
      expect(profile.gender, isNull);
      expect(profile.currentClass, isNull);
      expect(profile.board, isNull);
      expect(profile.city, isNull);
      expect(profile.isActive, false);
      expect(profile.isEmailVerified, false);
      expect(profile.createdAt, isNull);
      expect(profile.updatedAt, isNull);
    });

    test('tolerates unparseable / unknown optional values', () {
      final json = <String, dynamic>{
        '_id': 'stu_bad',
        'name': 'Bad Data',
        'email': 'bad@example.com',
        'dateOfBirth': 'not-a-date',
        'gender': 'martian',
        'board': 'Unknown',
        'currentClass': 'ten',
      };

      final profile = StudentProfile.fromJson(json);

      expect(profile.dateOfBirth, isNull);
      expect(profile.gender, isNull);
      expect(profile.board, isNull);
      expect(profile.currentClass, isNull);
    });

    test('copyWith replaces only the supplied fields', () {
      final base = StudentProfile.fromJson(<String, dynamic>{
        '_id': 'x',
        'name': 'Old',
        'email': 'x@example.com',
        'city': 'Pune',
      });

      final next = base.copyWith(name: 'New');

      expect(next.name, 'New');
      expect(next.city, 'Pune');
      expect(next.email, 'x@example.com');
    });
  });

  group('StudentGender', () {
    test('fromWire round-trips every known value', () {
      expect(StudentGender.fromWire('male'), StudentGender.male);
      expect(StudentGender.fromWire('female'), StudentGender.female);
      expect(StudentGender.fromWire('other'), StudentGender.other);
      expect(
        StudentGender.fromWire('prefer_not_to_say'),
        StudentGender.preferNotToSay,
      );
    });

    test('fromWire returns null for null / unknown', () {
      expect(StudentGender.fromWire(null), isNull);
      expect(StudentGender.fromWire(''), isNull);
      expect(StudentGender.fromWire('martian'), isNull);
    });

    test('wireValue + label are correct', () {
      expect(StudentGender.preferNotToSay.wireValue, 'prefer_not_to_say');
      expect(StudentGender.preferNotToSay.label, 'Prefer not to say');
      expect(StudentGender.male.label, 'Male');
      expect(StudentGender.female.wireValue, 'female');
    });
  });

  group('StudentBoard', () {
    test('fromWire round-trips every known value', () {
      expect(StudentBoard.fromWire('CBSE'), StudentBoard.cbse);
      expect(StudentBoard.fromWire('ICSE'), StudentBoard.icse);
      expect(StudentBoard.fromWire('State'), StudentBoard.state);
      expect(StudentBoard.fromWire('IB'), StudentBoard.ib);
      expect(StudentBoard.fromWire('IGCSE'), StudentBoard.igcse);
      expect(StudentBoard.fromWire('Other'), StudentBoard.other);
    });

    test('fromWire returns null for null / unknown', () {
      expect(StudentBoard.fromWire(null), isNull);
      expect(StudentBoard.fromWire(''), isNull);
      expect(StudentBoard.fromWire('IGNOU'), isNull);
    });

    test('wireValue + label are correct', () {
      expect(StudentBoard.cbse.wireValue, 'CBSE');
      expect(StudentBoard.cbse.label, 'CBSE');
      expect(StudentBoard.state.wireValue, 'State');
    });
  });
}
