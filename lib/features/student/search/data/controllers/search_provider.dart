/// SearchState, SearchController (StateNotifier), and Riverpod providers for
/// the student search screen. Drives the three searchType queries behind the
/// All / Teachers / Centers / Webinars tabs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider;
import '../models/filter_model.dart';
import '../models/search_result_model.dart';
import '../repository/search_remote_datasource.dart';
import '../repository/search_repository.dart';

/// Default page size for every search call.
const int _kPageSize = 20;

/// Which entity tab the search screen is showing.
enum SearchMode {
  /// Teachers + centers + webinars combined.
  all,

  /// Teachers only (`searchType=teacher`).
  teacher,

  /// Coaching centers only (`searchType=coaching`).
  coaching,

  /// Webinars only (`searchType=webinar`).
  webinar,
}

/// Discrete states a search can be in.
enum SearchStatus {
  /// No search has run yet (resting / pre-search state).
  idle,

  /// A fresh (page 1) search is in flight.
  loading,

  /// A "load more" (next-page append) is in flight; existing results stay.
  loadingMore,

  /// Results are available.
  data,

  /// The last search failed.
  error,
}

/// Per-type page cursor: how many pages exist and which one we have loaded.
/// `hasMore` mirrors [SearchPagination.hasMore] for the loaded page.
class PageCursor {
  const PageCursor({this.page = 0, this.pages = 1});

  /// Highest page number currently loaded (0 = nothing loaded yet).
  final int page;

  /// Total pages reported by the backend for the active query.
  final int pages;

  /// True when a later page exists for this type.
  bool get hasMore => page > 0 && page < pages;

  /// The next page number to request.
  int get nextPage => page + 1;

  /// Builds a cursor from a fetched [pagination] block.
  factory PageCursor.fromPagination(SearchPagination pagination) =>
      PageCursor(page: pagination.page, pages: pagination.pages);
}

/// Snapshot consumed by the student SearchScreen.
class SearchState {
  const SearchState({
    this.mode = SearchMode.all,
    this.filters = const SearchFilters(),
    this.status = SearchStatus.idle,
    this.errorMessage,
    this.teachers = const <TeacherSearchResult>[],
    this.centers = const <CenterSearchResult>[],
    this.webinars = const <WebinarSearchResult>[],
    this.teacherCursor = const PageCursor(),
    this.centerCursor = const PageCursor(),
    this.webinarCursor = const PageCursor(),
  });

  /// Active entity tab.
  final SearchMode mode;

  /// Active filters (includes the query string `filters.q`).
  final SearchFilters filters;

  /// Current step in the search.
  final SearchStatus status;

  /// User-safe error string, when [status] is `error`.
  final String? errorMessage;

  /// Teacher results (populated for `all` and `teacher`).
  final List<TeacherSearchResult> teachers;

  /// Center results (populated for `all` and `coaching`).
  final List<CenterSearchResult> centers;

  /// Webinar results (populated for `all` and `webinar`).
  final List<WebinarSearchResult> webinars;

  /// Teacher pagination cursor.
  final PageCursor teacherCursor;

  /// Center pagination cursor.
  final PageCursor centerCursor;

  /// Webinar pagination cursor.
  final PageCursor webinarCursor;

  /// True while a fresh search is in flight.
  bool get isLoading => status == SearchStatus.loading;

  /// True while a "load more" append is in flight.
  bool get isLoadingMore => status == SearchStatus.loadingMore;

  /// True when results have been loaded.
  bool get hasData => status == SearchStatus.data;

  /// True when the active mode has at least one more page to load. For
  /// [SearchMode.all], true when ANY of the three types still has more.
  bool get hasMore {
    switch (mode) {
      case SearchMode.all:
        return teacherCursor.hasMore ||
            centerCursor.hasMore ||
            webinarCursor.hasMore;
      case SearchMode.teacher:
        return teacherCursor.hasMore;
      case SearchMode.coaching:
        return centerCursor.hasMore;
      case SearchMode.webinar:
        return webinarCursor.hasMore;
    }
  }

