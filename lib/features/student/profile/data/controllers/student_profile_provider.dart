/// StudentProfileState, StudentProfileController (StateNotifier), and Riverpod
/// providers for the student profile read / edit feature. The single source of
/// truth the profile screen + edit form watch. Mirrors `bookmarks_provider.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider, tokenStorageProvider;
import '../models/student_profile_model.dart';
import '../models/student_profile_update.dart';
import '../repository/student_profile_remote_datasource.dart';
import '../repository/student_profile_repository.dart';

/// Discrete states the profile can be in.
enum StudentProfileStatus { initial, loading, data, error }

/// Snapshot consumed by the profile screen + edit form.
class StudentProfileState {
  const StudentProfileState({
    this.status = StudentProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  /// Current step in the profile fetch / mutation.
  final StudentProfileStatus status;

  /// The loaded profile, or null before the first successful fetch.
  final StudentProfile? profile;

  /// User-safe error string, when [status] is `error` (or after a failed
  /// mutation). Surfaced as a snackbar / inline message.
  final String? errorMessage;

  /// True while a fetch / mutation is in flight.
  bool get isLoading => status == StudentProfileStatus.loading;

  /// True once the profile has loaded at least once.
  bool get hasData => profile != null;

  /// Field-wise copy. `profile` and `errorMessage` deliberately REPLACE (not
  /// fall back) so callers can clear the error by passing `errorMessage: null`.
  StudentProfileState copyWith({
    StudentProfileStatus? status,
    StudentProfile? profile,
    String? errorMessage,
  }) {
    return StudentProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }
}

/// Holds the [StudentProfileState], fetches the profile on construction, and
/// exposes the save + change-password mutations. The screen + edit form watch
/// the same provider so the read view and form can't drift.
class StudentProfileController extends StateNotifier<StudentProfileState> {
  StudentProfileController(this._repository)
      : super(const StudentProfileState()) {
    // Fire-and-forget initial load when the provider is first read.
    load();
  }

  final StudentProfileRepository _repository;

  /// Guards [load] against overlapping calls.
  bool _loadInFlight = false;

  /// Fetches the profile via `GET /auth/me`. Loading → Data, or → Error with
  /// the backend's verbatim message. Re-entrant calls are ignored while a fetch
  /// is already running.
  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(
      status: StudentProfileStatus.loading,
      errorMessage: null,
    );
    try {
      final StudentProfile profile = await _repository.fetch();
      state = state.copyWith(
        status: StudentProfileStatus.data,
        profile: profile,
      );
    } on StudentProfileException catch (e) {
      state = state.copyWith(
        status: StudentProfileStatus.error,
        errorMessage: e.message,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  /// Applies a strict partial [update] via `PATCH /students/me`. On success the
  /// held profile is replaced with the doc the backend echoes back and the
  /// method returns `true` (the UI pops + snackbars). On failure the state keeps
  /// the existing profile, sets [StudentProfileState.errorMessage], and returns
  /// `false` (the UI stays on the form + snackbars the error).
  ///
  /// An empty [update] (nothing changed) short-circuits to `true` without a
  /// round-trip — the backend rejects an empty body, and "no changes" is a
  /// success from the user's point of view.
  Future<bool> save(StudentProfileUpdate update) async {
    if (update.isEmpty) return true;
    state = state.copyWith(
      status: StudentProfileStatus.loading,
      errorMessage: null,
    );
    try {
      final StudentProfile updated = await _repository.update(update);
      state = state.copyWith(
        status: StudentProfileStatus.data,
        profile: updated,
      );
      return true;
    } on StudentProfileException catch (e) {
      // Keep the loaded profile; just flag the error so the form can recover.
      state = state.copyWith(
        status: state.profile != null
            ? StudentProfileStatus.data
            : StudentProfileStatus.error,
        errorMessage: e.message,
      );
      return false;
    }
  }

  /// Changes the password via `POST /students/me/password`. Returns `true` on
  /// success; on failure returns `false` and sets [StudentProfileState.errorMessage]
  /// to the backend's verbatim message (e.g. `Invalid current password`) so the
  /// UI can surface it. The held profile is never touched by this call.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on StudentProfileException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }
}

/// Composes the [StudentProfileRemoteDataSource] from the shared
/// [apiClientProvider].
final Provider<StudentProfileRemoteDataSource>
    studentProfileRemoteDataSourceProvider =
    Provider<StudentProfileRemoteDataSource>(
  (ref) => StudentProfileRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the controller consumes. Reuses the shared
/// [tokenStorageProvider] (same secure-storage instance as the auth layer) so a
/// password change can persist the re-issued tokens and keep the session alive.
final Provider<StudentProfileRepository> studentProfileRepositoryProvider =
    Provider<StudentProfileRepository>(
  (ref) => StudentProfileRepository(
    ref.read(studentProfileRemoteDataSourceProvider),
    ref.read(tokenStorageProvider),
  ),
);

/// The shared profile state — watched by the profile screen + edit form. Fires
/// a fetch on first read.
final StateNotifierProvider<StudentProfileController, StudentProfileState>
    studentProfileControllerProvider =
    StateNotifierProvider<StudentProfileController, StudentProfileState>(
  (ref) =>
      StudentProfileController(ref.watch(studentProfileRepositoryProvider)),
);
