/// BookmarkState, BookmarkController (StateNotifier), and Riverpod providers
/// for the student Saved feature. The single source of truth shared by BOTH
/// the Saved screen (list + remove) and the save/unsave toggle on Search
/// result cards.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../auth/data/providers/auth_providers.dart'
    show apiClientProvider;
import '../models/bookmark_model.dart';
import '../repository/bookmarks_remote_datasource.dart';
import '../repository/bookmarks_repository.dart';

/// Discrete states the bookmark set can be in.
enum BookmarkStatus { initial, loading, data, error }

/// Snapshot consumed by the Saved screen and the search-card toggle.
class BookmarkState {
  const BookmarkState({
    this.status = BookmarkStatus.initial,
    this.bookmarks = const <Bookmark>[],
    this.savedKeys = const <String>{},
    this.errorMessage,
  });

  /// Current step in the bookmark fetch / mutation.
  final BookmarkStatus status;

  /// The full bookmark set, newest first (what the Saved screen renders).
  final List<Bookmark> bookmarks;

  /// Fast membership index: the [Bookmark.key]s of every saved item. Drives the
  /// instant flip of the save/unsave toggle on search cards.
  final Set<String> savedKeys;

  /// User-safe error string, when [status] is `error` (or after a failed
  /// mutation). Surfaced as a snackbar, never a full-screen state by itself.
  final String? errorMessage;

  /// True while a fetch is in flight.
  bool get isLoading => status == BookmarkStatus.loading;

  /// True once the bookmark set has loaded at least once.
  bool get hasData => status == BookmarkStatus.data;

  /// Whether [key] is currently saved (optimistic — reflects in-flight toggles).
  bool isSavedKey(String key) => savedKeys.contains(key);

  /// The bookmark `_id` for [key], or null when not saved. Used to issue the
  /// DELETE, which needs the bookmark id (not the target id).
  String? bookmarkIdForKey(String key) {
    for (final Bookmark b in bookmarks) {
      if (b.key == key) return b.id;
    }
    return null;
  }

  /// Field-wise copy. `errorMessage` deliberately replaces (not falls back) so
  /// callers can clear it by passing `errorMessage: null`.
  BookmarkState copyWith({
    BookmarkStatus? status,
    List<Bookmark>? bookmarks,
    Set<String>? savedKeys,
    String? errorMessage,
  }) {
    return BookmarkState(
      status: status ?? this.status,
      bookmarks: bookmarks ?? this.bookmarks,
      savedKeys: savedKeys ?? this.savedKeys,
      errorMessage: errorMessage,
    );
  }
}

/// Holds the [BookmarkState], fetches the full bookmark set on construction,
/// and exposes optimistic save / unsave / toggle mutations. Both the Saved
/// screen and search cards watch the same provider so the two views can't drift.
class BookmarkController extends StateNotifier<BookmarkState> {
  BookmarkController(this._repository) : super(const BookmarkState()) {
    // TEMP DIAGNOSTIC: log every state transition so we can see, on the running
    // device, exactly what `status` is when the spinner appears on remove.
    addListener((BookmarkState s) {
      debugPrint('[bookmark.state] status=${s.status} '
          'items=${s.bookmarks.length} loading=${s.isLoading} '
          'inFlight=${_inFlight.length} loadInFlight=$_loadInFlight '
          'err=${s.errorMessage}');
    }, fireImmediately: true);
    // Fire-and-forget initial load when the provider is first read.
    load();
  }

  final BookmarksRepository _repository;

  /// Keys with an in-flight create/remove, so a re-entrant toggle on the same
  /// key (e.g. an impatient double-tap) is ignored until the first settles.
  final Set<String> _inFlight = <String>{};

  /// Guards [load] against overlapping calls — the constructor fires it once
  /// and the Saved screen fires it again on entry; the second is a no-op while
  /// the first is still running.
  bool _loadInFlight = false;

  /// Builds the membership key for a (type, targetId) pair without a model.
  String _keyFor(BookmarkTargetType type, String targetId) =>
      '${type.wireValue}:$targetId';

  /// Whether the given target is currently saved.
  bool isSaved(BookmarkTargetType type, String targetId) =>
      state.isSavedKey(_keyFor(type, targetId));

  /// The bookmark id for the given target, or null when not saved.
  String? bookmarkId(BookmarkTargetType type, String targetId) =>
      state.bookmarkIdForKey(_keyFor(type, targetId));

