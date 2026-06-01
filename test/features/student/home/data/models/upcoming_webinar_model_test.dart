import 'package:coachfinder/features/student/home/data/models/upcoming_webinar_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpcomingWebinar.fromJson', () {
    test('maps _id -> id, parses scheduledAt and nested teacher', () {
      final webinar = UpcomingWebinar.fromJson(<String, dynamic>{
        '_id': 'w1',
        'title': 'Crack JEE Physics',
        'teacher': <String, dynamic>{
          'name': 'Marcus Chen',
          'profileImage': 'https://cdn/t.png',
          'totalReviews': 120,
        },
        'scheduledAt': '2026-06-01T10:00:00.000Z',
        'thumbnail': 'https://cdn/thumb.png',
        'joinUrl': 'https://meet/abc',
      });
      expect(webinar.id, 'w1');
      expect(webinar.title, 'Crack JEE Physics');
      expect(webinar.teacher.name, 'Marcus Chen');
      expect(webinar.teacher.profileImage, 'https://cdn/t.png');
      expect(webinar.teacher.totalReviews, 120);
      expect(webinar.scheduledAt,
          DateTime.parse('2026-06-01T10:00:00.000Z'));
      expect(webinar.thumbnail, 'https://cdn/thumb.png');
      expect(webinar.joinUrl, 'https://meet/abc');
    });

    test('applies defaults for absent optional fields', () {
      final webinar = UpcomingWebinar.fromJson(<String, dynamic>{
        '_id': 'w2',
        'title': 'Minimal',
        'teacher': <String, dynamic>{},
        'scheduledAt': '2026-06-02T08:30:00.000Z',
      });
      expect(webinar.teacher.name, '');
      expect(webinar.teacher.profileImage, '');
      expect(webinar.teacher.totalReviews, 0);
      expect(webinar.thumbnail, '');
      expect(webinar.joinUrl, '');
    });
  });
}
