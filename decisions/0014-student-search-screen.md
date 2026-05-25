# 0014 — Student Search screen

**Status:** Accepted
**Date:** 2026-05-25
**Phase:** Post-Phase-1 iteration
**Made by:** User (features, layout choices, screenshot reference) + Claude (structure, responsive grid, fixtures)

## Context

The student shell's `/search` route was a placeholder. The user asked for a
Search screen where students search **teachers and coaching institutes**, with
a reference screenshot (a coach-only search). The instruction was to borrow the
screenshot's structure but implement **only the specified features** and add
dummy data.

## Decision

Built `search_screen.dart` (a `HookConsumerWidget`) plus three widgets and a
fixture file. All content is fabricated and filtered locally; no
controller/repository yet (matches how Home was built — that layer arrives with
the backend).

### Behaviour

- **Search bar** drives a live, case-insensitive filter over name / title /
  location / tags.
- **Segmented control: All / Teachers / Institutes** narrows result type. The
  user chose this over a mixed list or grouped sections.
- **Resting state** (empty query on the All tab): "Browse by category" chips +
  "Recent searches" list. Tapping either fills the query. Selecting the
  Teachers/Institutes tab with an empty query browses that full type.
- **Results**: a "Found N {results|teachers|institutes}" header with a Filters
  link, then the cards. Empty query+matches → an empty state.

### Responsive (user chose mobile + desktop)

A single `LayoutBuilder` measures the **content area** (not `MediaQuery`, so it
is correct inside the desktop `NavigationRail`). Columns = `(contentWidth / 320)`
clamped to 1–3; cards are laid out in a `Wrap` with computed widths. Content is
capped at 1100 px and centred so cards don't stretch on wide windows. Phones get
one column; tablets/desktop get 2–3.

### Data

New `mock_search_data.dart`: `SearchTeacher`, `SearchInstitute`, the
`SearchEntityType` enum, and fixtures (5 teachers, 4 institutes, 8 categories, 4
recent searches). Tags are plain `String`s rendered as neutral pills (simpler
than Home's coloured `CoachTag`). The institute entity is **new** — nothing
modelled centers before.

## Divergences from the screenshot (intentional, per "don't copy all")

- **No "Book Now" button.** Booking isn't a requested feature; the whole card is
  tappable instead.
- **Selected pill uses student blue**, not the screenshot's teal — stays on the
  app's brand.
- **Added Institute cards** and the **Teachers/Institutes** tabs (the screenshot
  was coaches-only).
- The screenshot's category chips became the **resting-state** browse chips; the
  entity tabs are a separate control.

## Alternatives considered

- **Mixed list with type badges / two grouped sections** — rejected by the user
  in favour of segmented tabs.
- **`GridView` with fixed cell extent** — rejected; cards have variable height
  (different tag counts), so a `Wrap` of width-constrained cards avoids
  clipping.
- **Reusing Home's `Coach`/`CoachTag` models** — rejected to keep Search
  self-contained; only the app-global `mockUser` is imported (for the top-bar
  avatar).

## Consequences

- Result taps are no-op placeholders; the Filters link navigates to the existing
  `FilterScreen` placeholder (`/search/filter`). Both become real later.
- When a teacher-detail screen and real center-detail wiring land, the card
  `onTap`s are the integration points (institutes → `/center/:id`).
- The responsive `Wrap` sizing is reusable; if more grid screens appear,
  consider extracting the column-count helper.

## Follow-ups

- Real data via a search controller/repository once the backend lands.
- Teacher-detail route (student shell currently has center-detail only).
- Build the actual FilterScreen UI.
