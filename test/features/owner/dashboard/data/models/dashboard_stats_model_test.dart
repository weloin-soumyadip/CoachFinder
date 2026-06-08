/// Tests for the owner-dashboard models backing `GET /api/owners/dashboard`.
/// Mirrors the verified backend `data` payload (7 zero-filled profileViewStats,
/// ≤5 recentEnquiries) and the defensive / coercion behaviour required of
/// [OwnerDashboardData.fromJson].
library;

import 'package:coachfinder/features/owner/dashboard/data/models/dashboard_stats_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OwnerDashboardData.fromJson', () {
    test('parses a full realistic data payload', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'weeklyProfileViews': 58,
        'weeklyEnquiries': 12,
        // averageRating arrives as a double here.
        'averageRating': 4.5,
        'totalReviews': 27,
        'activeStudents': 3,
        'profileViewStats': <Map<String, dynamic>>[
          <String, dynamic>{'date': '2026-05-29', 'views': 10},
          <String, dynamic>{'date': '2026-05-30', 'views': 0},
          <String, dynamic>{'date': '2026-05-31', 'views': 8},
          <String, dynamic>{'date': '2026-06-01', 'views': 12},
          <String, dynamic>{'date': '2026-06-02', 'views': 7},
          <String, dynamic>{'date': '2026-06-03', 'views': 9},
          <String, dynamic>{'date': '2026-06-04', 'views': 12},
        ],
        'recentEnquiries': <Map<String, dynamic>>[
          <String, dynamic>{
            'enquiryId': 'e1',
            'studentName': 'Asha Rao',
            'phone': '+919812345678',
            'email': 'asha@example.com',
            'message': 'Is there a weekend batch?',
            'createdAt': '2026-06-04T09:30:00.000Z',
          },
          <String, dynamic>{
            'enquiryId': 'e2',
            'studentName': 'Vikram Singh',
            'phone': '+919811112222',
            'email': 'vikram@example.com',
            'message': 'What are the fees?',
            'createdAt': '2026-06-03T14:05:00.000Z',
          },
        ],
      };

      final OwnerDashboardData data = OwnerDashboardData.fromJson(json);

      expect(data.weeklyProfileViews, 58);
      expect(data.weeklyEnquiries, 12);
      expect(data.averageRating, 4.5);
      expect(data.averageRating, isA<double>());
      expect(data.totalReviews, 27);
      expect(data.activeStudents, 3);

      expect(data.profileViewStats, hasLength(7));
      final ProfileViewPoint first = data.profileViewStats.first;
      expect(first.date, DateTime(2026, 5, 29));
      expect(first.views, 10);
      // The zero-filled day is preserved.
      expect(data.profileViewStats[1].views, 0);
      expect(data.profileViewStats.last.date, DateTime(2026, 6, 4));
      expect(data.profileViewStats.last.views, 12);

      expect(data.recentEnquiries, hasLength(2));
      final RecentEnquiry e1 = data.recentEnquiries.first;
      expect(e1.enquiryId, 'e1');
      expect(e1.studentName, 'Asha Rao');
      expect(e1.phone, '+919812345678');
      expect(e1.email, 'asha@example.com');
      expect(e1.message, 'Is there a weekend batch?');
      expect(
        e1.createdAt,
        DateTime.parse('2026-06-04T09:30:00.000Z'),
      );
    });

    test('coerces averageRating that arrives as an int to a double', () {
      final OwnerDashboardData data = OwnerDashboardData.fromJson(
        <String, dynamic>{'averageRating': 4},
      );
      expect(data.averageRating, 4.0);
      expect(data.averageRating, isA<double>());
    });

    test('coerces string-encoded numbers (numbers + ratings)', () {
      final OwnerDashboardData data = OwnerDashboardData.fromJson(
        <String, dynamic>{
          'weeklyProfileViews': '58',
          'weeklyEnquiries': '12',
          'averageRating': '4.5',
          'totalReviews': '27',
          'activeStudents': '3',
          'profileViewStats': <Map<String, dynamic>>[
            <String, dynamic>{'date': '2026-06-04', 'views': '12'},
          ],
        },
      );
      expect(data.weeklyProfileViews, 58);
      expect(data.weeklyEnquiries, 12);
      expect(data.averageRating, 4.5);
      expect(data.totalReviews, 27);
      expect(data.activeStudents, 3);
      expect(data.profileViewStats.single.views, 12);
    });

    test('is null-tolerant: numbers default to 0, arrays to empty', () {
      final OwnerDashboardData data =
          OwnerDashboardData.fromJson(<String, dynamic>{});
      expect(data.weeklyProfileViews, 0);
      expect(data.weeklyEnquiries, 0);
      expect(data.averageRating, 0.0);
      expect(data.totalReviews, 0);
      expect(data.activeStudents, 0);
      expect(data.profileViewStats, isEmpty);
      expect(data.recentEnquiries, isEmpty);
    });

    test('tolerates null / wrong-typed array fields', () {
      final OwnerDashboardData data = OwnerDashboardData.fromJson(
        <String, dynamic>{
          'profileViewStats': null,
          'recentEnquiries': 'not-a-list',
        },
      );
      expect(data.profileViewStats, isEmpty);
      expect(data.recentEnquiries, isEmpty);
    });
  });

  group('ProfileViewPoint.fromJson', () {
    test('parses a bare YYYY-MM-DD date string', () {
      final ProfileViewPoint p = ProfileViewPoint.fromJson(
        <String, dynamic>{'date': '2026-05-30', 'views': 4},
      );
      expect(p.date, DateTime(2026, 5, 30));
      expect(p.views, 4);
    });

    test('null-tolerant: bad date → null, missing views → 0', () {
      final ProfileViewPoint bad = ProfileViewPoint.fromJson(
        <String, dynamic>{'date': 'not-a-date'},
      );
      expect(bad.date, isNull);
      expect(bad.views, 0);

      final ProfileViewPoint empty =
          ProfileViewPoint.fromJson(<String, dynamic>{});
      expect(empty.date, isNull);
      expect(empty.views, 0);
    });
  });

  group('RecentEnquiry.fromJson', () {
    test('strings default to empty, bad createdAt → null', () {
      final RecentEnquiry e = RecentEnquiry.fromJson(<String, dynamic>{});
      expect(e.enquiryId, '');
      expect(e.studentName, '');
      expect(e.phone, '');
      expect(e.email, '');
      expect(e.message, '');
      expect(e.createdAt, isNull);

      final RecentEnquiry bad = RecentEnquiry.fromJson(
        <String, dynamic>{'createdAt': 'nope'},
      );
      expect(bad.createdAt, isNull);
    });
  });
}
