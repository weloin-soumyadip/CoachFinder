/// Tests for [Enquiry.fromJson] + the status enum wire mapping.
library;

import 'package:coachfinder/features/owner/enquiry_inbox/data/models/enquiry_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Enquiry.fromJson', () {
    test('parses populated student + subject, status, and notes', () {
      final e = Enquiry.fromJson(<String, dynamic>{
        '_id': 'e1',
        'student': <String, dynamic>{
          'name': 'Ananya Sharma',
          'phone': '+91 98765 43210',
          'email': 'a@x.com',
        },
        'subject': <String, dynamic>{'_id': 's1', 'name': 'Physics'},
        'message': 'Weekend batch?',
        'status': 'contacted',
        'ownerNotes': 'Called back',
        'createdAt': '2026-01-15T10:30:00.000Z',
      });

      expect(e.id, 'e1');
      expect(e.studentName, 'Ananya Sharma');
      expect(e.studentPhone, '+91 98765 43210');
      expect(e.studentEmail, 'a@x.com');
      expect(e.subjectName, 'Physics');
      expect(e.message, 'Weekend batch?');
      expect(e.status, EnquiryStatus.contacted);
      expect(e.ownerNotes, 'Called back');
      expect(e.initial, 'A');
      expect(e.createdAt, isNotNull);
    });

    test('defaults: unknown status → new, missing student name → "Student"',
        () {
      final e = Enquiry.fromJson(<String, dynamic>{
        '_id': 'e1',
        'message': 'Hi',
        'status': 'bogus',
      });
      expect(e.status, EnquiryStatus.newEnquiry);
      expect(e.studentName, 'Student');
      expect(e.subjectName, isNull);
      expect(e.ownerNotes, isNull);
    });
  });

  group('EnquiryStatus', () {
    test('wire round-trip', () {
      expect(EnquiryStatus.fromWire('new'), EnquiryStatus.newEnquiry);
      expect(EnquiryStatus.fromWire('contacted'), EnquiryStatus.contacted);
      expect(EnquiryStatus.fromWire('closed'), EnquiryStatus.closed);
      expect(EnquiryStatus.contacted.wireValue, 'contacted');
    });
  });

  group('EnquiryFilter.status', () {
    test('maps to the backing status (null for all)', () {
      expect(EnquiryFilter.all.status, isNull);
      expect(EnquiryFilter.newEnquiry.status, EnquiryStatus.newEnquiry);
      expect(EnquiryFilter.closed.status, EnquiryStatus.closed);
    });
  });
}
