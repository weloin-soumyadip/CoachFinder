/// Centralised backend URL strings (paths and the dev base URL).
library;

/// Backend HTTP API base URL and endpoint paths.
///
/// `baseUrl` resolves to the host machine from inside an Android emulator. For
/// the iOS simulator and physical devices it will need a different URL - that
/// switch is out of scope for Phase 1 (see decision 0002).
abstract final class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Auth (paths to be confirmed when the backend contract is shared)
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';

  // Per-feature endpoint constants get added when each feature is implemented.
}