  /// True when the active mode has produced zero results after a search.
  bool get isEmpty {
    switch (mode) {
      case SearchMode.all:
        return teachers.isEmpty && centers.isEmpty && webinars.isEmpty;
      case SearchMode.teacher:
        return teachers.isEmpty;
      case SearchMode.coaching:
        return centers.isEmpty;
      case SearchMode.webinar:
        return webinars.isEmpty;
    }
  }

  /// Field-wise copy. `errorMessage` deliberately replaces (not falls back)
  /// so callers can clear it by passing `errorMessage: null`.
  SearchState copyWith({
    SearchMode? mode,
    SearchFilters? filters,
    SearchStatus? status,
    String? errorMessage,
    List<TeacherSearchResult>? teachers,
    List<CenterSearchResult>? centers,
    List<WebinarSearchResult>? webinars,
    PageCursor? teacherCursor,
    PageCursor? centerCursor,
    PageCursor? webinarCursor,
  }) {
    return SearchState(
      mode: mode ?? this.mode,
      filters: filters ?? this.filters,
      status: status ?? this.status,
      errorMessage: errorMessage,
      teachers: teachers ?? this.teachers,
      centers: centers ?? this.centers,
      webinars: webinars ?? this.webinars,
      teacherCursor: teacherCursor ?? this.teacherCursor,
      centerCursor: centerCursor ?? this.centerCursor,
      webinarCursor: webinarCursor ?? this.webinarCursor,
    );
  }
}

/// Holds the [SearchState] and runs the search calls. Does NOT auto-fire on
/// construction — search needs an explicit query / trigger; the initial
/// status is [SearchStatus.idle].
class SearchController extends StateNotifier<SearchState> {
  SearchController(this._repository) : super(const SearchState());

  final SearchRepository _repository;

