# 0037 — Teacher Schedule (week strip + a day's sessions)

**Status:** Accepted
**Date:** 2026-05-30
**Phase:** Round 5 — completing the teacher shell's tab screens.
**Made by:** User (one-line directive: "now create schedule screen using this
design style") + Claude (design approval → flutter-ui implementation).

## Context

The last teacher placeholder was the Schedule tab ("availability and upcoming
sessions"). With Home (0034), Search (0035), and Enquiries (0036) built, this
completes the teacher shell's primary tabs.

"This design style" was read as the established teacher neoglass look. Through
the design flow the user chose:

- **Layout:** a horizontal **week day-strip** (tap a day) + that day's sessions
  below — the most calendar-like option (vs. a grouped Today/Tomorrow agenda).
- **Style:** **neoglass hero** like the home — teal `BrandBackdrop`, a frosted
  summary header, and `NeoSurface` session rows (vs. the flat enquiries look).

## Decision

Replaced the placeholder `teacher_schedule_screen.dart`:

1. **`BrandBackdrop(orbColors: [teacherAccent])`** → `SafeArea` →
   `SingleChildScrollView` → capped/centered 600 px (matching the home).
2. **Week strip** (`_WeekStrip` / `_DayPill`) — a horizontally scrollable row of
   day pills (weekday + date number + a "today" dot). The selected pill is a
   filled-teal `Material`; the rest are frosted `GlassPanel`s, with today's date
   tinted teal. Selection is local hook state, defaulting to today's index.
3. **Frosted summary header** — a `GlassPanel` with a tinted calendar icon, the
   selected day's full label, and a "N session(s)" count (singular/plural).
4. **Session rows** (`_SessionRow`) — `NeoSurface` rows with a start/end time
   column, a hairline divider, subject + group, and a delivery-mode icon
   (video / in-person). An empty-state `NeoSurface` row when a day is free.
   Row taps are "Coming soon" stubs.

New fixture `data/mock_teacher_schedule_data.dart`: `ScheduleSession`
(`startTime, endTime, subject, group, mode`) and `ScheduleDay`
(`weekday, dayNum, fullLabel, isToday, sessions`) + a 7-day `mockScheduleWeek`
(today = Wed 30 May, mixed full/empty days). New teacher-schedule `AppStrings`
(title, session/sessions words, empty-state, "Today").

**SessionMode duplication (deliberate):** the schedule defines its own
`SessionMode { online, inPerson }` enum rather than importing the identical one
from the home data. An initial attempt to `import`/`export` the home enum to
keep a single source produced `invalid_constant` / `undefined` errors (the
re-exported enum did not resolve as a compile-time constant in the const
fixtures). Defining a local enum is the pragmatic fix; no file imports both
data libraries, so there is no collision. A future cleanup could hoist
`SessionMode` to a shared `core`/`shared` location if a third consumer appears.

## Consequences

- The teacher shell's four primary tabs (Home, Search, Enquiries, Schedule) are
  now all real screens; only deeper flows (session detail, availability editing)
  remain stubbed.
- The schedule is fixture-backed and read-only — tapping a session and editing
  availability are "Coming soon"; data resets on restart.
- Two small `SessionMode` enums now exist (home + schedule); acceptable given
  the const-fixture constraint, flagged here for a possible future hoist.
- Verified: `dart format` + `flutter analyze` (whole project) clean. Not yet
  walked on a device in light/dark.
