/// Tests for [CenterCreateRequest.toJson] — it must emit the strict create body
/// `POST /api/centers` expects: the required fields, an optional description,
/// and the server-mandated default GeoJSON location.
library;

import 'package:coachfinder/features/owner/manage_center/data/models/center_create_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CenterCreateRequest.toJson', () {
    test('emits the required fields plus the default location', () {
      const request = CenterCreateRequest(
        name: 'Bright Minds',
        address: '12 MG Road',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001',
        phone: '9876543210',
      );

      expect(request.toJson(), <String, dynamic>{
        'name': 'Bright Minds',
        'address': '12 MG Road',
        'city': 'Pune',
        'state': 'Maharashtra',
        'pincode': '411001',
        'phone': '9876543210',
        'location': <String, dynamic>{
          'type': 'Point',
          'coordinates': CenterCreateRequest.defaultCoordinates,
        },
      });
    });

    test('includes description when present and non-empty', () {
      const request = CenterCreateRequest(
        name: 'Bright Minds',
        address: '12 MG Road',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001',
        phone: '9876543210',
        description: '  Top-rated NEET coaching  ',
      );

      // Trimmed.
      expect(request.toJson()['description'], 'Top-rated NEET coaching');
    });

    test('omits description when null', () {
      const request = CenterCreateRequest(
        name: 'Bright Minds',
        address: '12 MG Road',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001',
        phone: '9876543210',
      );

      expect(request.toJson().containsKey('description'), isFalse);
    });

    test('omits description when blank / whitespace-only', () {
      const request = CenterCreateRequest(
        name: 'Bright Minds',
        address: '12 MG Road',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001',
        phone: '9876543210',
        description: '   ',
      );

      expect(request.toJson().containsKey('description'), isFalse);
    });

    test('default coordinates are ordered [longitude, latitude]', () {
      // GeoJSON ordering is [lng, lat]; India centroid ≈ (78.96 E, 20.59 N).
      expect(
          CenterCreateRequest.defaultCoordinates, <double>[78.9629, 20.5937]);
      final List<dynamic> coords = (CenterCreateRequest(
        name: 'X',
        address: 'Y',
        city: 'Z',
        state: 'S',
        pincode: '1',
        phone: '9876543210',
      ).toJson()['location'] as Map<String, dynamic>)['coordinates']
          as List<dynamic>;
      expect(coords.first, greaterThan(coords.last)); // lng (78) > lat (20)
    });
  });
}
