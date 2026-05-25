# 0015 — Student Saved screen

**Status:** Accepted
**Date:** 2026-05-25
**Phase:** Post-Phase-1 iteration
**Made by:** User (features, filter labels, interaction choices) + Claude (structure, reuse strategy, fixtures)

## Context

The student shell's `/saved` route was a bare placeholder (`Text('SavedScreen')`)
living under the `profile/` feature, with a stale `saved_center_tile_widget.dart`
stub (`// TODO`). The user asked for a Saved screen with a **search field at the
top** and **All / Coachings / Tutors** filters.

"Coachings" maps to coaching institutes / centers and "Tutors" maps to teachers
— the same two entity types Search already models, so Saved is effectively a
bookmarked view over them.

## Decision

Built a dedicated `saved/` feature (`data/` + `presentation/`) with a real
`saved_screen.dart` (`HookConsumerWidget`) plus a fixture file. Three confirmed
choices drove the design:

1. **Reuse the Search result cards.** Tutors render with `TeacherResultCard`,
   coachings with `InstituteResultCard` — same visual language as Search, no new
   card widgets. The fixtures reuse the `SearchTeacher` / `SearchInstitute`
   models so the cards render unchanged.
2. **Working un-save toggle.** Each card shows a filled-bookmark button in its
   footer; tapping it removes that item from local hook state. Clearing the
   visible list shows an empty state. (Still no backend — state resets on
   rebuild.)
3. **Dedicated `lib/features/student/saved/` folder**, matching the
   feature-per-tab convention. The old placeholder under `profile/` and the
   stale tile widget were removed; the router import was repointed.

### Behaviour

- **Search field** (the reused `SearchFieldWidget`, now with an optional
  `hintText`) live-filters saved items by name / title / location / tags.
- **All / Coachings / Tutors** filter narrows by type (same pill styling as
  Search's segmented control, blue when selected).
- A subtle "N saved" count line sits above the responsive card grid.
- **Empty state** ("Nothing saved yet") shows when the visible list is empty.

### Responsive

Mirrors Search exactly: a single `LayoutBuilder` measures the **content area**
(correct inside the desktop `NavigationRail`), columns = `(contentWidth / 320)`
clamped 1–3, cards in a width-constrained `Wrap`, content capped at 1100 px and
centred.

## Shared widget

The bookmark-remove control is a new `SavedBookmarkButton` in
`lib/shared/widgets/` (the previously-reserved folder) so both result cards can
use it. Both cards gained an optional `onUnsave` callback — backward-compatible,
so Search (which passes nothing) is visually unchanged.

## Alternatives considered

- **A distinct compact "saved tile"** (the original `saved_center_tile_widget`
  intent) — rejected by the user in favour of reusing the Search cards for
  consistency.
- **Display-only cards (no remove)** — rejected; the working toggle makes the
  screen feel real and exercises the empty state.
- **Keeping the screen under `profile/`** — rejected; Saved is its own top-level
  tab, so it gets its own feature folder.
- **Overlaying the bookmark via a `Stack`** instead of an `onUnsave` param —
  rejected; an explicit footer button avoids hit-testing surprises and aligns
  cleanly with the price / course-count row.

## Consequences

- Card taps are still no-op placeholders (same as Search); they become the
  integration points when teacher-detail / center-detail wiring lands.
- Un-save is local-only and resets on rebuild — it persists once a real saved
  repository exists.
- The empty state uses one copy for both "nothing saved" and "no search match";
  acceptable at fixture level, can be split later.
- `SavedBookmarkButton` and the card `onUnsave` hook are reusable if other
  screens need a save/unsave affordance.

## Follow-ups

- Real saved data + persistence via a controller/repository once the backend
  lands.
- Teacher-detail / center-detail routes so card taps navigate.
