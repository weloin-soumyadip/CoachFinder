/// OwnerDashboardState, OwnerDashboardController (StateNotifier), and the
/// Riverpod providers for the owner dashboard feature. Fetches
/// `GET /api/owners/dashboard` once on first read; the Dashboard screen watches
/// [ownerDashboardControllerProvider] and maps the payload into its view models.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider;
import '../models/dashboard_stats_model.dart';
import '../repository/dashboard_remote_datasource.dart';
import '../repository/dashboard_repository.dart';

/// Discrete states the owner dashboard can be in. [noCenter] is the dedicated
/// state for a freshly-signed-up owner who has not created a coaching center
/// yet — the dashboard endpoint replies `404` for them, and the screen renders
/// an "Add Coaching Center" CTA instead of the generic error card.
enum OwnerDashboardStatus { initial, loading, data, error, noCenter }

/// Immutable snapshot consumed by the Dashboard screen.
class OwnerDashboardState {
  const OwnerDashboardState({
    this.status = OwnerDashboardStatus.initial,
    this.data,
    this.errorMessage,
  });

  /// Current step in the dashboard fetch.
  final OwnerDashboardStatus status;

  /// The loaded dashboard payload, present once [status] is `data`.
  final OwnerDashboardData? data;

  /// User-safe error string, when [status] is `error` (the backend's verbatim
  /// `message` where available — e.g. the 404 when the owner has no center).
  final String? errorMessage;

  /// True while a fetch is in flight.
  bool get isLoading => status == OwnerDashboardStatus.loading;

  /// True once the dashboard has loaded successfully.
  bool get hasData => status == OwnerDashboardStatus.data && data != null;

  /// Field-wise copy. `errorMessage` deliberately replaces (not falls back) so
  /// callers can clear it by passing `errorMessage: null`.
  OwnerDashboardState copyWith({
    OwnerDashboardStatus? status,
    OwnerDashboardData? data,
    String? errorMessage,
  }) {
    return OwnerDashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

/// Holds the [OwnerDashboardState] and fetches the dashboard on construction.
/// Re-entrancy-guarded so the constructor's load and a screen-triggered retry
/// can't overlap.
class OwnerDashboardController extends StateNotifier<OwnerDashboardState> {
  OwnerDashboardController(this._repository)
      : super(const OwnerDashboardState()) {
    // Fire-and-forget initial load when the provider is first read.
    load();
  }

  final OwnerDashboardRepository _repository;

  /// Guards [load] against overlapping calls — the constructor fires it once and
  /// a retry button may fire it again; the second is a no-op while the first
  /// runs.
  bool _loadInFlight = false;

  /// Fetches the dashboard payload. Loading → Data, or → Error with the
  /// backend's verbatim message. Re-entrant calls while a fetch is already
  /// running are ignored. Safe for the screen to call as a retry.
  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(
      status: OwnerDashboardStatus.loading,
      errorMessage: null,
    );
    try {
      final OwnerDashboardData data = await _repository.fetch();
      state = state.copyWith(
        status: OwnerDashboardStatus.data,
        data: data,
      );
    } on OwnerDashboardException catch (e) {
      // A 404 from this endpoint means exactly one thing: the owner has no
      // center yet (auth failures are 401). Route it to the dedicated
      // [OwnerDashboardStatus.noCenter] so the screen can offer to create one.
      state = state.copyWith(
        status: e.code == '404'
            ? OwnerDashboardStatus.noCenter
            : OwnerDashboardStatus.error,
        errorMessage: e.message,
      );
    } finally {
      _loadInFlight = false;
    }
  }
}

/// Composes the [OwnerDashboardRemoteDataSource] from the shared
/// [apiClientProvider].
final Provider<OwnerDashboardRemoteDataSource>
    ownerDashboardRemoteDataSourceProvider =
    Provider<OwnerDashboardRemoteDataSource>(
  (ref) => OwnerDashboardRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the controller consumes.
final Provider<OwnerDashboardRepository> ownerDashboardRepositoryProvider =
    Provider<OwnerDashboardRepository>(
  (ref) => OwnerDashboardRepository(
    ref.read(ownerDashboardRemoteDataSourceProvider),
  ),
);

/// The owner-dashboard state the Dashboard screen watches. Fires a fetch on
/// first read.
final StateNotifierProvider<OwnerDashboardController, OwnerDashboardState>
    ownerDashboardControllerProvider =
    StateNotifierProvider<OwnerDashboardController, OwnerDashboardState>(
  (ref) =>
      OwnerDashboardController(ref.watch(ownerDashboardRepositoryProvider)),
);
