/// CenterDetailState, CenterDetailController (StateNotifier, keyed by centre id),
/// and the Riverpod providers for the student center-detail screen. On first
/// read it fetches `GET /api/centers/:id`, loads the first page of reviews, and
/// records a profile view; it also exposes the Enquire mutation.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider;
import '../models/center_detail_model.dart';
import '../models/center_review_model.dart';
import '../repository/center_detail_remote_datasource.dart';
import '../repository/center_detail_repository.dart';

/// Discrete states the detail fetch can be in.
enum CenterDetailStatus { loading, data, error }

/// Immutable snapshot the detail screen watches.
class CenterDetailState {
  /// Creates a state.
  const CenterDetailState({
    this.status = CenterDetailStatus.loading,
    this.center,
    this.reviews = const <CenterReview>[],
    this.errorMessage,
    this.enquirySubmitting = false,
  });

  /// Current step in the detail fetch.
  final CenterDetailStatus status;

  /// The loaded centre, or null before the first successful fetch.
  final CenterDetail? center;

  /// The loaded reviews (non-fatal — empty if they failed to load).
  final List<CenterReview> reviews;

  /// User-safe error string, when [status] is `error`.
  final String? errorMessage;

  /// True while an enquiry submission is in flight.
  final bool enquirySubmitting;

  /// Field-wise copy. `center` and `errorMessage` REPLACE so callers can clear.
  CenterDetailState copyWith({
    CenterDetailStatus? status,
    CenterDetail? center,
    List<CenterReview>? reviews,
    String? errorMessage,
    bool? enquirySubmitting,
  }) {
    return CenterDetailState(
      status: status ?? this.status,
      center: center ?? this.center,
      reviews: reviews ?? this.reviews,
      errorMessage: errorMessage,
      enquirySubmitting: enquirySubmitting ?? this.enquirySubmitting,
    );
  }
}

/// Holds the [CenterDetailState] for one centre id and fetches on construction.
class CenterDetailController extends StateNotifier<CenterDetailState> {
  /// Creates the controller for [_centerId] and fires the initial load.
  CenterDetailController(this._repository, this._centerId)
      : super(const CenterDetailState()) {
    load();
  }

  final CenterDetailRepository _repository;
  final String _centerId;

  bool _loadInFlight = false;

  /// Fetches the centre, then (non-fatally) its reviews, and records a view.
  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(
      status: CenterDetailStatus.loading,
      errorMessage: null,
    );
    try {
      final CenterDetail center = await _repository.getById(_centerId);
      state = state.copyWith(status: CenterDetailStatus.data, center: center);
      // Best-effort analytics + reviews (neither blocks the screen).
      unawaited(_repository.recordView(_centerId));
      _loadReviews();
    } on CenterDetailException catch (e) {
      state = state.copyWith(
        status: CenterDetailStatus.error,
        errorMessage: e.message,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> _loadReviews() async {
    try {
      final List<CenterReview> reviews =
          await _repository.getReviews(_centerId);
      if (!mounted) return;
      state = state.copyWith(reviews: reviews);
    } on CenterDetailException {
      // Reviews are non-fatal — leave the (empty) list.
    }
  }

  /// Sends a student enquiry. Returns `true` on success; on failure returns
  /// `false` and sets [CenterDetailState.errorMessage].
  Future<bool> submitEnquiry({
    required String message,
    String? subjectId,
  }) async {
    state = state.copyWith(enquirySubmitting: true, errorMessage: null);
    try {
      await _repository.submitEnquiry(
        _centerId,
        message: message,
        subjectId: subjectId,
      );
      state = state.copyWith(enquirySubmitting: false);
      return true;
    } on CenterDetailException catch (e) {
      state = state.copyWith(
        enquirySubmitting: false,
        errorMessage: e.message,
      );
      return false;
    }
  }
}

/// Composes the [CenterDetailRemoteDataSource] from the shared [apiClientProvider].
final Provider<CenterDetailRemoteDataSource>
    centerDetailRemoteDataSourceProvider =
    Provider<CenterDetailRemoteDataSource>(
  (ref) => CenterDetailRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the controller consumes.
final Provider<CenterDetailRepository> centerDetailRepositoryProvider =
    Provider<CenterDetailRepository>(
  (ref) =>
      CenterDetailRepository(ref.read(centerDetailRemoteDataSourceProvider)),
);

/// The center-detail state, keyed by centre id. Fires a fetch on first read;
/// `autoDispose` so leaving the screen frees it (and a re-open re-fetches).
final AutoDisposeStateNotifierProviderFamily<CenterDetailController,
        CenterDetailState, String> centerDetailControllerProvider =
    StateNotifierProvider.autoDispose
        .family<CenterDetailController, CenterDetailState, String>(
  (ref, id) =>
      CenterDetailController(ref.read(centerDetailRepositoryProvider), id),
);