  /// Fetches the full bookmark set (all pages) and derives [savedKeys].
  /// Loading → Data, or → Error with the backend's verbatim message. Re-entrant
  /// calls while a fetch is already running are ignored.
  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(status: BookmarkStatus.loading, errorMessage: null);
    try {
      final List<Bookmark> all = await _repository.listAll();
      state = state.copyWith(
        status: BookmarkStatus.data,
        bookmarks: all,
        savedKeys: all.map((Bookmark b) => b.key).toSet(),
      );
    } on BookmarksException catch (e) {
      state = state.copyWith(
        status: BookmarkStatus.error,
        errorMessage: e.message,
      );
    } catch (_) {
      // Catch-all so an UNEXPECTED throwable (a parse/type error that bypassed
      // the repository guard, etc.) can never leave the controller stuck in the
      // `loading` state — the Saved screen's spinner is bound to `isLoading`, so
      // a stuck `loading` is a permanent spinner. Always settle to `error`.
      state = state.copyWith(
        status: BookmarkStatus.error,
        errorMessage: AppStrings.errorUnknown,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  /// Saves the target if absent, otherwise removes it. The single entry point
  /// the search-card toggle button calls.
  Future<void> toggle(BookmarkTargetType type, String targetId) async {
    if (isSaved(type, targetId)) {
      final String? id = bookmarkId(type, targetId);
      if (id != null) await remove(id);
    } else {
      await create(type, targetId);
    }
  }

  /// Saves [targetId] of [targetType]. OPTIMISTIC: flips [savedKeys] instantly,
  /// then reconciles. Because the POST response does NOT populate `target`, a
  /// success triggers a full [load] so the Saved list gets the populated item.
  /// A `409 Already bookmarked` is treated as success (the key stays).
  Future<void> create(BookmarkTargetType type, String targetId) async {
    final String key = _keyFor(type, targetId);
    if (_inFlight.contains(key) || state.isSavedKey(key)) return;
    _inFlight.add(key);
    // Optimistic add.
    state = state.copyWith(
      savedKeys: <String>{...state.savedKeys, key},
      errorMessage: null,
    );
    try {
      await _repository.create(type, targetId);
      // Re-fetch so the populated target lands in the Saved list. The optimistic
      // key stays set throughout (load() will re-derive it anyway).
      await load();
    } on BookmarksException catch (e) {
      if (e.alreadyExists) {
        // Already saved server-side — keep the optimistic key, refresh the list
        // so the existing bookmark (with its id + populated target) is present.
        await load();
      } else {
        // Revert the optimistic add and surface the error.
        final Set<String> reverted = <String>{...state.savedKeys}..remove(key);
        state = state.copyWith(
          savedKeys: reverted,
          errorMessage: e.message,
        );
      }
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Removes the bookmark with id [bookmarkId]. OPTIMISTIC: drops it from
  /// [bookmarks] + [savedKeys] instantly (Saved screen updates immediately),
  /// then reconciles. On failure, the single dropped item is RE-INSERTED in
  /// place and the error is surfaced as a snackbar — deliberately NOT a full
  /// [load]. A blocking, sequential all-pages reload here (over the very
  /// connection that just made the DELETE slow/time out) is what produced the
  /// "spinner spins forever" bug; the local revert keeps the list correct
  /// without ever flipping the screen back to a loading spinner.
  Future<void> remove(String bookmarkId) async {
    // Locate the bookmark (and its index) so we can revert in place + guard
    // re-entry. If it's already gone, there's nothing to do.
    final int index =
        state.bookmarks.indexWhere((Bookmark b) => b.id == bookmarkId);
    if (index < 0) return;
    final Bookmark target = state.bookmarks[index];
    final String key = target.key;
    if (_inFlight.contains(key)) return;
    _inFlight.add(key);

    // Optimistic removal.
    final List<Bookmark> remaining = <Bookmark>[...state.bookmarks]
      ..removeAt(index);
    final Set<String> remainingKeys = <String>{...state.savedKeys}..remove(key);
    state = state.copyWith(
      bookmarks: remaining,
      savedKeys: remainingKeys,
      errorMessage: null,
    );

    try {
      await _repository.remove(bookmarkId);
    } on BookmarksException catch (e) {
      // Re-insert the item at its original position and restore its key — no
      // blocking reload, no spinner — then surface the error.
      final List<Bookmark> reverted = <Bookmark>[...state.bookmarks];
      reverted.insert(index.clamp(0, reverted.length), target);
      state = state.copyWith(
        bookmarks: reverted,
        savedKeys: <String>{...state.savedKeys, key},
        errorMessage: e.message,
      );
    } finally {
      _inFlight.remove(key);
    }
  }
}

/// Composes the [BookmarksRemoteDataSource] from the shared [apiClientProvider].
final Provider<BookmarksRemoteDataSource> bookmarksRemoteDataSourceProvider =
    Provider<BookmarksRemoteDataSource>(
  (ref) => BookmarksRemoteDataSource(ref.read(apiClientProvider)),
);

/// The repository surface the controller consumes.
final Provider<BookmarksRepository> bookmarksRepositoryProvider =
    Provider<BookmarksRepository>(
  (ref) => BookmarksRepository(ref.read(bookmarksRemoteDataSourceProvider)),
);

/// The shared bookmark state — watched by the Saved screen AND the search-card
/// toggle. Fires a full fetch on first read.
final StateNotifierProvider<BookmarkController, BookmarkState>
    bookmarksControllerProvider =
    StateNotifierProvider<BookmarkController, BookmarkState>(
  (ref) => BookmarkController(ref.watch(bookmarksRepositoryProvider)),
);
