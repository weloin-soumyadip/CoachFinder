/// CreateCenterState, CreateCenterController (StateNotifier), and the Riverpod
/// providers for the first-time center-creation flow. The CreateCenterScreen
/// watches [createCenterControllerProvider] and calls [submit]; on success the
/// dashboard re-fetches and flips from its "no center" CTA to live stats.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider;
import '../models/center_create_request.dart';
import '../repository/manage_center_remote_datasource.dart';
import '../repository/manage_center_repository.dart';

/// Discrete states the create-center submission can be in.
enum CreateCenterStatus { idle, submitting, success, error }

/// Immutable snapshot consumed by the CreateCenterScreen.
class CreateCenterState {
  /// Creates a create-center state.
  const CreateCenterState({
    this.status = CreateCenterStatus.idle,
    this.errorMessage,
  });

  /// Current step in the submission.
  final CreateCenterStatus status;

  /// User-safe error string, when [status] is `error` (the backend's verbatim
  /// `message` where available — e.g. the `409` already-exists message).
  final String? errorMessage;

  /// True while a submission is in flight.
  bool get isSubmitting => status == CreateCenterStatus.submitting;

  /// Field-wise copy. `errorMessage` deliberately REPLACES (not falls back) so
  /// callers can clear it by passing `errorMessage: null`.
  CreateCenterState copyWith({
    CreateCenterStatus? status,
    String? errorMessage,
  }) {
    return CreateCenterState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// Holds the [CreateCenterState] and exposes the single [submit] mutation.
class CreateCenterController extends StateNotifier<CreateCenterState> {
  /// Creates the controller over the [ManageCenterRepository].
  CreateCenterController(this._repository) : super(const CreateCenterState());

  final ManageCenterRepository _repository;

  /// Creates the center via `POST /api/centers`. Returns `true` on success
  /// (the UI pops + the dashboard reloads). On failure returns `false`, sets
  /// [CreateCenterState.errorMessage] to the backend's verbatim message, and
  /// the UI stays on the form to surface it.
  Future<bool> submit(CenterCreateRequest request) async {
    state = state.copyWith(
      status: CreateCenterStatus.submitting,
      errorMessage: null,
    );
    try {
      await _repository.create(request);
      state = state.copyWith(status: CreateCenterStatus.success);
      return true;
    } on ManageCenterException catch (e) {
      state = state.copyWith(
        status: CreateCenterStatus.error,
        errorMessage: e.message,
      );
      return false;
    }
  }
}

/// Composes the [ManageCenterRemoteDataSource] from the shared
/// [apiClientProvider].
final Provider<ManageCenterRemoteDataSource>
    manageCenterRemoteDataSourceProvider =
    Provider<ManageCenterRemoteDataSource>(
  (ref) => ManageCenterRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the create-center controller consumes.
final Provider<ManageCenterRepository> manageCenterRepositoryProvider =
    Provider<ManageCenterRepository>(
  (ref) => ManageCenterRepository(
    ref.read(manageCenterRemoteDataSourceProvider),
  ),
);

/// The create-center state the CreateCenterScreen watches. Starts idle (no
/// fetch on construction — this is a write-only flow).
final StateNotifierProvider<CreateCenterController, CreateCenterState>
    createCenterControllerProvider =
    StateNotifierProvider<CreateCenterController, CreateCenterState>(
  (ref) => CreateCenterController(ref.watch(manageCenterRepositoryProvider)),
);
