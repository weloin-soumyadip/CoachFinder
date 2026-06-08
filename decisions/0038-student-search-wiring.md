# 0038 — Student Search wired to the backend

**Status:** Accepted
**Date:** 2026-06-02
**Phase:** Backend wiring — replacing mock-backed student screens with the real API.
**Made by:** User (directive: "use flutter-data-layer subagent and implement the
search feature in student app … ask me clarifying questions") + Claude
(clarifying Q&A → `flutter-data-layer` subagent for `data/` → `flutter-ui` skill
for the presentation rewire).

## Context

The student Search tab (ADR 0014-era) was mock-backed: `mock_search_data.dart`
fixtures filtered locally, with an All / Teachers / Institutes segment control
and a placeholder filter screen. The `data/` layer was scaffolded but all
`// TODO: implement` stubs.

The backend exposes one student-only endpoint, `GET /api/search`, with a
`searchType` discriminator (`teacher` | `coaching` | `webinar`); each call
returns exactly **one** entity type with envelope
`{ success, data: [...], pagination: { page, limit, total, pages } }`.

Clarifying answers from the user fixed scope: **four tabs** (All / Teachers /
Centers / Webinars), **full filters minus geo** (subject, city, board, minRating,
min/max fees — device location is out, no plugin in the fixed stack), **infinite
scroll**, and **rewire the presentation layer** too (not just `data/`).

## Decision

### Data layer (`flutter-data-layer` subagent)
- Models `TeacherSearchResult` / `CenterSearchResult` / `WebinarSearchResult`
  (from the backend public projections), plus `FeesRange` and
  `SearchPagination`; `SearchFilters` + a `SearchBoard` enum
  (`wireValue` → exact `CBSE`/`ICSE`/… strings).
- `SearchRemoteDataSource` → `SearchRepository` (throws `SearchException`) →
  `SearchController` (`StateNotifier<SearchState>`) with `setMode` / `setQuery` /
  `applyFilters` / `search` / `loadMore`. Providers reuse the auth
  `apiClientProvider`. Model + filter tests (17, all green).
- **`SearchMode.all` fans out** to teacher + coaching + webinar in parallel
  (`Future.wait`); `loadMore` advances each type that still `hasMore`. Per-type
  `PageCursor`s track pagination independently.

### Core
- **`ApiClient.rawGet(path, {queryParameters})`** added (mirrors `rawPost`):
  `ApiResponse.fromJson` extracts only `data` and **drops the `pagination`
  sibling**, and the typed `get` had no query-param support. The datasource uses
  `rawGet` and parses `data` + `pagination` itself.
- `ApiConfig.search = '/search'`.
- **Webinar reduced param set:** the webinar schema is `.strict()` and 400s on
  `subject`/`city`/`board`/rating/fees, so `SearchFilters.toQueryParameters`
  takes a `forWebinar` flag that emits only `q`.
- `SearchController.reset()` (added during the UI wiring) returns to
  `SearchStatus.idle` keeping the active mode — drives the search field's clear
  button back to the resting state.

### Presentation (`flutter-ui` skill)
- Rewrote `search_screen.dart` to watch `searchControllerProvider`: a **debounced**
  (`AppEffects.searchDebounce`, 350 ms) field → `setQuery`; a horizontally
  scrollable 4-tab segment control → `setMode`; resting state (`status == idle`)
  reusing the mock category/recent fixtures; results in the responsive 1–3 col
  capped `Wrap`; **infinite scroll** via `NotificationListener` → `loadMore`;
  inline loading / error+retry / empty states.
- New real-model cards `teacher_search_card.dart` / `center_search_card.dart` /
  `webinar_search_card.dart`, a shared `result_avatar_widget.dart` (network image
  + initial fallback, no cache package) and `result_card_parts.dart`
  (`RatingBadge`, `SubjectTag`, `feesLabel`). The webinar card formats the
  schedule locally (no `intl`) and stubs Join ("Coming soon").
- Built the real `filter_screen.dart` (subject/city text, board + rating choice
  pills, min/max fees) — Apply builds a fresh `SearchFilters` preserving `q` and
  calls `applyFilters`; pushed (not `go`) so back returns to results.

## Consequences

- Student search is now fully backend-wired (the second student feature after
  the dashboard, ADR-pending). Mock fixtures survive only for the resting-state
  browse chips / recent searches.
- **The existing `TeacherResultCard` / `InstituteResultCard` were left untouched**
  — the Saved screen still consumes them with the mock `SearchTeacher` /
  `SearchInstitute` types, so search got new, differently-named cards instead of
  retyping the shared ones. Four never-implemented stub widgets
  (`center_card_widget`, `search_bar_widget`, `filter_chip_widget`,
  `shimmer_card_widget`) were deleted.
- **`SearchMode.all` issues three requests per search** and `loadMore` up to
  three more; an empty query browses-all. Acceptable for now; could be narrowed
  later. Webinars carry no subject/city/fees/rating filters, so applied filters
  silently don't constrain the webinar slice of an "All" search.
- Geo/distance is intentionally unsupported (no location plugin).
- **Performance:** result cards use `GlassPanel` in a `Wrap` (not a
  `ListView.builder`), consistent with the existing student result cards, so the
  per-frame re-blur caveat does not apply.
- Verified: `dart format` + `flutter analyze` clean, full suite 43 tests green,
  `flutter build apk --debug` succeeds. Not yet walked on a device in light/dark.