  /// Switches the active tab and re-runs the search from page 1.
  Future<void> setMode(SearchMode mode) async {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode);
    await search();
  }

  /// Clears the query + filters and returns to the resting ([SearchStatus.idle])
  /// state, keeping the active [SearchMode]. Used by the search field's clear
  /// button so the screen falls back to its browse / recent-searches view.
  void reset() {
    state = SearchState(mode: state.mode);
  }

  /// Updates the query string and re-runs from page 1. Debounce is the UI's
  /// responsibility — this fires immediately.
  Future<void> setQuery(String query) async {
    state = state.copyWith(filters: state.filters.copyWith(q: query));
    await search();
  }

  /// Replaces the entire filter set and re-runs from page 1.
  Future<void> applyFilters(SearchFilters filters) async {
    state = state.copyWith(filters: filters);
    await search();
  }

  /// Clears every refinement but keeps the free-text query [SearchFilters.q]
  /// and the active mode, then re-runs from page 1. Backs the results screen's
  /// "Clear filters" button.
  Future<void> clearFilters() async {
    state = state.copyWith(filters: SearchFilters(q: state.filters.q));
    await search();
  }

  /// Runs page 1 of the active mode's type(s), replacing any existing results.
  Future<void> search() async {
    final SearchFilters filters = state.filters;
    final SearchMode mode = state.mode;
    state = state.copyWith(status: SearchStatus.loading, errorMessage: null);
    try {
      switch (mode) {
        case SearchMode.all:
          final results = await Future.wait(<Future<Object>>[
            _repository.searchTeachers(filters, page: 1, limit: _kPageSize),
            _repository.searchCenters(filters, page: 1, limit: _kPageSize),
            _repository.searchWebinars(filters, page: 1, limit: _kPageSize),
          ]);
          final teacherPage = results[0] as SearchPage<TeacherSearchResult>;
          final centerPage = results[1] as SearchPage<CenterSearchResult>;
          final webinarPage = results[2] as SearchPage<WebinarSearchResult>;
          state = state.copyWith(
            status: SearchStatus.data,
            teachers: teacherPage.items,
            centers: centerPage.items,
            webinars: webinarPage.items,
            teacherCursor: PageCursor.fromPagination(teacherPage.pagination),
            centerCursor: PageCursor.fromPagination(centerPage.pagination),
            webinarCursor: PageCursor.fromPagination(webinarPage.pagination),
          );
        case SearchMode.teacher:
          final page = await _repository.searchTeachers(filters,
              page: 1, limit: _kPageSize);
          state = state.copyWith(
            status: SearchStatus.data,
            teachers: page.items,
            teacherCursor: PageCursor.fromPagination(page.pagination),
          );
        case SearchMode.coaching:
          final page = await _repository.searchCenters(filters,
              page: 1, limit: _kPageSize);
          state = state.copyWith(
            status: SearchStatus.data,
            centers: page.items,
            centerCursor: PageCursor.fromPagination(page.pagination),
          );
        case SearchMode.webinar:
          final page = await _repository.searchWebinars(filters,
              page: 1, limit: _kPageSize);
          state = state.copyWith(
            status: SearchStatus.data,
            webinars: page.items,
            webinarCursor: PageCursor.fromPagination(page.pagination),
          );
      }
    } on SearchException catch (e) {
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: e.message,
      );
    }
  }

  /// Loads and APPENDS the next page of every type in the active mode that
  /// still has more. No-op when nothing has more or a load is already running.
  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == SearchStatus.loading ||
        state.status == SearchStatus.loadingMore) {
      return;
    }
    final SearchFilters filters = state.filters;
    final SearchMode mode = state.mode;
    state =
        state.copyWith(status: SearchStatus.loadingMore, errorMessage: null);
    try {
      switch (mode) {
        case SearchMode.all:
          await _loadMoreAll(filters);
        case SearchMode.teacher:
          await _loadMoreTeachers(filters);
        case SearchMode.coaching:
          await _loadMoreCenters(filters);
        case SearchMode.webinar:
          await _loadMoreWebinars(filters);
      }
      state = state.copyWith(status: SearchStatus.data);
    } on SearchException catch (e) {
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: e.message,
      );
    }
  }

  /// Advances every type that still has more (in parallel) and appends.
  Future<void> _loadMoreAll(SearchFilters filters) async {
    final futures = <Future<void>>[];
    if (state.teacherCursor.hasMore) futures.add(_loadMoreTeachers(filters));
    if (state.centerCursor.hasMore) futures.add(_loadMoreCenters(filters));
    if (state.webinarCursor.hasMore) futures.add(_loadMoreWebinars(filters));
    await Future.wait(futures);
  }

  Future<void> _loadMoreTeachers(SearchFilters filters) async {
    final page = await _repository.searchTeachers(
      filters,
      page: state.teacherCursor.nextPage,
      limit: _kPageSize,
    );
    state = state.copyWith(
      teachers: <TeacherSearchResult>[...state.teachers, ...page.items],
      teacherCursor: PageCursor.fromPagination(page.pagination),
    );
  }

  Future<void> _loadMoreCenters(SearchFilters filters) async {
    final page = await _repository.searchCenters(
      filters,
      page: state.centerCursor.nextPage,
      limit: _kPageSize,
    );
    state = state.copyWith(
      centers: <CenterSearchResult>[...state.centers, ...page.items],
      centerCursor: PageCursor.fromPagination(page.pagination),
    );
  }

  Future<void> _loadMoreWebinars(SearchFilters filters) async {
    final page = await _repository.searchWebinars(
      filters,
      page: state.webinarCursor.nextPage,
      limit: _kPageSize,
    );
    state = state.copyWith(
      webinars: <WebinarSearchResult>[...state.webinars, ...page.items],
      webinarCursor: PageCursor.fromPagination(page.pagination),
    );
  }
}

/// Composes the [SearchRemoteDataSource] from the shared [apiClientProvider].
final Provider<SearchRemoteDataSource> searchRemoteDataSourceProvider =
    Provider<SearchRemoteDataSource>(
  (ref) => SearchRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the controller consumes.
final Provider<SearchRepository> searchRepositoryProvider =
    Provider<SearchRepository>(
  (ref) => SearchRepository(ref.read(searchRemoteDataSourceProvider)),
);

/// The active search state — consumed by the student SearchScreen. Does NOT
/// fire any request on first read; call `setQuery` / `search` to trigger one.
final StateNotifierProvider<SearchController, SearchState>
    searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>(
  (ref) => SearchController(ref.watch(searchRepositoryProvider)),
);
