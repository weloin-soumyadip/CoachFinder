/// Owner enquiry controllers + providers. A list controller drives the inbox
/// (paginated, status-filtered, searchable) and a per-id family controller
/// drives the detail screen (load + status/notes mutations). Detail mutations
/// fold their result back into the inbox list so the two can't drift.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider;
import '../models/enquiry_model.dart';
import '../repository/enquiry_remote_datasource.dart';
import '../repository/enquiry_repository.dart';

/// Page size for the inbox list.
const int _pageLimit = 20;

// ===========================================================================
// Inbox list
// ===========================================================================

/// Discrete states the inbox can be in.
enum EnquiryListStatus { loading, loadingMore, data, error }

/// Immutable snapshot the inbox watches.
class EnquiryListState {
  /// Creates a state.
  const EnquiryListState({
    this.status = EnquiryListStatus.loading,
    this.items = const <Enquiry>[],
    this.filter = EnquiryFilter.all,
    this.query = '',
    this.page = 1,
    this.pages = 1,
    this.newCount = 0,
    this.errorMessage,
  });

  /// Current step.
  final EnquiryListStatus status;

  /// Loaded enquiries (accumulated across pages).
  final List<Enquiry> items;

  /// Active status filter.
  final EnquiryFilter filter;

  /// Active search query.
  final String query;

  /// Last loaded page.
  final int page;

  /// Total page count.
  final int pages;

  /// Count of `new` (unread) enquiries — shown as the header badge.
  final int newCount;

  /// User-safe error string, when [status] is `error`.
  final String? errorMessage;

  /// Whether more pages can be loaded.
  bool get hasMore => page < pages;

  /// True while the first page is loading (no items yet).
  bool get isInitialLoading =>
      status == EnquiryListStatus.loading && items.isEmpty;

  /// Field-wise copy.
  EnquiryListState copyWith({
    EnquiryListStatus? status,
    List<Enquiry>? items,
    EnquiryFilter? filter,
    String? query,
    int? page,
    int? pages,
    int? newCount,
    String? errorMessage,
  }) {
    return EnquiryListState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      newCount: newCount ?? this.newCount,
      errorMessage: errorMessage,
    );
  }
}

/// Holds the [EnquiryListState] and fetches the first page on construction.
class EnquiryListController extends StateNotifier<EnquiryListState> {
  /// Creates the controller and loads page 1.
  EnquiryListController(this._repository) : super(const EnquiryListState()) {
    load();
  }

  final EnquiryRepository _repository;
  bool _loadInFlight = false;

  /// (Re)loads page 1 for the current filter + query, and refreshes the unread
  /// count.
  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(
      status: EnquiryListStatus.loading,
      errorMessage: null,
    );
    try {
      final EnquiryPage page = await _repository.list(
        page: 1,
        limit: _pageLimit,
        status: state.filter.status,
        query: state.query,
      );
      state = state.copyWith(
        status: EnquiryListStatus.data,
        items: page.items,
        page: page.page,
        pages: page.pages,
      );
      _refreshNewCount();
    } on EnquiryException catch (e) {
      state = state.copyWith(
        status: EnquiryListStatus.error,
        errorMessage: e.message,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  /// Loads the next page and appends it.
  Future<void> loadMore() async {
    if (_loadInFlight || !state.hasMore) return;
    _loadInFlight = true;
    state = state.copyWith(status: EnquiryListStatus.loadingMore);
    try {
      final EnquiryPage page = await _repository.list(
        page: state.page + 1,
        limit: _pageLimit,
        status: state.filter.status,
        query: state.query,
      );
      state = state.copyWith(
        status: EnquiryListStatus.data,
        items: <Enquiry>[...state.items, ...page.items],
        page: page.page,
        pages: page.pages,
      );
    } on EnquiryException {
      // Keep what we have; just stop the spinner.
      state = state.copyWith(status: EnquiryListStatus.data);
    } finally {
      _loadInFlight = false;
    }
  }

  /// Switches the status filter and reloads from page 1.
  void setFilter(EnquiryFilter filter) {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter);
    load();
  }

  /// Sets the search query and reloads from page 1.
  void setQuery(String query) {
    if (query == state.query) return;
    state = state.copyWith(query: query);
    load();
  }

  /// Folds an updated enquiry (from the detail screen) into the list: replaces
  /// it in place, drops it when it no longer matches the active filter, and
  /// keeps the unread badge in sync.
  void applyUpdate(Enquiry updated) {
    final EnquiryStatus? filterStatus = state.filter.status;
    final List<Enquiry> next = <Enquiry>[];
    for (final Enquiry e in state.items) {
      if (e.id != updated.id) {
        next.add(e);
        continue;
      }
      // Drop it if it no longer matches the active (non-all) filter.
      if (filterStatus == null || updated.status == filterStatus) {
        next.add(updated);
      }
    }
    state = state.copyWith(items: next);
    _refreshNewCount();
  }

  /// Refreshes the true `new` count via a tiny status-scoped query (reads only
  /// the pagination total). Best-effort — failures leave the prior count.
  Future<void> _refreshNewCount() async {
    try {
      final EnquiryPage page = await _repository.list(
        page: 1,
        limit: 1,
        status: EnquiryStatus.newEnquiry,
      );
      if (!mounted) return;
      state = state.copyWith(newCount: page.total);
    } on EnquiryException {
      // Leave the existing count.
    }
  }
}

// ===========================================================================
// Detail (per id)
// ===========================================================================

/// Discrete states the detail screen can be in.
enum EnquiryDetailStatus { loading, data, error }

/// Immutable snapshot the detail screen watches.
class EnquiryDetailState {
  /// Creates a state.
  const EnquiryDetailState({
    this.status = EnquiryDetailStatus.loading,
    this.enquiry,
    this.saving = false,
    this.errorMessage,
  });

