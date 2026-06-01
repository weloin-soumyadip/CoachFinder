import 'package:coachfinder/features/student/home/data/models/student_dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentDashboard.fromJson', () {
    test('reads the nested dashboard key off the full top-level envelope', () {
      // ApiResponse.fromJson does `json['data'] ?? json`; with no `data` key it
      // hands fromJson the FULL {success, dashboard} map.
      final dashboard = StudentDashboard.fromJson(<String, dynamic>{
        'success': true,
        'dashboard': <String, dynamic>{
          'topTeachers': <Map<String, dynamic>>[
            <String, dynamic>{
              '_id': 't1',
              'name': 'Marcus Chen',
              'profileImage': '',
              'subjects': <String>['Physics'],
              'averageRating': 4.8,
              'totalReviews': 120,
            },
          ],
          'topCenters': <Map<String, dynamic>>[
            <String, dynamic>{
              '_id': 'c1',
              'name': 'Bright Academy',
              'image': '',
              'averageRating': 4.5,
              'totalReviews': 80,
              'city': 'Kolkata',
              'area': 'Salt Lake',
            },
          ],
          'upcomingWebinars': <Map<String, dynamic>>[
            <String, dynamic>{
              '_id': 'w1',
              'title': 'Crack JEE Physics',
              'teacher': <String, dynamic>{
                'name': 'Marcus Chen',
                'profileImage': '',
                'totalReviews': 120,
              },
              'scheduledAt': '2026-06-01T10:00:00.000Z',
              'thumbnail': '',
              'joinUrl': '',
            },
          ],
        },
      });
      expect(dashboard.topTeachers, hasLength(1));
      expect(dashboard.topTeachers.first.id, 't1');
      expect(dashboard.topCenters, hasLength(1));
      expect(dashboard.topCenters.first.id, 'c1');
      expect(dashboard.upcomingWebinars, hasLength(1));
      expect(dashboard.upcomingWebinars.first.id, 'w1');
    });

    test('defaults to empty lists when dashboard key is absent', () {
      final dashboard = StudentDashboard.fromJson(<String, dynamic>{
        'success': true,
      });
      expect(dashboard.topTeachers, isEmpty);
      expect(dashboard.topCenters, isEmpty);
      expect(dashboard.upcomingWebinars, isEmpty);
    });

    test('tolerates absent list keys inside dashboard', () {
      final dashboard = StudentDashboard.fromJson(<String, dynamic>{
        'dashboard': <String, dynamic>{
          'topTeachers': <Map<String, dynamic>>[
            <String, dynamic>{'_id': 't1', 'name': 'Solo'},
          ],
        },
      });
      expect(dashboard.topTeachers, hasLength(1));
      expect(dashboard.topCenters, isEmpty);
      expect(dashboard.upcomingWebinars, isEmpty);
    });
  });
}
