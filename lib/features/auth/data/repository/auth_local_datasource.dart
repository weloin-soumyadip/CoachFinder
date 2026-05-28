/// Hive reads and writes for the JWT token, refresh token, cached user, and
/// active role.
library;

import 'dart:convert';

import '../../../../core/constants/hive_keys.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/user_model.dart';

/// Tiny value class composing the four pieces of session state that move
/// together: the access JWT, refresh JWT, the user, and the role. Lives next
/// to the local data source because it's the natural unit of persistence.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.role,
  });

  /// Access JWT (sent as `Authorization: Bearer ...`).
  final String accessToken;

  /// Refresh JWT (used by future `/auth/refresh` rotations).
  final String refreshToken;

  /// The authenticated user.
  final User user;

  /// `'student'` / `'owner'` / `'teacher'`.
  final String role;
}

/// Contract for the local persistence layer of the auth feature.
abstract interface class AuthLocalDataSource {
  /// Persists [session] to Hive: token + refresh + user JSON to `boxAuth`,
  /// role to `boxSettings`.
  Future<void> saveSession(AuthSession session);

  /// Clears `keyJwtToken`, `keyRefreshToken`, and `keyCurrentUser` from
  /// `boxAuth`. The role is preserved so re-login lands on the same shell.
  Future<void> clearSession();

  /// Returns the cached session, or null when any of token / refresh / user
  /// / role are missing. Used by [AuthNotifier.build] to hydrate startup
  /// state without a `/me` round-trip.
  AuthSession? readSession();
}

/// `HiveService`-backed implementation.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._hive);

  final HiveService _hive;

  @override
  Future<void> saveSession(AuthSession session) async {
    await _hive.authBox.put(HiveKeys.keyJwtToken, session.accessToken);
    await _hive.authBox.put(HiveKeys.keyRefreshToken, session.refreshToken);
    await _hive.authBox.put(
      HiveKeys.keyCurrentUser,
      jsonEncode(session.user.toJson()),
    );
    await _hive.settingsBox.put(HiveKeys.keyUserRole, session.role);
  }

  @override
  Future<void> clearSession() async {
    await _hive.authBox.delete(HiveKeys.keyJwtToken);
    await _hive.authBox.delete(HiveKeys.keyRefreshToken);
    await _hive.authBox.delete(HiveKeys.keyCurrentUser);
  }

  @override
  AuthSession? readSession() {
    final String? token = _hive.authBox.get(HiveKeys.keyJwtToken) as String?;
    final String? refresh =
        _hive.authBox.get(HiveKeys.keyRefreshToken) as String?;
    final String? userRaw =
        _hive.authBox.get(HiveKeys.keyCurrentUser) as String?;
    final String? role = _hive.settingsBox.get(HiveKeys.keyUserRole) as String?;
    if (token == null ||
        refresh == null ||
        userRaw == null ||
        role == null ||
        token.isEmpty ||
        refresh.isEmpty ||
        userRaw.isEmpty ||
        role.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(userRaw) as Map<String, dynamic>;
      return AuthSession(
        accessToken: token,
        refreshToken: refresh,
        user: User.fromCache(decoded),
        role: role,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
