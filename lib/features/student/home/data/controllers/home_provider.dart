/// HomeState, HomeController (StateNotifier), and Riverpod providers for the
/// student home/dashboard screen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider;
import '../models/student_dashboard_model.dart';
import '../repository/home_remote_datasource.dart';
import '../repository/home_repository.dart';

/// Discrete states the dashboard fetch can be in.
enum HomeStatus { initial, loading, data, error }

/// Snapshot consumed by the student HomeScreen.
class HomeState {
  const HomeState({
    this.status = HomeStatus.initial,
    this.dashboard,
    this.errorMessage,
  });

  /// Current step in the dashboard fetch.
  final HomeStatus status;

  /// The loaded dashboard, when [status] is `data`.
  final StudentDashboard? dashboard;

  /// User-safe error string, when [status] is `error`.
  final String? errorMessage;

  /// True while the first or a refresh fetch is in flight.
  bool get isLoading => status == HomeStatus.loading;

  /// True once a dashboard payload is available.
  bool get hasData => status == HomeStatus.data && dashboard != null;

  /// Field-wise copy. `errorMessage` deliberately replaces (not falls back)
  /// so callers can clear it by passing `errorMessage: null`.
  HomeState copyWith({
    HomeStatus? status,
    StudentDashboard? dashboard,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: errorMessage,
    );
  }
}

/// Holds the [HomeState] and exposes the dashboard fetch. Flips state through
/// Loading → Data, or → Error with the backend's verbatim message on failure.
class HomeController extends StateNotifier<HomeState> {
  HomeController(this._repository) : super(const HomeState()) {
    // Fire-and-forget initial load when the provider is first read.
    load();
  }

  final HomeRepository _repository;

  /// Fetches `GET /api/students/dashboard` and flips state accordingly.
  /// Used both for the initial load and for pull-to-refresh / retry.
  Future<void> load() async {
    state = state.copyWith(status: HomeStatus.loading, errorMessage: null);
    try {
      final dashboard = await _repository.fetchDashboard();
      state = HomeState(status: HomeStatus.data, dashboard: dashboard);
    } on HomeException catch (e) {
      state = HomeState(status: HomeStatus.error, errorMessage: e.message);
    }
  }

  /// Re-runs [load]. Convenience alias for pull-to-refresh call sites.
  Future<void> refresh() => load();
}

/// Composes the [HomeRemoteDataSource] from the shared [apiClientProvider].
final Provider<HomeRemoteDataSource> homeRemoteDataSourceProvider =
    Provider<HomeRemoteDataSource>(
  (ref) => HomeRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the controller consumes.
final Provider<HomeRepository> homeRepositoryProvider =
    Provider<HomeRepository>(
  (ref) => HomeRepository(ref.read(homeRemoteDataSourceProvider)),
);

/// The active dashboard state — consumed by the student HomeScreen. Reading
/// this provider kicks off the initial dashboard fetch in the background.
final StateNotifierProvider<HomeController, HomeState> homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(ref.watch(homeRepositoryProvider)),
);
