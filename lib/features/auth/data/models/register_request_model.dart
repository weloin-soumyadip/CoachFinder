/// Request body for `POST /api/auth/register`.
library;

/// Serialises the form's fields into the JSON shape the backend expects.
/// `userType` is one of `'student'`, `'owner'`, `'teacher'` (matches the
/// project's role constants in `core/providers/role_provider.dart`).
class RegisterRequest {
  const RegisterRequest({
    required this.userType,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  /// One of `'student'`, `'owner'`, `'teacher'`. The backend rejects
  /// `'admin'` with a 400.
  final String userType;

  /// Full name (single string). Caller is responsible for trimming /
  /// concatenating first + last name where applicable.
  final String name;

  /// Lower-cased email. Caller trims + lowercases before constructing.
  final String email;

  /// Plaintext password — the backend bcrypt-hashes before storage.
  final String password;

  /// Optional phone. Omitted from JSON entirely when null or empty.
  final String? phone;

  /// Backend-shaped JSON body.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userType': userType,
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
    };
  }
}
