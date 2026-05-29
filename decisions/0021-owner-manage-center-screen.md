# 0021 — Owner Center tab (manage-center) read view + edit form

**Status:** Accepted
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (request + interaction/section choices) + Claude (implementation)

## Context

The owner Center tab (`ManageCenterScreen`) and its create route were
placeholders, but this feature had the richest skeleton of any: a
`center_form_model` + `subject_model`, a `manage_center_provider`, a
repository trio, and four purpose-built widget stubs (board selector, subject
selector, timing editor, image upload). The user asked to build the tab and,
via clarifying questions, chose a **read view + Edit button** (not an inline
form), the four detail sections (**subjects, boards, weekly timings, photos**)
on top of the defaults (logo, name, location, about), the extras **contact
details, fees per course, and a read-only stats strip**, and to **leave the
first-time Create wizard** as a placeholder.

## Decision

Built a read view (the tab) plus a separate edit form, sharing one provider.
Owner-branded (`AppColors.ownerAccent`), palette-first per decision [0017].

### Shared state

Implemented the `manage_center_provider.dart` stub as a Riverpod **`Notifier`**
(`NotifierProvider<ManageCenterNotifier, CenterProfile>`, the same pattern
introduced for enquiries in [0020]) seeded from a fixture. The read view
`ref.watch`es it; the edit form reads it once into local draft state and calls
`save(updated)` to commit — so edits show up on the tab live.

### Pieces

- `data/mock_center_data.dart` — `CenterProfile` (+`copyWith`), `DayTiming`
  (`TimeOfDay`-based, with `copyWith`), `CenterPhoto`, `CourseFee`, the
  `allSubjects`/`allBoards` taxonomy, a context-free `formatTimeOfDay`, and the
  `mockCenter` fixture. Name + headline figures (Apex Coaching Centre, 1,248
  views, 4.8★, 128 reviews) match the dashboard / owner profile so the owner
  experience reads as one business. Model/repository stubs left for the backend
  swap (established `mock_*_data.dart` convention).
- Implemented all four widget stubs: `SubjectSelectorWidget` /
  `BoardSelectorWidget` (multi-select accent chips), `TimingEditorWidget`
  (per-day open/closed `Switch` + tappable open/close time chips that fire
  `onPickTime` so the host runs the picker), and `ImageUploadWidget` (coloured
  placeholder tiles; doubles as a read-only gallery when `onAdd`/`onRemove` are
  omitted).
- `ManageCenterScreen` (read view) — "My Center" + Edit button, a read-only
  views/rating/reviews stats strip, identity card, and About / Subjects /
  Boards / Timings / Photos / Contact / Fees sections.
- `EditCenterScreen` (new, `/manage-center/edit`, `AppRoutes.ownerEditCenter`)
  — text fields (name, tagline, location, address, about, phone, email), the
  four selector widgets, an editable fee list (add/remove/edit, rows keyed by
  id), a "Save Changes" button (commits + snackbar + pop). Reached via
  `pushNamed` from the read view so back returns within the shell. The new
  route sits under the existing `/manage-center` prefix, so the cross-shell
  guard and Center-tab highlight already cover it (no router-prefix change).

### Constraints honoured

- **No image picker** in the fixed stack, so photos are coloured placeholder
  tiles and "Add Photo" is a "coming soon" stub; remove works on the draft.
- Time editing uses the built-in `showTimePicker` (no package). `TimeOfDay` is
  formatted via a context-free helper so both screens render "4:00 PM".
- Fee rows use `TextFormField` with `ValueKey(id)` + `onChanged` (no per-row
  controllers) so add/remove preserves each row's edit state.

## Consequences

- Edits are **in-memory only** (reset on restart) until the backend lands —
  intended Phase-1 behaviour, consistent with enquiries.
- The edit form renders inside the owner shell (bottom nav visible beneath);
  acceptable, same trade-off as the enquiry detail.
- `CreateCenterScreen` stays a placeholder; there is no "no center yet"
  empty-state path (a center always exists in fixtures).
- The center now shares identity/figures with the dashboard + owner profile;
  keep them in sync until one backend source feeds all three.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build
apk --debug` → built.
