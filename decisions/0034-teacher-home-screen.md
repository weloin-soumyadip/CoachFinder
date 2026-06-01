# 0034 — Teacher Home (activity control center)

**Status:** Accepted
**Date:** 2026-05-30
**Phase:** Round 5 — building out the teacher shell's tab screens (home,
search, …) from their Phase-1 placeholders.
**Made by:** User (one-line directive: "now build the home screen of the
teacher's app") + Claude (brainstorming skill → design approval → flutter-ui
skill implementation).

## Context

The teacher shell (`roleTeacher`, teal-branded `AppColors.teacherAccent`)
had only its Profile tab built (ADR 0022). Home, Schedule, Enquiries, and
Search were all 54-line "Coming soon" placeholders. The teacher is a hybrid:
an independent tutor who can also affiliate with a coaching center.

The user asked to build the teacher home. Through the brainstorming flow they
chose, from ASCII-mockup options:

- **Purpose:** an *activity control-center* (vs. schedule-first or
  growth-first) — mirrors the owner dashboard (ADR 0019).
- **Quick actions:** profile-oriented and *real where possible* — Edit Profile
  pushes the working edit route; Share Profile is a stub. (Schedule/Enquiries
  aren't built, so workflow actions would all be dead stubs.)
- **Data:** a new per-feature home fixture (vs. inline lists).
- **Chart:** skipped (the owner's 7-day views chart) to keep the screen lean.

## Decision

Replaced the placeholder `teacher_home_screen.dart` with a control-center
laid out like the owner dashboard but teal-branded and palette-first:

1. **`BrandBackdrop(orbColors: [teacherAccent])`** → `SafeArea` →
   `SingleChildScrollView` (bottom `floatingNavClearance`) → capped/centered
   at 600 px.
2. **Greeting** `GlassPanel`: "Good morning, <firstName> 👋" + an
   Independent/Affiliated status line read live from `teacherProfileProvider`,
   and a notification bell with an unread dot (stub).
3. **2×2 stat grid** of `NeoSurface` tiles — Views / Students / Rating (amber
   `ratingStar` icon) / Response — all read live from the profile provider, so
   the home and profile never disagree.
4. **Today's Sessions** — `NeoSurface` rows (mode icon, subject, batch, start
   time) with an empty-state fallback row.
5. **Recent Enquiries** — section header + teal "View all" (→ stub) and
   tappable `NeoSurface` rows (avatar, name, wanted subject, "2h ago").
6. **Quick actions** — a filled-teal **Edit Profile** `NeoButton`
   (`pushNamed(AppRoutes.teacherEditProfile)`) + an outlined **Share Profile**
   `NeoButton` (stub).

New fixture `lib/features/teacher/home/data/mock_teacher_home_data.dart`:
`TeacherSession { time, subject, group, mode(SessionMode) }` and
`TeacherEnquiry { studentName, initial, avatarColor, subject, ago }` with
`mockTeacherSessions` (3) + `mockTeacherEnquiries` (3). New teacher-home
`AppStrings` block (greeting/section labels, empty states) — no hardcoded copy.

All sub-widgets are private to the screen file (single-use). When the backend
lands, the fixtures swap for a controller-backed `AsyncValue` and the layout is
unchanged.

## Consequences

- The teacher shell now opens onto a real, branded home instead of a
  placeholder; consistent with the owner dashboard so the two role shells feel
  like one app.
- Stats are sourced once (the profile provider), avoiding a second source of
  truth — but sessions/enquiries are static fixtures and reset on restart.
- "View all", the bell, Share Profile, and enquiry taps are stubs until the
  Schedule/Enquiries tabs and an enquiry-detail screen exist (a natural follow-
  up, mirroring the owner enquiries work in ADR 0020).
- Verified: `dart format` + `flutter analyze` (whole project) clean. Not yet
  walked on a device in light/dark.
