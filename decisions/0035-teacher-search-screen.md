# 0035 — Teacher Search (find a center to affiliate with)

**Status:** Accepted
**Date:** 2026-05-30
**Phase:** Round 5 — building out the teacher shell's tab screens.
**Made by:** User (one-line directive: "now do the search screen") + Claude
(brainstorming skill → design approval → flutter-ui skill implementation).

## Context

Continuing from ADR 0034, the teacher Search tab was still a placeholder. Its
documented purpose differs from the student search (which discovers tutors &
institutes *to learn from*): a teacher — a hybrid who can affiliate with a
center — searches for **coaching centers to associate with**.

Through the brainstorming flow the user chose, from ASCII-mockup options:

- **Result card:** a center card with a primary **"Request to affiliate"**
  action and a "Hiring" badge (vs. a tap-only view card).
- **Resting state:** browse-by-subject chips + recent searches (vs.
  results-only), with a single "Hiring now" filter replacing the student
  search's All/Teachers/Institutes segments.

## Decision

Replaced the placeholder `teacher_search_screen.dart`, reusing the student
search's structure (responsive 1–3 col grid, capped 1100 px, live
case-insensitive filter) but teal-branded:

1. **Teal gradient wash** (`AppColors.teacherAccentTint → palette.background`,
   stops `[0, 0.4]`) — the teacher-shell counterpart to the student search's
   blue wash.
2. **Reuses the student `SearchFieldWidget`** (already frosted glass;
   cross-feature import, exactly as the Saved screen reuses it) with a teacher
   hint.
3. A single **"Hiring now"** toggle pill (`_HiringFilterPill`): filled teal when
   active, frosted `GlassPanel` when off — in place of the student segments.
4. **Resting state** (empty query + filter off): a "Browse by subject"
   `GlassPanel` chip row (reusing `teacherSubjectOptions` from the profile
   fixture) + a recent-searches list.
5. **Results:** "Found N centers" header + a `Wrap` grid of `CenterResultCard`s;
   an empty state when nothing matches.

New widget `center_result_card.dart` — a `GlassPanel` card (matches the student
result cards): logo tile, name + tinted rating pill, location, a teal "● Hiring"
badge when open, subject tag pills, and a full-width teal **Request to
affiliate** `NeoButton`.

New fixture `mock_teacher_search_data.dart`:
`AffiliationCenter { id, name, location, initial, logoColor, rating, subjects,
isHiring }` + `mockAffiliationCenters` (6, mixed hiring) +
`mockTeacherSearchRecents`. New teacher-search `AppStrings` block — no hardcoded
copy.

## Consequences

- The teacher now has a purpose-built discovery surface distinct from the
  student search, reinforcing the hybrid (independent + affiliatable) model from
  ADR 0012.
- Reusing `SearchFieldWidget` keeps the frosted-field treatment in one place;
  the result card deliberately diverges from the student institute card (an
  affiliate CTA + Hiring badge instead of a course count / save).
- Card taps, "Request to affiliate", and the affiliate flow are stubs ("Coming
  soon") until a center-detail screen and a real affiliation request exist.
  Filtering is the in-screen "Hiring now" toggle; there's no separate Filters
  sheet (the student search's Filters entry point is not replicated).
- **Performance:** the center cards use `GlassPanel`, consistent with the
  (user-chosen) glass student result cards, and flow through a `Wrap` (not a
  `ListView.builder`), so the per-frame re-blur caveat does not apply.
- Verified: `dart format` + `flutter analyze` (whole project) clean. Not yet
  walked on a device in light/dark.
