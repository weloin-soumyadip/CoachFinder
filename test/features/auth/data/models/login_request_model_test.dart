import 'package:coachfinder/features/auth/data/models/login_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginRequest.toJson', () {
    test('serialises all three required fields', () {
      const request = LoginRequest(
        userType: 'owner',
        email: 'alice@x.com',
        password: 'secret123',
      );
      expect(request.toJson(), <String, dynamic>{
        'userType': 'owner',
        'email': 'alice@x.com',
        'password': 'secret123',
      });
    });

    test('uses the userType verbatim — no admin filtering at the model layer',
        () {
      const request = LoginRequest(
        userType: 'student',
        email: 's@x.com',
        password: 'p1234567',
      );
      expect(request.toJson()['userType'], 'student');
    });

    test('does not include name or phone keys', () {
      const request = LoginRequest(
        userType: 'teacher',
        email: 't@x.com',
        password: 'p1234567',
      );
      final json = request.toJson();
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('phone'), isFalse);
    });
  });
}
