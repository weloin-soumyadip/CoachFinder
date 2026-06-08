# 0040 — Student bookmarks (Saved) wired to the backend

**Status:** Accepted
**Date:** 2026-06-02
**Phase:** Backend wiring — replacing mock-backed student screens with the real API.
**Made by:** User (directive: "implement all three bookmark APIs in the saved
screen with all bookmark apis", then chose "1(a) + add Webinars" when asked
where the POST should live) + Claude (`flutter-data-layer` subagent for `data/`,
`flutter-ui` skill for the presentation).

## Context

The Saved screen was mock-backed (`mock_saved_data.dart`, local hook state,
reusing the old `TeacherResultCard`/`InstituteResultCard`). The backend exposes
three student-only, polymorphic bookmark endpoints under
`/api/students/bookmarks`:

- **POST** `{ targetType: Teacher|Webinar|CoachingCenter, targetId }` → 201
  `{ bookmark }` (top-level; `target` is a bare id, not populated); 409 if dup.
- **GET** `?page&limit&targetType` → `{ data[], pagination }`, `target`
  populated with a union select; newest first.
- **DELETE** `/:id` (the **bookmark** id) → 204.

There's **no toggle and no "is-saved?" endpoint** — membership is inferred from
the list. POST has no natural home on the Saved screen, so per the user's choice
the save action lives on the **Search result cards**; Saved lists + removes.

## Decision

### Core
- Added `ApiClient.delete(path)` (goes through the same interceptor → auth +
  refresh apply). `ApiConfig.studentsBookmarks`.

### Data layer (`flutter-data-layer` subagent), under `saved/data/`
- `bookmark_model.dart` — `BookmarkTargetType { teacher, webinar, coachingCenter }`
  (`wireValue`/`fromWire`) + `Bookmark { id, targetType, targetId, target (raw
  map), createdAt, key }`. `target` is kept as a raw map so the presentation can
  feed it straight into the existing `TeacherSearchResult`/`CenterSearchResult`/
  `WebinarSearchResult` `fromJson`s. `key = '<wireValue>:<targetId>'`.
- Datasource (`rawGet` list / `rawPost` create / `delete` remove) + repository
  (`BookmarksException`, `listAll()` drains all pages at limit 50 so the full
  set is in memory for the search-card membership check).
- **`BookmarkController` is the single source of truth shared by both screens**
  (`bookmarksControllerProvider`). State: `status`, `bookmarks` (full set),
  `savedKeys` (membership index), `errorMessage`. Mutations are **optimistic**:
  `create` flips `savedKeys` instantly then re-`load`s (the POST doesn't populate
  `target`, so a refetch is needed for the Saved list; 409 is treated as
  success); `remove` drops the item locally then reconciles on failure. An
  in-flight key set guards double-taps. Tests: 19 (model + state).

### Presentation (`flutter-ui` skill)
- New `BookmarkToggleButton` (connected `HookConsumerWidget`) — filled vs outline
  bookmark bound to `savedKeys`, calls `controller.toggle`, surfaces a failed
  mutation as a snackbar. The one bookmark affordance for both screens.
- The three Search result cards gained an optional `headerAction` slot (kept them
  decoupled from the bookmark provider); Search passes a `BookmarkToggleButton`
  per card.
- `saved_screen.dart` rewritten to watch `bookmarksControllerProvider`: live
  client-side search + an **All / Tutors / Coachings / Webinars** scrollable
  filter, rendering each bookmark through the matching Search card (built from
  `bookmark.target`) with a filled toggle that removes it. Loading spinner,
  inline error+retry, empty state.
- Deleted the now-dead `mock_saved_data.dart`, `teacher_result_card.dart`,
  `institute_result_card.dart`, and `shared/widgets/saved_bookmark_button.dart`.

## Consequences

- Bookmarks work end-to-end: save/unsave from Search, view/remove on Saved, the
  two views can't drift (one controller). Webinars are first-class.
- **The full bookmark set is loaded into memory** (`listAll` drains pages) — the
  search-card "is-saved?" indicator needs the complete set since there's no
  per-item check. Fine for realistic counts; if a student ever has thousands of
  bookmarks this would need a server-side membership endpoint.
- `create` costs an extra GET (refetch) because POST returns an unpopulated
  target; acceptable, keeps the Saved list correct without threading target data
  through the button.
- Optimistic mutations can briefly show a state the server later rejects; on
  failure the controller re-`load`s to restore truth and shows the message.
- Saved/Search now share the real result cards; the old mock cards +
  `SavedBookmarkButton` are gone.
- Verified: `dart format` + `flutter analyze` clean, full suite **67 tests**
  green, `flutter build apk --debug` succeeds. Not yet walked on a device in
  light/dark.
