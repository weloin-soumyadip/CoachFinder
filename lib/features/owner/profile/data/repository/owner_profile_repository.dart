/// Repository owning the owner profile operations (fetch / update /
/// change-password). Translates [ApiError] into a feature-specific
/// [OwnerProfileException]. Mirrors `StudentProfileRepository`.
library;

import '../../../../../core/api/api_error.dart';
import '../../../../../core/storage/token_storage.dart';
import '../models/owner_profile_model.dart';
import '../models/owner_profile_update.dart';
import 'owner_profile_remote_datasource.dart';

/// Feature-specific exception thrown by [OwnerProfileRepository] on failure.
class OwnerProfileException implements Exception {
  /// Creates the exception.
  OwnerProfileException(this.message, {this.code});

  /// User-safe failure message — the backend's `message` where available
  /// (e.g. `Invalid current password`), or a repository fallback otherwise.
  final String message;

  /// Optional sentinel (HTTP status code as string).
  final String? code;

  @override
  String toString() => message;
}

/// Concrete repository owning the three owner profile calls. Each throws an
/// [OwnerProfileException] on failure.
class OwnerProfileRepository {
  /// Wraps the datasource + the shared secure token store.
  OwnerProfileRepository(this._remote, this._tokenStorage);

  final OwnerProfileRemoteDataSource _remote;

  /// Shared secure token store — the repository persists the re-issued tokens
  /// here after a password change so the session survives the revocation.
  final TokenStorage _tokenStorage;

  /// Fetches the owner's profile via `GET /auth/me`.
  Future<OwnerProfile> fetch() {
    return _guard(
      _remote.fetch,
      'Something went wrong while loading your profile',
    );
  }

  /// Applies a strict partial [update] via `PATCH /owners/me`, returning the
  /// updated profile the backend echoes back.
  Future<OwnerProfile> update(OwnerProfileUpdate update) {
    return _guard(
      () => _remote.update(update),
      'Something went wrong while saving your profile',
    );
  }

  /// Changes the password via `POST /owners/me/password`. The backend revokes
  /// every existing refresh token and re-issues a fresh pair, so on success we
  /// persist the new tokens BEFORE returning — otherwise the dead tokens would
  /// 401 on the next request and bounce the owner to login. A wrong current
  /// password surfaces the backend's verbatim `message`.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _guard(
      () async {
        final PasswordChangeTokens tokens = await _remote.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        final String? accessToken = tokens.accessToken;
        if (accessToken != null && accessToken.isNotEmpty) {
          await _tokenStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: tokens.refreshToken,
          );
        }
      },
      'Something went wrong while changing your password',
    );
  }

  /// Runs [task], translating [ApiError] (and unexpected throwables) into an
  /// [OwnerProfileException] with the backend's `message`, or a [fallback].
  Future<T> _guard<T>(Future<T> Function() task, String fallback) async {
    try {
      return await task();
    } on ApiError catch (e) {
      throw OwnerProfileException(e.message, code: e.statusCode?.toString());
    } on OwnerProfileException {
      rethrow;
    } catch (_) {
      throw OwnerProfileException(fallback);
    }
  }
}
