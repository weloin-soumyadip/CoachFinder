/// Constants for Hive box names and key strings used across storage layers.
library;

/// Box names and key strings used by Hive. Centralised to keep magic strings
/// out of the rest of the codebase.
abstract final class HiveKeys {
  HiveKeys._();

  // Box names
  static const String boxSettings = 'settings';
  static const String boxAuth = 'auth';
  static const String boxCache = 'cache';

  // Keys inside [boxSettings]
  static const String keyUserRole = 'user_role';
  static const String keyThemeMode = 'theme_mode';

  // Keys inside [boxAuth]
  static const String keyJwtToken = 'jwt_token';
  static const String keyCurrentUser = 'current_user';
}
