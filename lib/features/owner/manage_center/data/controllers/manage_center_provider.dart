/// ManageCenterState + ManageCenterController (StateNotifier) and the provider
/// the Manage-Center read view + edit form watch. Wired to the backend:
/// `GET /api/centers/me` on load, `PATCH /api/centers/:id` on save. Replaces the
/// former in-memory mock notifier.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/center_update.dart';
import '../models/owner_center.dart';
import '../repository/manage_center_repository.dart' show ManageCenterException;
import 'create_center_provider.dart' show manageCenterRepositoryProvider;

/// Discrete states the Manage-Center feature can be in.
enum ManageCenterStatus { initial, loading, data, error }

/// Immutable snapshot the read view + edit form watch.
class ManageCenterState {
  /// Creates a state.
  const ManageCenterState({
    this.status = ManageCenterStatus.initial,
    this.center,
    this.errorMessage,
  });

  /// Current step in the fetch / mutation.
  final ManageCenterStatus status;

  /// The loaded centre, or null before the first successful fetch.
  final OwnerCenter? center;

  /// User-safe error string (the backend's verbatim message where available).
  final String? errorMessage;

  /// True while a fetch / mutation is in flight.
  bool get isLoading => status == ManageCenterStatus.loading;

  /// True once the centre has loaded at least once.
  bool get hasData => center != null;

  /// Field-wise copy. `center` and `errorMessage` deliberately REPLACE (not
  /// fall back) so callers can clear the error with `errorMessage: null`.
  ManageCenterState copyWith({
    ManageCenterStatus? status,
    OwnerCenter? center,
    String? errorMessage,
  }) {
    return ManageCenterState(
      status: status ?? this.status,
      center: center ?? this.center,
      errorMessage: errorMessage,
    );
  }
}

/// Holds the [ManageCenterState], fetches the centre on construction, and
/// exposes the save mutation. The read view + edit form share this provider so
/// they can't drift.
class ManageCenterController extends StateNotifier<ManageCenterState> {
  /// Creates the controller and fires the initial load.
  ManageCenterController(this._ref) : super(const ManageCenterState()) {
    load();
  }

  final Ref _ref;

  /// Guards [load] against overlapping calls.
  bool _loadInFlight = false;

  /// Fetches the centre via `GET /api/centers/me`. Loading → Data, or → Error
  /// with the backend's verbatim message.
  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(
      status: ManageCenterStatus.loading,
      errorMessage: null,
    );
    try {
      final OwnerCenter? center =
          await _ref.read(manageCenterRepositoryProvider).getMine();
      if (center == null) {
        // No centre — the owner-setup gate normally prevents reaching here.
        state = state.copyWith(
          status: ManageCenterStatus.error,
          errorMessage: 'No coaching center found for this owner',
        );
      } else {
        state = state.copyWith(
          status: ManageCenterStatus.data,
          center: center,
        );
      }
    } on ManageCenterException catch (e) {
      state = state.copyWith(
        status: ManageCenterStatus.error,
        errorMessage: e.message,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  /// Applies a strict-partial [update] via `PATCH /api/centers/:id`. On success
  /// the held centre is replaced with the backend's echoed doc and `true` is
  /// returned (the UI pops + snackbars). An empty update short-circuits to
  /// `true`. On failure the loaded centre is kept, [ManageCenterState.errorMessage]
  /// is set, and `false` is returned.
  Future<bool> save(CenterUpdate update) async {
    final OwnerCenter? current = state.center;
    if (current == null) return false;
    if (update.isEmpty) return true;
    state = state.copyWith(
      status: ManageCenterStatus.loading,
      errorMessage: null,
    );
    try {
      final OwnerCenter updated = await _ref
          .read(manageCenterRepositoryProvider)
          .update(current.id, update);
      state = state.copyWith(
        status: ManageCenterStatus.data,
        center: updated,
      );
      return true;
    } on ManageCenterException catch (e) {
      // Keep the loaded centre; just flag the error so the form can recover.
      state = state.copyWith(
        status: ManageCenterStatus.data,
        errorMessage: e.message,
      );
      return false;
    }
  }
}

/// The shared Manage-Center state. Fires a fetch on first read.
final StateNotifierProvider<ManageCenterController, ManageCenterState>
    manageCenterControllerProvider =
    StateNotifierProvider<ManageCenterController, ManageCenterState>(
  ManageCenterController.new,
);
