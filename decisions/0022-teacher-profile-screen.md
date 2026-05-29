# 0022 — Teacher Profile (public listing read view + edit form)

**Status:** Accepted
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (request + shape/section choices) + Claude (implementation)

## Context

The teacher shell's five screens are the lightest scaffold in the app — bare
placeholders with no `data/` or `widgets/` folders. The profile screen's doc
already framed it as *"public listing and account settings"*, fitting the
teacher being a hybrid: a discoverable independent tutor and/or affiliated with
a center. The user asked to build the profile and chose an **account profile +
editable public listing** (the owner-Center read+edit pattern), all four listing
sections (**subjects & expertise, bio, rate & experience, teacher stats**), and
all four account sections (**appearance, settings, sign out, tutor-status
badge**).

## Decision

Built a read view (the tab) + an edit form sharing one provider — combining the
student/owner account-profile pattern ([0016]) with the owner-Center read+edit
pattern ([0021]). Teal-branded (`AppColors.teacherAccent`), palette-first per
[0017].

### Pieces (created the teacher's first data layer)

- `data/mock_teacher_profile_data.dart` — `TeacherProfile` (listing +
  account + read-only metrics, with `copyWith`), the `teacherSubjectOptions`
  taxonomy, and the `mockTeacherProfile` fixture (Vikram Desai, independent).
- `data/controllers/teacher_profile_provider.dart` — a Riverpod **`Notifier`**
  (`teacherProfileProvider`, same pattern as enquiries [0020] / center [0021])
  seeded from the fixture; read view `watch`es it, edit form commits via `save`.
- `teacher_profile_screen.dart` (rewritten from placeholder) — "Profile" +
  Edit button, identity card (avatar, name, headline, tutor-status badge,
  rating, email), a read-only views/students/rating/response stats strip, then
  About / Subjects & Expertise / Rate & Experience, and the shared
  Appearance / Settings / Sign Out tail (sign-out clears token + role →
  onboarding, identical to student/owner).
- `edit_teacher_profile_screen.dart` (new, `/teacher-profile/edit` =
  `AppRoutes.teacherEditProfile`, nested under teacher-profile) — text fields
  (name, headline, email, bio, expertise, rate, experience), an inline teal
  multi-select subject picker, and an **Independent-tutor switch** that reveals
  an "Affiliated center" field when off. Save commits + snackbar + pop. Reached
  via `pushNamed` so back returns within the shell.

### Notes

- The teacher had no scaffolded widget stubs (unlike the owner), so sub-widgets
  are inlined as private classes in the screens (consistent with how the
  student home inlines its private widgets) rather than split into
  `widgets/` files. The subject picker is teal, so reusing the owner's
  `SubjectSelectorWidget` (orange, cross-feature) was not appropriate.
- Reuses the shared `themeModeProvider` + `keyThemeMode` and the existing
  `profile*` strings where they were already generic; added `teacher*` strings
  for the listing + edit fields.
- `int` fields (rate, experience) parse on save with `int.tryParse(...) ??
  current`, so junk input falls back rather than corrupting state.

## Consequences

- Edits are **in-memory only** (reset on restart) until the backend lands —
  intended Phase-1 behaviour, consistent with the other owner/teacher features.
- The edit form renders inside the teacher shell (bottom nav visible beneath);
  same accepted trade-off as the enquiry detail and center edit.
- The teacher's other four tabs (Home, Search, Enquiries, Schedule) remain
  placeholders.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build
apk --debug` → built.
