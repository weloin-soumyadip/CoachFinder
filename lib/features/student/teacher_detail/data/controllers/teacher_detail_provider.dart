/// TeacherDetailState, TeacherDetailController (StateNotifier, keyed by teacher
/// id), and the Riverpod providers for the student teacher-detail screen. On
/// first read it fetches `GET /api/teachers/:id` and the first page of reviews.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider;
import '../models/teacher_detail_model.dart';
import '../models/teacher_review_model.dart';
import '../repository/teacher_detail_remote_datasource.dart';
import '../repository/teacher_detail_repository.dart';

/// Discrete states the detail fetch can be in.
enum TeacherDetailStatus { loading, data, error }

/// Immutable snapshot the detail screen watches.
class TeacherDetailState {
  /// Creates a state.
  const TeacherDetailState({
    this.status = TeacherDetailStatus.loading,
    this.teacher,
    this.reviews = const <TeacherReview>[],
    this.errorMessage,
  });

  /// Current step in the detail fetch.
  final TeacherDetailStatus status;

  /// The loaded teacher, or null before the first successful fetch.
  final TeacherDetail? teacher;

  /// The loaded reviews (non-fatal — empty if they failed to load).
  final List<TeacherReview> reviews;

  /// User-safe error string, when [status] is `error`.
  final String? errorMessage;

  /// Field-wise copy. `teacher` and `errorMessage` REPLACE so callers can clear.
  TeacherDetailState copyWith({
    TeacherDetailStatus? status,
    TeacherDetail? teacher,
    List<TeacherReview>? reviews,
    String? errorMessage,
  }) {
    return TeacherDetailState(
      status: status ?? this.status,
      teacher: teacher ?? this.teacher,
      reviews: reviews ?? this.reviews,
      errorMessage: errorMessage,
    );
  }
}

/// Holds the [TeacherDetailState] for one teacher id and fetches on construction.
class TeacherDetailController extends StateNotifier<TeacherDetailState> {
  /// Creates the controller for [_teacherId] and fires the initial load.
  TeacherDetailController(this._repository, this._teacherId)
      : super(const TeacherDetailState()) {
    load();
  }

  final TeacherDetailRepository _repository;
  final String _teacherId;

  bool _loadInFlight = false;

  /// Fetches the teacher, then (non-fatally) the first page of reviews.
  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(
      status: TeacherDetailStatus.loading,
      errorMessage: null,
    );
    try {
      final TeacherDetail teacher = await _repository.getById(_teacherId);
      state =
          state.copyWith(status: TeacherDetailStatus.data, teacher: teacher);
      _loadReviews();
    } on TeacherDetailException catch (e) {
      state = state.copyWith(
        status: TeacherDetailStatus.error,
        errorMessage: e.message,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> _loadReviews() async {
    try {
      final List<TeacherReview> reviews =
          await _repository.getReviews(_teacherId);
      if (!mounted) return;
      state = state.copyWith(reviews: reviews);
    } on TeacherDetailException {
      // Reviews are non-fatal — leave the (empty) list.
    }
  }
}

/// Composes the [TeacherDetailRemoteDataSource] from the shared [apiClientProvider].
final Provider<TeacherDetailRemoteDataSource>
    teacherDetailRemoteDataSourceProvider =
    Provider<TeacherDetailRemoteDataSource>(
  (ref) => TeacherDetailRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the controller consumes.
final Provider<TeacherDetailRepository> teacherDetailRepositoryProvider =
    Provider<TeacherDetailRepository>(
  (ref) =>
      TeacherDetailRepository(ref.read(teacherDetailRemoteDataSourceProvider)),
);

/// The teacher-detail state, keyed by teacher id. `autoDispose` so leaving the
/// screen frees it (and a re-open re-fetches).
final AutoDisposeStateNotifierProviderFamily<TeacherDetailController,
        TeacherDetailState, String> teacherDetailControllerProvider =
    StateNotifierProvider.autoDispose
        .family<TeacherDetailController, TeacherDetailState, String>(
  (ref, id) =>
      TeacherDetailController(ref.read(teacherDetailRepositoryProvider), id),
);