  /// Current step.
  final EnquiryDetailStatus status;

  /// The loaded enquiry, or null before the first fetch.
  final Enquiry? enquiry;

  /// True while a status / notes mutation is in flight.
  final bool saving;

  /// User-safe error string.
  final String? errorMessage;

  /// Field-wise copy.
  EnquiryDetailState copyWith({
    EnquiryDetailStatus? status,
    Enquiry? enquiry,
    bool? saving,
    String? errorMessage,
  }) {
    return EnquiryDetailState(
      status: status ?? this.status,
      enquiry: enquiry ?? this.enquiry,
      saving: saving ?? this.saving,
      errorMessage: errorMessage,
    );
  }
}

/// Holds one enquiry's [EnquiryDetailState] and exposes the mutations.
class EnquiryDetailController extends StateNotifier<EnquiryDetailState> {
  /// Creates the controller for [_id] and fires the initial load.
  EnquiryDetailController(this._ref, this._id)
      : super(const EnquiryDetailState()) {
    load();
  }

  final Ref _ref;
  final String _id;

  EnquiryRepository get _repository => _ref.read(enquiryRepositoryProvider);

  /// Loads the enquiry.
  Future<void> load() async {
    state = state.copyWith(
      status: EnquiryDetailStatus.loading,
      errorMessage: null,
    );
    try {
      final Enquiry enquiry = await _repository.getById(_id);
      state = state.copyWith(
        status: EnquiryDetailStatus.data,
        enquiry: enquiry,
      );
    } on EnquiryException catch (e) {
      state = state.copyWith(
        status: EnquiryDetailStatus.error,
        errorMessage: e.message,
      );
    }
  }

  /// Sets the status. Returns true on success.
  Future<bool> setStatus(EnquiryStatus status) => _mutate(status: status);

  /// Saves owner notes. Returns true on success.
  Future<bool> saveNotes(String notes) => _mutate(ownerNotes: notes.trim());

  Future<bool> _mutate({EnquiryStatus? status, String? ownerNotes}) async {
    if (state.enquiry == null) return false;
    state = state.copyWith(saving: true, errorMessage: null);
    try {
      final Enquiry updated = await _repository.update(
        _id,
        status: status,
        ownerNotes: ownerNotes,
      );
      state = state.copyWith(saving: false, enquiry: updated);
      // Keep the inbox in sync.
      _ref.read(enquiryListControllerProvider.notifier).applyUpdate(updated);
      return true;
    } on EnquiryException catch (e) {
      state = state.copyWith(saving: false, errorMessage: e.message);
      return false;
    }
  }
}

// ===========================================================================
// Providers
// ===========================================================================

/// Composes the datasource from the shared [apiClientProvider].
final Provider<EnquiryRemoteDataSource> enquiryRemoteDataSourceProvider =
    Provider<EnquiryRemoteDataSource>(
  (ref) => EnquiryRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the controllers consume.
final Provider<EnquiryRepository> enquiryRepositoryProvider =
    Provider<EnquiryRepository>(
  (ref) => EnquiryRepository(ref.read(enquiryRemoteDataSourceProvider)),
);

/// The inbox list state. Fires page 1 on first read.
final StateNotifierProvider<EnquiryListController, EnquiryListState>
    enquiryListControllerProvider =
    StateNotifierProvider<EnquiryListController, EnquiryListState>(
  (ref) => EnquiryListController(ref.read(enquiryRepositoryProvider)),
);

/// The detail state, keyed by enquiry id. `autoDispose` so leaving frees it.
final AutoDisposeStateNotifierProviderFamily<EnquiryDetailController,
        EnquiryDetailState, String> enquiryDetailControllerProvider =
    StateNotifierProvider.autoDispose
        .family<EnquiryDetailController, EnquiryDetailState, String>(
  (ref, id) => EnquiryDetailController(ref, id),
);
