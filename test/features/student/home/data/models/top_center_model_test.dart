import 'package:coachfinder/features/student/home/data/models/top_center_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TopCenter.fromJson', () {
    test('maps _id -> id and parses every field', () {
      final center = TopCenter.fromJson(<String, dynamic>{
        '_id': 'c1',
        'name': 'Bright Academy',
        'image': 'https://cdn/c.png',
        'averageRating': 4.5,
        'totalReviews': 80,
        'city': 'Kolkata',
        'area': 'Salt Lake',
      });
      expect(center.id, 'c1');
      expect(center.name, 'Bright Academy');
      expect(center.image, 'https://cdn/c.png');
      expect(center.averageRating, 4.5);
      expect(center.totalReviews, 80);
      expect(center.city, 'Kolkata');
      expect(center.area, 'Salt Lake');
    });

    test('applies defaults for absent optional fields', () {
      final center = TopCenter.fromJson(<String, dynamic>{
        '_id': 'c2',
        'name': 'No Frills',
        'city': 'Delhi',
      });
      expect(center.image, '');
      expect(center.averageRating, 0);
      expect(center.totalReviews, 0);
      expect(center.area, '');
    });

    test('coerces an int averageRating to double', () {
      final center = TopCenter.fromJson(<String, dynamic>{
        '_id': 'c3',
        'name': 'IntRating',
        'city': 'Mumbai',
        'averageRating': 4,
      });
      expect(center.averageRating, 4.0);
    });
  });
}
