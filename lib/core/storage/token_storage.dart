/// Secure-storage wrapper for the access and refresh JWTs.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the auth tokens in platform secure storage (Keychain on iOS,
/// EncryptedSharedPreferences on Android, `libsecret` on Linux). Mirrors the
/// pattern used in the user's other Flutter project.
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Writes the access token.
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  /// Returns the cached access token, or null when none is present.
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  /// Writes the refresh token.
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  /// Returns the cached refresh token, or null when none is present.
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// Persists both tokens in one call. Refresh token is optional — when null
  /// the existing refresh value is left untouched.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  /// Deletes both tokens. Called on logout or 401 reuse.
  Future<void> clearTokens() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  /// Best-effort "is logged in" check. Returns true iff an access token is
  /// present and non-empty. Does not verify against the server; the next
  /// protected call will 401-and-clear if the token has actually expired.
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// True iff an access token is present (may be empty / invalid).
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null;
  }
}
