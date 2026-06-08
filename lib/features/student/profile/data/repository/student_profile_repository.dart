/// Repository owning the student profile operations (fetch / update /
/// change-password). Translates [ApiError] into a feature-specific
/// [StudentProfileException]. Mirrors `BookmarksException` / `SearchException`.
library;

import '../../../../../core/api/api_error.dart';
import '../../../../../core/storage/token_storage.dart';
import '../models/student_profile_model.dart';
import '../models/student_profile_update.dart';
import 'student_profile_remote_datasource.dart';

/// Feature-specific exception thrown by [StudentProfileRepository] on failure.
/// Controllers catch this and translate to an error state.
class StudentProfileException implements Exception {
  StudentProfileException(this.message, {this.code});

  /// User-safe failure message — the backend's `message` field where available
  /// (e.g. `Invalid current password` on a wrong-password change), or a
  /// repository fallback otherwise.
  final String message;

  /// Optional sentinel (HTTP status code as string, or `'NETWORK_ERROR'` /
  /// `'TIMEOUT'` / `'UNKNOWN'`).
  final String? code;

  @override
  String toString() => message;
}

/// Concrete repository owning the three profile calls. Each throws a
/// [StudentProfileException] on failure.
class StudentProfileRepository {
  StudentProfileRepository(this._remote, this._tokenStorage);

  final StudentProfileRemoteDataSource _remote;

  /// Shared secure token store (the same instance the auth layer uses) — the
  /// repository persists the re-issued tokens here after a password change.
  final TokenStorage _tokenStorage;

  /// Fetches the caller's profile via `GET /auth/me`.
  Future<StudentProfile> fetch() {
    return _guard(
      _remote.fetch,
      'Something went wrong while loading your profile',
    );
  }

  /// Applies a strict partial [update] via `PATCH /students/me`, returning the
  /// updated profile the backend echoes back.
  Future<StudentProfile> update(StudentProfileUpdate update) {
    return _guard(
      () => _remote.update(update),
      'Something went wrong while saving your profile',
    );
  }

  /// Changes the password via `POST /students/me/password`. The backend revokes
  /// every existing refresh token and re-issues a fresh pair, so on success we
  /// persist the new tokens to secure storage BEFORE returning — otherwise the
  /// dead access/refresh tokens would 401 (and fail to refresh) on the very next
  /// request and bounce the user to login. When the body omits either token we
  /// skip persistence and still report success. A wrong current password
  /// surfaces the backend's verbatim `message` (e.g. `Invalid current password`)
  /// on the thrown [StudentProfileException].
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

  /// Runs [task], translating [ApiError] (and unexpected throwables) into a
  /// [StudentProfileException] with the backend's `message`, or a user-safe
  /// [fallback] when none is available.
  Future<T> _guard<T>(Future<T> Function() task, String fallback) async {
    try {
      return await task();
    } on ApiError catch (e) {
      throw StudentProfileException(e.message, code: e.statusCode?.toString());
    } on StudentProfileException {
      rethrow;
    } catch (_) {
      throw StudentProfileException(fallback);
    }
  }
}
