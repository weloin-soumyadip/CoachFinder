/// Hard-coded developer test credentials for the debug-only sign-in bypass.
library;

/// Debug-only test account used to enter the app while real auth is unbuilt.
///
/// The sign-in logic recognises these exact credentials **only in debug builds**
/// (`kDebugMode`); in release builds they are ignored. This lets the UI be
/// exercised end-to-end without a backend. Remove together with the
/// `TODO(real-auth)` shortcuts once real authentication lands.
abstract final class DevCredentials {
  DevCredentials._();

  /// Email that signs in as the debug test user.
  static const String testEmail = 'test@gmail.com';

  /// Password that signs in as the debug test user.
  static const String testPassword = 'test-password';
}
