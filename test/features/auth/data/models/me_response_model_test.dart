import 'package:coachfinder/features/auth/data/models/me_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeResponse.fromJson', () {
    test('parses {success, userType, user} from the /me envelope', () {
      final response = MeResponse.fromJson(<String, dynamic>{
        'success': true,
        'userType': 'owner',
        'user': <String, dynamic>{
          '_id': 'abc123',
          'name': 'Soumya',
          'email': 'soumya@example.com',
          'isActive': true,
          'isEmailVerified': false,
          'createdAt': '2026-05-28T10:00:00.000Z',
          'updatedAt': '2026-05-28T10:00:00.000Z',
        },
      });
      expect(response.userType, 'owner');
      expect(response.user.id, 'abc123');
      expect(response.user.name, 'Soumya');
      expect(response.user.email, 'soumya@example.com');
    });

    test('accepts the three registerable userTypes verbatim', () {
      for (final type in <String>['owner', 'teacher', 'student']) {
        final response = MeResponse.fromJson(<String, dynamic>{
          'userType': type,
          'user': <String, dynamic>{
            '_id': 'x',
            'name': 'n',
            'email': 'n@x.com',
            'isActive': true,
            'isEmailVerified': false,
            'createdAt': '2026-05-28T10:00:00.000Z',
            'updatedAt': '2026-05-28T10:00:00.000Z',
          },
        });
        expect(response.userType, type);
      }
    });

    test('parses userType: admin (backend can return it; controller filters)',
        () {
      // The backend's UserType enum includes 'admin' (see
      // server/src/lib/auth/jwt.ts), and `/me` returns it verbatim. The
      // model is intentionally permissive — the role gate lives in
      // AuthController.bootstrap, not here.
      final response = MeResponse.fromJson(<String, dynamic>{
        'userType': 'admin',
        'user': <String, dynamic>{
          '_id': 'admin-1',
          'name': 'Super Admin',
          'email': 'admin@example.com',
          'isActive': true,
          'isEmailVerified': true,
          'createdAt': '2026-05-28T10:00:00.000Z',
          'updatedAt': '2026-05-28T10:00:00.000Z',
        },
      });
      expect(response.userType, 'admin');
    });
  });
}
