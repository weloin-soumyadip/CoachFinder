/// Repository owning center create / update / delete operations. Translates
/// transport failures into a feature-specific [ManageCenterException] the
/// controllers catch. Currently covers the create path only.
library;

import '../../../../../core/api/api_error.dart';
import '../models/center_create_request.dart';
import '../models/center_update.dart';
import '../models/owner_center.dart';
import '../models/subject_option.dart';
import 'manage_center_remote_datasource.dart';

/// Feature-specific exception thrown by [ManageCenterRepository] on failure.
/// Mirrors `OwnerDashboardException` / `AuthException`. The controller catches
/// this and surfaces [message] (the backend's verbatim `message` where
/// available — e.g. the `409` "You already have a coaching center").
class ManageCenterException implements Exception {
  /// Creates the exception with a user-safe [message] and optional [code].
  ManageCenterException(this.message, {this.code});

  /// User-safe failure message — the backend's `message` where available, else
  /// a plain fallback.
  final String message;

  /// Optional sentinel (HTTP status code as string, or `'NETWORK_ERROR'` /
  /// `'TIMEOUT'` / `'UNKNOWN'`).
  final String? code;

  @override
  String toString() => message;
}

/// Concrete repository owning the center mutations. Throws a
/// [ManageCenterException] on any failure.
class ManageCenterRepository {
  /// Wraps the [ManageCenterRemoteDataSource].
  ManageCenterRepository(this._remote);

  final ManageCenterRemoteDataSource _remote;

  /// Creates the owner's center via `POST /api/centers`. Surfaces the backend's
  /// `message` (e.g. the `409` when one already exists) verbatim.
  Future<void> create(CenterCreateRequest request) {
    return _guard(
      () => _remote.createCenter(request),
      'Something went wrong while creating your center',
    );
  }

  /// The owner's coaching center via `GET /api/centers/me`, or null when they
  /// have none (`404`). Any other failure surfaces as a [ManageCenterException].
  /// Backs the owner-setup gate, the dashboard header's centre name, and the
  /// Manage-Center read view + edit form (the full doc is cheap to parse).
  Future<OwnerCenter?> getMine() async {
    try {
      final Map<String, dynamic>? json = await _remote.fetchMine();
      if (json == null) return null;
      return OwnerCenter.fromJson(json);
    } on ApiError catch (e) {
      if (e.statusCode == 404) return null;
      throw ManageCenterException(e.message, code: e.statusCode?.toString());
    }
  }

  /// Whether the owner already has a coaching center (`200` → true, `404` →
  /// false). Used by the owner-setup gate to decide between the dashboard and
  /// the create wizard.
  Future<bool> hasCenter() async => (await getMine()) != null;

  /// Applies a strict-partial [update] via `PATCH /api/centers/:id` and returns
  /// the updated [OwnerCenter]. Surfaces the backend `message` (e.g. the `403`
  /// "Not your coaching center") verbatim.
  Future<OwnerCenter> update(String id, CenterUpdate update) {
    return _guard(
      () async {
        final Map<String, dynamic> json =
            await _remote.updateCenter(id, update.toJson());
        return OwnerCenter.fromJson(json);
      },
      'Something went wrong while saving your center',
    );
  }

  /// The subject options for the centre multi-select (`GET /api/subjects`).
  Future<List<SubjectOption>> fetchSubjects() {
    return _guard(
      () async {
        final List<Map<String, dynamic>> rows = await _remote.fetchSubjects();
        return rows.map(SubjectOption.fromJson).toList();
      },
      'Could not load subjects',
    );
  }

  /// Runs [task], translating [ApiError] (and unexpected throwables) into a
  /// [ManageCenterException] with a user-safe [fallback] message.
  Future<T> _guard<T>(Future<T> Function() task, String fallback) async {
    try {
      return await task();
    } on ApiError catch (e) {
      throw ManageCenterException(e.message, code: e.statusCode?.toString());
    } on ManageCenterException {
      rethrow;
    } catch (_) {
      throw ManageCenterException(fallback);
    }
  }
}
