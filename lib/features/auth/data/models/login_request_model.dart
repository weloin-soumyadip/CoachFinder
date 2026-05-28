/// Request body for `POST /api/auth/login`.
library;

/// Serialises the login form's fields into the JSON shape the backend expects.
/// `userType` is one of `'student'`, `'owner'`, `'teacher'` (matches the
/// project's role constants in `core/providers/role_provider.dart`).
class LoginRequest {
  const LoginRequest({
    required this.userType,
    required this.email,
    required this.password,
  });

  /// One of `'student'` / `'owner'` / `'teacher'`. The app never sends
  /// `'admin'`; admins log in through a separate flow not yet implemented.
  final String userType;

  /// Lower-cased email. Caller trims + lowercases before constructing.
  final String email;

  /// Plaintext password — the backend bcrypt-compares against the stored hash.
  final String password;

  /// Backend-shaped JSON body.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'userType': userType,
        'email': email,
        'password': password,
      };
}
