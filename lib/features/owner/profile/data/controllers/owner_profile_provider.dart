/// OwnerProfileState, OwnerProfileController (StateNotifier), and Riverpod
/// providers for the owner profile read / edit / change-password feature. The
/// single source of truth the owner profile screen + edit form watch. Mirrors
/// `student_profile_provider.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider, tokenStorageProvider;
import '../models/owner_profile_model.dart';
import '../models/owner_profile_update.dart';
import '../repository/owner_profile_remote_datasource.dart';
import '../repository/owner_profile_repository.dart';

/// Discrete states the profile can be in.
enum OwnerProfileStatus { initial, loading, data, error }

/// Snapshot consumed by the profile screen + edit form.
class OwnerProfileState {
  /// Creates a state.
  const OwnerProfileState({
    this.status = OwnerProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  /// Current step in the profile fetch / mutation.
  final OwnerProfileStatus status;

  /// The loaded profile, or null before the first successful fetch.
  final OwnerProfile? profile;

  /// User-safe error string, when [status] is `error` (or after a failed
  /// mutation).
  final String? errorMessage;

  /// True while a fetch / mutation is in flight.
  bool get isLoading => status == OwnerProfileStatus.loading;

  /// True once the profile has loaded at least once.
  bool get hasData => profile != null;

  /// Field-wise copy. `profile` and `errorMessage` deliberately REPLACE (not
  /// fall back) so callers can clear the error by passing `errorMessage: null`.
  OwnerProfileState copyWith({
    OwnerProfileStatus? status,
    OwnerProfile? profile,
    String? errorMessage,
  }) {
    return OwnerProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }
}

/// Holds the [OwnerProfileState], fetches the profile on construction, and
/// exposes the save + change-password mutations.
class OwnerProfileController extends StateNotifier<OwnerProfileState> {
  /// Creates the controller and fires the initial load.
  OwnerProfileController(this._repository) : super(const OwnerProfileState()) {
    load();
  }

  final OwnerProfileRepository _repository;

  /// Guards [load] against overlapping calls.
  bool _loadInFlight = false;

  /// Fetches the profile via `GET /auth/me`. Loading → Data, or → Error.
  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(
      status: OwnerProfileStatus.loading,
      errorMessage: null,
    );
    try {
      final OwnerProfile profile = await _repository.fetch();
      state = state.copyWith(
        status: OwnerProfileStatus.data,
        profile: profile,
      );
    } on OwnerProfileException catch (e) {
      state = state.copyWith(
        status: OwnerProfileStatus.error,
        errorMessage: e.message,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  /// Applies a strict partial [update] via `PATCH /owners/me`. Returns `true`
  /// on success (UI pops + snackbars); on failure keeps the profile, sets
  /// [OwnerProfileState.errorMessage], and returns `false`. An empty update
  /// short-circuits to `true`.
  Future<bool> save(OwnerProfileUpdate update) async {
    if (update.isEmpty) return true;
    state = state.copyWith(
      status: OwnerProfileStatus.loading,
      errorMessage: null,
    );
    try {
      final OwnerProfile updated = await _repository.update(update);
      state = state.copyWith(
        status: OwnerProfileStatus.data,
        profile: updated,
      );
      return true;
    } on OwnerProfileException catch (e) {
      state = state.copyWith(
        status: state.profile != null
            ? OwnerProfileStatus.data
            : OwnerProfileStatus.error,
        errorMessage: e.message,
      );
      return false;
    }
  }

  /// Changes the password via `POST /owners/me/password`. Returns `true` on
  /// success; on failure returns `false` and sets [OwnerProfileState.errorMessage]
  /// to the backend's verbatim message.
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
    } on OwnerProfileException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }
}

/// Composes the [OwnerProfileRemoteDataSource] from the shared [apiClientProvider].
final Provider<OwnerProfileRemoteDataSource>
    ownerProfileRemoteDataSourceProvider =
    Provider<OwnerProfileRemoteDataSource>(
  (ref) => OwnerProfileRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the controller consumes. Reuses the shared
/// [tokenStorageProvider] so a password change can persist the re-issued tokens.
final Provider<OwnerProfileRepository> ownerProfileRepositoryProvider =
    Provider<OwnerProfileRepository>(
  (ref) => OwnerProfileRepository(
    ref.read(ownerProfileRemoteDataSourceProvider),
    ref.read(tokenStorageProvider),
  ),
);

/// The shared profile state — watched by the profile screen + edit form. Fires
/// a fetch on first read.
final StateNotifierProvider<OwnerProfileController, OwnerProfileState>
    ownerProfileControllerProvider =
    StateNotifierProvider<OwnerProfileController, OwnerProfileState>(
  (ref) => OwnerProfileController(ref.watch(ownerProfileRepositoryProvider)),
);
