/// Concrete AuthRepository talking to the backend via ApiClient.
library;

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/api/api_error.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/auth_response_model.dart';
import '../models/register_request_model.dart';

/// Feature-specific exception thrown by [AuthRepository] on failure.
/// Controllers catch this and translate to [AuthState.error].
class AuthException implements Exception {
  AuthException(this.message, {this.code});

  /// User-safe failure message — already the backend's `message` field where
  /// available.
  final String message;

  /// Optional sentinel (HTTP status code as string, or `'NETWORK_ERROR'` /
  /// `'TIMEOUT'` / `'UNKNOWN'`).
  final String? code;

  @override
  String toString() => message;
}

/// Single concrete repository owning every auth operation. Throws
/// [AuthException] on failure. Persists tokens via [TokenStorage] on success.
class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Calls `POST /api/auth/register` and persists the returned tokens.
  /// Returns the parsed [AuthResponse] (including the new [User]).
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final dioResponse = await _apiClient.rawPost(
        ApiConfig.authRegister,
        data: request.toJson(),
      );
      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        dioResponse.data ?? <String, dynamic>{},
        (json) => AuthResponse.fromJson(json),
      );
      if (!apiResponse.success || apiResponse.data == null) {
        throw AuthException(apiResponse.message ?? 'Failed to register');
      }
      final authResponse = apiResponse.data!;
      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      return authResponse;
    } on ApiError catch (e) {
      throw AuthException(e.message, code: e.statusCode?.toString());
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException('Something went wrong while signing up');
    }
  }

  /// True iff a non-empty access token is cached locally. Does not verify
  /// against the server.
  Future<bool> isAuthenticated() => _tokenStorage.isTokenValid();

  /// Returns the cached access token, or null when none is present.
  Future<String?> getAccessToken() => _tokenStorage.getAccessToken();

  /// Local-only sign-out: clears the cached tokens. (The server's `/logout`
  /// is wired in a later round.)
  Future<void> logout() => _tokenStorage.clearTokens();
}
