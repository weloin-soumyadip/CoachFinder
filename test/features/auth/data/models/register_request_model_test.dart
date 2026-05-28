import 'package:coachfinder/features/auth/data/models/register_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegisterRequest.toJson', () {
    test('serialises required fields and omits null phone', () {
      const request = RegisterRequest(
        userType: 'owner',
        name: 'Alice',
        email: 'alice@x.com',
        password: 'secret123',
      );
      expect(request.toJson(), <String, dynamic>{
        'userType': 'owner',
        'name': 'Alice',
        'email': 'alice@x.com',
        'password': 'secret123',
      });
    });

    test('includes phone when non-empty', () {
      const request = RegisterRequest(
        userType: 'student',
        name: 'Bob',
        email: 'b@x.com',
        password: 'p1234567',
        phone: '+1234',
      );
      expect(request.toJson()['phone'], '+1234');
    });

    test('omits phone when empty string', () {
      const request = RegisterRequest(
        userType: 'teacher',
        name: 'Cara',
        email: 'c@x.com',
        password: 'p1234567',
        phone: '',
      );
      expect(request.toJson().containsKey('phone'), isFalse);
    });
  });
}
