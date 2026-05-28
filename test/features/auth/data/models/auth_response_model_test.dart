import 'package:coachfinder/features/auth/data/models/auth_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthResponse.fromJson parses accessToken / refreshToken / user', () {
    final response = AuthResponse.fromJson(<String, dynamic>{
      'success': true,
      'accessToken': 'access.jwt.value',
      'refreshToken': 'refresh.jwt.value',
      'user': <String, dynamic>{
        '_id': 'u1',
        'name': 'Alice',
        'email': 'a@x.com',
        'phone': null,
        'profileImage': '',
        'isActive': true,
        'isEmailVerified': false,
        'createdAt': '2026-05-28T10:00:00.000Z',
        'updatedAt': '2026-05-28T10:00:00.000Z',
      },
    });
    expect(response.accessToken, 'access.jwt.value');
    expect(response.refreshToken, 'refresh.jwt.value');
    expect(response.user.id, 'u1');
    expect(response.user.email, 'a@x.com');
  });
}
